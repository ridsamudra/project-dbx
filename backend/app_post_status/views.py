# app_post_status/views.py

import json
from django.utils.decorators import method_decorator
from django.views.decorators.csrf import csrf_exempt
from rest_framework.views import APIView
from rest_framework.response import Response
from django.db.models import Sum, Count
from .models import PostStatus
from app_users.utils import get_session_data_from_body, fetch_user_locations, is_admin_user

@method_decorator(csrf_exempt, name='dispatch')
class PostStatusSummaryView(APIView):
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

            if request.path.endswith('bylocations'):
                return self.view_by_locations(locations)
            else:
                return self.view_all(locations)

        except Exception as e:
            return Response({"status": "error", "message": f"Terjadi kesalahan: {str(e)}"}, status=500)

    def view_all(self, locations):
        try:
            # Hitung total trafic dan jumlah pos untuk online & offline
            total_transaksi_pos_online = PostStatus.objects.filter(aktif=1, id_lokasi__in=locations).aggregate(total_trafic=Sum('trafic'))['total_trafic'] or 0
            total_transaksi_pos_offline = PostStatus.objects.filter(aktif=0, id_lokasi__in=locations).aggregate(total_trafic=Sum('trafic'))['total_trafic'] or 0

            jumlah_pos_online = PostStatus.objects.filter(aktif=1, id_lokasi__in=locations).count()
            jumlah_pos_offline = PostStatus.objects.filter(aktif=0, id_lokasi__in=locations).count()

            return Response({
                'total_transaksi_pos_online': total_transaksi_pos_online,
                'total_transaksi_pos_offline': total_transaksi_pos_offline,
                'jumlah_pos_online': jumlah_pos_online,
                'jumlah_pos_offline': jumlah_pos_offline
            })

        except Exception as e:
            return Response({"status": "error", "message": f"Error in view_all: {str(e)}"}, status=500)

    def view_by_locations(self, locations):
        try:
            location_data = {}

            # Query untuk mendapatkan semua data yang diperlukan dalam satu kali query
            pos_data = PostStatus.objects.filter(
                id_lokasi__in=locations
            ).values(
                'id_lokasi__site',  # Nama lokasi
                'pos',              # Nama pos
                'aktif',            # Status aktif
                'trafic'           # Total transaksi
            )

            # Memproses dan mengelompokkan data per lokasi
            for pos in pos_data:
                site_name = pos['id_lokasi__site']
                
                # Inisialisasi list untuk lokasi jika belum ada
                if site_name not in location_data:
                    location_data[site_name] = []

                # Menambahkan data pos ke dalam list lokasi
                location_data[site_name].append({
                    "nama_pos": pos['pos'],
                    "status_pos": "Online" if pos['aktif'] == 1 else "Offline",
                    "total_transaksi": pos['trafic']
                })

            return Response(location_data)

        except Exception as e:
            return Response({"status": "error", "message": f"Error in view_by_locations: {str(e)}"}, status=500)