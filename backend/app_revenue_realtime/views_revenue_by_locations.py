# app_revenue_realtime/views_revenue_by_locations.py

import json
from django.utils.decorators import method_decorator
from django.views.decorators.csrf import csrf_exempt
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.parsers import JSONParser
from django.db.models import Sum, Max
from django.utils import timezone
from .serializers import RevenueByLocationsSerializer
from app_users.utils import get_session_data_from_body, fetch_user_locations, is_admin_user
from app_revenue_realtime.models import RevenueRealtime

@method_decorator(csrf_exempt, name='dispatch')
class RevenueByLocationsView(APIView):
    parser_classes = [JSONParser]

    def get(self, request, *args, **kwargs):
        try:
            # Step 1: Session Data Validation
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

            # Step 2: User Authorization Check
            is_admin = is_admin_user(session_data)
            if isinstance(is_admin, dict) and 'error' in is_admin:
                return Response({"status": "error", "message": is_admin['error']}, status=400)

            # Step 3: Location Access Validation
            locations = fetch_user_locations(session_data)
            if isinstance(locations, dict) and 'error' in locations:
                return Response({"status": "error", "message": locations['error']}, status=400)

            # Step 4: Route to appropriate view method
            if request.path.endswith('bylocations'):
                return self.view_by_locations(locations)
            else:
                return self.view_all(locations)

        except Exception as e:
            return Response({"status": "error", "message": f"An error occurred: {str(e)}"}, status=500)

    def should_show_member_data(self, target_date):
        current_date = timezone.now().date()
        if target_date.month == 12:
            cutoff_date = target_date.replace(year=target_date.year + 1, month=1, day=6)
        else:
            cutoff_date = target_date.replace(month=target_date.month + 1, day=6)
        return current_date >= cutoff_date

    def filter_member_data(self, queryset, target_date):
        show_member_data = self.should_show_member_data(target_date)
        if not show_member_data:
            return queryset.exclude(kendaraan='MEMBER')
        return queryset

    def get_latest_data_per_location(self, locations):
        today = timezone.now().date()
        location_data = {}
        
        for location in locations:
            # Cek transaksi hari ini
            today_data = RevenueRealtime.objects.filter(
                id_lokasi=location,
                tanggal=today
            ).aggregate(
                latest_time=Max('waktu'),
                total_transaksi=Sum('qty'),
                total_pendapatan=Sum('jumlah')
            )
            
            if today_data['latest_time']:
                # Ada transaksi hari ini
                location_data[location] = {
                    'waktu': today_data['latest_time'],
                    'tanggal': today,
                    'total_transaksi': today_data['total_transaksi'] or 0,
                    'total_pendapatan': int(today_data['total_pendapatan'] or 0),
                    'has_today_transaction': True
                }
            else:
                # Cari data transaksi terakhir
                last_data = RevenueRealtime.objects.filter(
                    id_lokasi=location
                ).order_by('-tanggal', '-waktu').first()
                
                if last_data:
                    # Ambil total untuk tanggal terakhir
                    last_date_data = RevenueRealtime.objects.filter(
                        id_lokasi=location,
                        tanggal=last_data.tanggal,
                        waktu__lte=last_data.waktu
                    ).aggregate(
                        total_transaksi=Sum('qty'),
                        total_pendapatan=Sum('jumlah')
                    )
                    
                    location_data[location] = {
                        'waktu': last_data.waktu,
                        'tanggal': last_data.tanggal,
                        'total_transaksi': last_date_data['total_transaksi'] or 0,
                        'total_pendapatan': int(last_date_data['total_pendapatan'] or 0),
                        'has_today_transaction': False
                    }
                else:
                    location_data[location] = None
                
        return location_data

    def view_all(self, locations):
        try:
            location_latest_data = self.get_latest_data_per_location(locations)
            
            # Filter out locations with no data
            active_locations = {loc: data for loc, data in location_latest_data.items() if data is not None}
            
            if not active_locations:
                return Response({"detail": "No data available for any location"}, status=404)

            data_list = []
            for location, latest_data in active_locations.items():
                # Terapkan filter member data
                base_queryset = RevenueRealtime.objects.filter(
                    id_lokasi=location,
                    tanggal=latest_data['tanggal'],
                    waktu__lte=latest_data['waktu']
                )
                
                if base_queryset.exists():
                    filtered_queryset = self.filter_member_data(base_queryset, latest_data['tanggal'])
                    
                    # Aggregate data
                    aggregated_data = filtered_queryset.aggregate(
                        total_transaksi=Sum('qty'),
                        total_pendapatan=Sum('jumlah')
                    )
                    
                    data = {
                        "waktu": latest_data['waktu'],
                        "id_lokasi": location.site,
                        "total_transaksi": aggregated_data['total_transaksi'] or 0,
                        "total_pendapatan": int(aggregated_data['total_pendapatan'] or 0)
                    }
                    serializer = RevenueByLocationsSerializer(data)
                    data_list.append(serializer.data)
                    
            return Response(data_list)

        except Exception as e:
            return Response({"status": "error", "message": f"Error in view_all: {str(e)}"}, status=500)

    def view_by_locations(self, locations):
        try:
            location_latest_data = self.get_latest_data_per_location(locations)
            
            # Filter out locations with no data
            active_locations = {loc: data for loc, data in location_latest_data.items() if data is not None}
            
            if not active_locations:
                return Response({"detail": "No data available for any location"}, status=404)

            location_data = {}
            
            for location, latest_data in active_locations.items():
                # Terapkan filter member data
                base_queryset = RevenueRealtime.objects.filter(
                    id_lokasi=location,
                    tanggal=latest_data['tanggal'],
                    waktu__lte=latest_data['waktu']
                )
                
                if base_queryset.exists():
                    filtered_queryset = self.filter_member_data(base_queryset, latest_data['tanggal'])
                    
                    # Aggregate data
                    aggregated_data = filtered_queryset.aggregate(
                        total_transaksi=Sum('qty'),
                        total_pendapatan=Sum('jumlah')
                    )
                    
                    location_data[location.site] = [{
                        "waktu": latest_data['waktu'],
                        "id_lokasi": location.site,
                        "total_transaksi": aggregated_data['total_transaksi'] or 0,
                        "total_pendapatan": int(aggregated_data['total_pendapatan'] or 0)
                    }]

            return Response(location_data)

        except Exception as e:
            return Response({"status": "error", "message": f"Error in view_by_locations: {str(e)}"}, status=500)