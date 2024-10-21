# app_traffic_hours/views.py

import json
from django.utils.decorators import method_decorator
from django.views.decorators.csrf import csrf_exempt
from rest_framework.views import APIView
from rest_framework.response import Response
from django.db.models import Sum
from .models import TrafficHours
from .serializers import TrafficHoursSerializer
from app_users.utils import get_session_data_from_body, fetch_user_locations, is_admin_user

@method_decorator(csrf_exempt, name='dispatch')
class TrafficHoursSummaryView(APIView):
    def get(self, request, *args, **kwargs):
        try:
            # Langkah 1: Mendapatkan session data
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

            is_admin = is_admin_user(session_data)
            if isinstance(is_admin, dict) and 'error' in is_admin:
                return Response({"status": "error", "message": is_admin['error']}, status=400)

            locations = fetch_user_locations(session_data)
            if isinstance(locations, dict) and 'error' in locations:
                return Response({"status": "error", "message": locations['error']}, status=400)

            # Tentukan apakah perlu tampilkan view_all atau view_by_locations
            if request.path.endswith('bylocations'):
                return self.view_by_locations(locations)
            else:
                return self.view_all(locations)

        except Exception as e:
            return Response({"status": "error", "message": f"Terjadi kesalahan: {str(e)}"}, status=500)

    def view_all(self, locations):
        try:
            # Menghitung total transaksi dan pendapatan per jam untuk semua lokasi
            transaksi_sums = TrafficHours.objects.filter(id_lokasi__in=locations).aggregate(
                **{f'jam_{i}': Sum(f'jam_{i}') for i in range(24)}
            )
            pendapatan_sums = TrafficHours.objects.filter(id_lokasi__in=locations).aggregate(
                **{f'tarif_{i}': Sum(f'tarif_{i}') for i in range(24)}
            )

            transaksi_data = {f'jam_{i}': transaksi_sums[f'jam_{i}'] or 0 for i in range(24)}
            pendapatan_data = {f'jam_{i}': pendapatan_sums[f'tarif_{i}'] or 0 for i in range(24)}

            return Response({
                'transaksi': transaksi_data,
                'pendapatan': pendapatan_data
            })

        except Exception as e:
            return Response({"status": "error", "message": f"Error in view_all: {str(e)}"}, status=500)

    def view_by_locations(self, locations):
        try:
            location_data = {}

            # Query untuk mendapatkan data transaksi dan pendapatan per lokasi
            traffic_data = TrafficHours.objects.filter(id_lokasi__in=locations).values('id_lokasi__site').annotate(
                **{f'jam_{i}_transaksi': Sum(f'jam_{i}') for i in range(24)},
                **{f'jam_{i}_pendapatan': Sum(f'tarif_{i}') for i in range(24)}
            )

            # Loop untuk tiap lokasi dan membentuk response data
            for location in locations:
                site_name = location.site  # Nama lokasi (site)
                
                transaksi_data = {f'jam_{i}': 0 for i in range(24)}
                pendapatan_data = {f'jam_{i}': 0 for i in range(24)}

                lokasi_data = [item for item in traffic_data if item['id_lokasi__site'] == site_name]

                for data in lokasi_data:
                    for i in range(24):
                        transaksi_data[f'jam_{i}'] = data.get(f'jam_{i}_transaksi', 0)
                        pendapatan_data[f'jam_{i}'] = data.get(f'jam_{i}_pendapatan', 0)

                location_data[site_name] = {
                    'transaksi': transaksi_data,
                    'pendapatan': pendapatan_data
                }

            return Response(location_data)

        except Exception as e:
            return Response({"status": "error", "message": f"Error in view_by_locations: {str(e)}"}, status=500)
