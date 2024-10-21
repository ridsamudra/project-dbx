# app_revenue_trends_by_locations/views_filter_by_days.py

import json
from django.utils.decorators import method_decorator
from django.views.decorators.csrf import csrf_exempt
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.parsers import JSONParser
from django.db.models import Sum
from django.utils import timezone
from datetime import timedelta
from decimal import Decimal
from app_income_parkir.models import IncomeParkir
from app_income_member.models import IncomeMember
from app_income_manual.models import IncomeManual
from app_users.utils import get_session_data_from_body, fetch_user_locations, is_admin_user

@method_decorator(csrf_exempt, name='dispatch')
class RevenueByDaysView(APIView):

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

            # Return revenue data for all locations
            return self.view_all(locations)

        except Exception as e:
            return Response({"status": "error", "message": f"Terjadi kesalahan: {str(e)}"}, status=500)

    def should_show_member_data(self, target_date):
        """
        Menentukan apakah data member untuk bulan tertentu harus ditampilkan.
        Data member hanya ditampilkan setelah tanggal 5 bulan berikutnya.
        """
        current_date = timezone.now().date()
        
        # Menentukan tanggal cutoff (tanggal 6 bulan berikutnya)
        if target_date.month == 12:
            cutoff_date = target_date.replace(year=target_date.year + 1, month=1, day=6)
        else:
            cutoff_date = target_date.replace(month=target_date.month + 1, day=6)
        
        return current_date >= cutoff_date

    def filter_member_data(self, member_data, date):
        """
        Memfilter data member berdasarkan tanggal.
        Jika belum melewati tanggal cutoff, data member akan diset menjadi 0.
        """
        show_member_data = self.should_show_member_data(date)
        
        if not show_member_data:
            return Decimal('0')
        
        return member_data

    def view_all(self, locations):
        try:
            latest_date = IncomeParkir.objects.order_by('-tanggal').first().tanggal
            start_date = latest_date - timedelta(days=6)

            # Fetch data across all locations
            parkir_data = IncomeParkir.objects.filter(
                id_lokasi__in=locations, 
                tanggal__range=[start_date, latest_date]
            ).values(
                'id_lokasi__site', 
                'tanggal'
            ).annotate(
                cash=Sum('cash'), 
                prepaid=Sum('prepaid')
            ).order_by('tanggal')

            member_data = IncomeMember.objects.filter(
                id_lokasi__in=locations, 
                tanggal__range=[start_date, latest_date]
            ).values(
                'id_lokasi__site', 
                'tanggal'
            ).annotate(
                member=Sum('member')
            )

            manual_data = IncomeManual.objects.filter(
                id_lokasi__in=locations, 
                tanggal__range=[start_date, latest_date]
            ).values(
                'id_lokasi__site', 
                'tanggal'
            ).annotate(
                manual=Sum('manual'), 
                masalah=Sum('masalah')
            ).order_by('tanggal')

            # Initializing result dictionary with dates as keys
            result = {}
            date_range = [start_date + timedelta(days=x) for x in range(7)]

            for single_date in date_range:
                result[str(single_date)] = []

                for location in locations:
                    site_name = location.site

                    cash = Decimal(next((
                        item['cash'] for item in parkir_data 
                        if item['tanggal'] == single_date and item['id_lokasi__site'] == site_name
                    ), 0))
                    prepaid = Decimal(next((
                        item['prepaid'] for item in parkir_data 
                        if item['tanggal'] == single_date and item['id_lokasi__site'] == site_name
                    ), 0))
                    
                    # Apply member data filtering
                    raw_member = Decimal(next((
                        item['member'] for item in member_data 
                        if item['tanggal'] == single_date and item['id_lokasi__site'] == site_name
                    ), 0))
                    member = self.filter_member_data(raw_member, single_date)
                    
                    manual = Decimal(next((
                        item['manual'] for item in manual_data 
                        if item['tanggal'] == single_date and item['id_lokasi__site'] == site_name
                    ), 0))
                    masalah = Decimal(next((
                        item['masalah'] for item in manual_data 
                        if item['tanggal'] == single_date and item['id_lokasi__site'] == site_name
                    ), 0))

                    total = cash + prepaid + manual + member - masalah

                    # Append data for each location for that date
                    result[str(single_date)].append({
                        'nama_lokasi': site_name,
                        'total': str(total)  # Convert to string to maintain consistency
                    })

                # Ensure all locations are present in the result even if total is 0
                existing_locations = {item['nama_lokasi'] for item in result[str(single_date)]}
                for location in locations:
                    site_name = location.site
                    if site_name not in existing_locations:
                        result[str(single_date)].append({
                            'nama_lokasi': site_name,
                            'total': '0'
                        })

            return Response(result, status=200)

        except Exception as e:
            return Response({"status": "error", "message": f"Error in view_all: {str(e)}"}, status=500)