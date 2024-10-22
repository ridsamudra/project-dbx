# app_revenue_trends_by_locations/views_filter_by_years.py

import json
from decimal import Decimal
from django.utils.decorators import method_decorator
from django.views.decorators.csrf import csrf_exempt
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.parsers import JSONParser
from django.db.models import Sum
from django.db.models.functions import TruncYear
from dateutil.relativedelta import relativedelta
from django.utils import timezone
from app_income_parkir.models import IncomeParkir
from app_income_member.models import IncomeMember
from app_income_manual.models import IncomeManual
from app_users.utils import get_session_data_from_body, fetch_user_locations, is_admin_user

@method_decorator(csrf_exempt, name='dispatch')
class RevenueByYearsView(APIView):
    parser_classes = [JSONParser]

    def get(self, request, *args, **kwargs):
        try:
            # Step 1: Get session data from body or fallback to query params/headers
            session_data_result = get_session_data_from_body(request)
            if isinstance(session_data_result, dict) and 'error' in session_data_result:
                session_data_str = request.GET.get('session_data') or request.headers.get('X-Session-Data')
                if session_data_str:
                    try:
                        session_data = json.loads(session_data_str)
                    except json.JSONDecodeError:
                        return Response({"status": "error", "message": "Invalid session data format"}, status=400)
                else:
                    return Response({"status": "error", "message": session_data_result['error']}, status=400)
            else:
                session_data = session_data_result

            # Step 2: Check if user is admin
            is_admin = is_admin_user(session_data)
            if isinstance(is_admin, dict) and 'error' in is_admin:
                return Response({"status": "error", "message": is_admin['error']}, status=400)

            # Step 3: Fetch valid user locations based on session data
            locations = fetch_user_locations(session_data)
            if isinstance(locations, dict) and 'error' in locations:
                return Response({"status": "error", "message": locations['error']}, status=400)

            # Return revenue data for all locations across last 6 years
            return self.view_all(locations)

        except Exception as e:
            return Response({"status": "error", "message": f"Terjadi kesalahan: {str(e)}"}, status=500)

    def should_show_member_data(self, target_date):
        """
        Determines whether member data for a specific date should be shown.
        Member data is only shown after the 5th of the following month.
        """
        current_date = timezone.now().date()
        
        # Determine cutoff date (6th day of next month)
        if target_date.month == 12:
            cutoff_date = target_date.replace(year=target_date.year + 1, month=1, day=6)
        else:
            cutoff_date = target_date.replace(month=target_date.month + 1, day=6)
        
        return current_date >= cutoff_date

    def filter_member_data(self, member_data, target_date):
        """
        Filters member data based on date.
        If cutoff date hasn't passed, member data will be set to 0.
        """
        show_member_data = self.should_show_member_data(target_date)
        
        if not show_member_data:
            return Decimal('0')
        
        return member_data

    def view_all(self, locations):
        try:
            # Get the latest date in the database
            latest_date = IncomeParkir.objects.order_by('-tanggal').first().tanggal
            start_date = (latest_date - relativedelta(years=5)).replace(month=1, day=1)

            # Fetch data across all locations for the last 6 years
            parkir_data = IncomeParkir.objects.filter(id_lokasi__in=locations, tanggal__range=[start_date, latest_date]) \
                .annotate(year=TruncYear('tanggal')) \
                .values('year', 'id_lokasi__site') \
                .annotate(cash=Sum('cash'), prepaid=Sum('prepaid')) \
                .order_by('year')

            manual_data = IncomeManual.objects.filter(id_lokasi__in=locations, tanggal__range=[start_date, latest_date]) \
                .annotate(year=TruncYear('tanggal')) \
                .values('year', 'id_lokasi__site') \
                .annotate(manual=Sum('manual'), masalah=Sum('masalah')) \
                .order_by('year')

            # Prepare result dictionary with year as key
            result = {}
            for year_data in parkir_data:
                year_key = str(year_data['year'].year)
                result[year_key] = []

                for location in locations:
                    site_name = location.site
                    current_year = year_data['year'].year
                    total_member = Decimal('0')

                    # Calculate member data with protection for each month
                    for month in range(1, 13):
                        target_date = year_data['year'].replace(month=month, day=1)
                        
                        # Get member data for this month and location
                        month_member_data = IncomeMember.objects.filter(
                            id_lokasi__site=site_name,
                            tanggal__year=current_year,
                            tanggal__month=month
                        ).aggregate(Sum('member'))['member__sum'] or Decimal('0')
                        
                        # Apply member data protection
                        filtered_member_data = self.filter_member_data(month_member_data, target_date)
                        total_member += filtered_member_data

                    cash = Decimal(next((
                        item['cash'] for item in parkir_data 
                        if item['year'].year == current_year and item['id_lokasi__site'] == site_name
                    ), 0))
                    prepaid = Decimal(next((
                        item['prepaid'] for item in parkir_data 
                        if item['year'].year == current_year and item['id_lokasi__site'] == site_name
                    ), 0))
                    manual = Decimal(next((
                        item['manual'] for item in manual_data 
                        if item['year'].year == current_year and item['id_lokasi__site'] == site_name
                    ), 0))
                    masalah = Decimal(next((
                        item['masalah'] for item in manual_data 
                        if item['year'].year == current_year and item['id_lokasi__site'] == site_name
                    ), 0))

                    total = cash + prepaid + total_member + manual - masalah

                    result[year_key].append({
                        'nama_lokasi': site_name,
                        'total': str(total)
                    })

            # Ensure all locations are present in the result even if total is 0
            for year_key in result.keys():
                for location in locations:
                    site_name = location.site
                    if not any(loc['nama_lokasi'] == site_name for loc in result[year_key]):
                        result[year_key].append({
                            'nama_lokasi': site_name,
                            'total': '0'
                        })

            return Response(result, status=200)

        except Exception as e:
            return Response({"status": "error", "message": f"Error in view_all: {str(e)}"}, status=500)