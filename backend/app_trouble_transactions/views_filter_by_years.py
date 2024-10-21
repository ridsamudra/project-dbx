# app_trouble_transactions/views_filter_by_years.py

import json
from decimal import Decimal
from django.utils.decorators import method_decorator
from django.views.decorators.csrf import csrf_exempt
from dateutil.relativedelta import relativedelta
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.parsers import JSONParser
from django.db.models import Sum
from django.db.models.functions import TruncYear
from app_income_manual.models import IncomeManual
from app_users.utils import get_session_data_from_body, fetch_user_locations, is_admin_user

@method_decorator(csrf_exempt, name='dispatch')
class TroubleByYearsView(APIView):
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

    def view_all(self, locations):
        try:
            # Get the latest date in the database
            latest_date = IncomeManual.objects.order_by('-tanggal').first().tanggal

            # start_date = latest_date - relativedelta(years=5)
            start_date = (latest_date - relativedelta(years=5)).replace(month=1, day=1)

            # Query for income manual data
            manual_data = IncomeManual.objects.filter(id_lokasi__in=locations, tanggal__range=[start_date, latest_date]) \
                .exclude(masalah=0) \
                .annotate(year=TruncYear('tanggal')) \
                .values('year', 'id_lokasi__site') \
                .annotate(total_masalah=Sum('masalah')) \
                .order_by('year', 'id_lokasi__site')

            # Prepare response data
            result = {}
            for year_data in manual_data:
                year_key = str(year_data['year'].year)
                result[year_key] = []

                for location in locations:
                    site_name = location.site

                    total_masalah = Decimal(next((item['total_masalah'] for item in manual_data if item['year'].year == year_data['year'].year and item['id_lokasi__site'] == site_name), 0))

                    result[year_key].append({
                        'nama_lokasi' : site_name,
                        'total_masalah' : str(total_masalah)
                    })
                
                # Ensure all locations are present in the result even if total_masalah is 0
                for year_key in result.keys():
                    for location in locations:
                        site_name = location.site
                        if not any(loc['nama_lokasi'] == site_name for loc in result[year_key]):
                            result[year_key].append({
                                'nama_lokasi' : site_name,
                                'total_masalah' : str(total_masalah)
                            })                    

            return Response(result, status=200)  

        except Exception as e:
            return Response({"status": "error", "message": f"Error in view_all: {str(e)}"}, status=500)
