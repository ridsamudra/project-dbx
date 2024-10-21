# app_revenue_realtime/views_revenue_realtime.py

import json
from django.utils.decorators import method_decorator
from django.views.decorators.csrf import csrf_exempt
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.parsers import JSONParser
from django.db.models import Sum, Max, Case, When, Value, DecimalField, Q
from django.utils import timezone
from datetime import datetime, timedelta
from .models import RevenueRealtime
from .serializers import RevenueRealtimeSerializer
from app_users.utils import get_session_data_from_body, fetch_user_locations, is_admin_user

@method_decorator(csrf_exempt, name='dispatch')
class RevenueRealtimeView(APIView):
    """
    API View untuk mengambil data pendapatan real-time dengan aturan proteksi data member.
    Menangani tampilan data agregat dan spesifik per lokasi.
    """
    parser_classes = [JSONParser]

    def get(self, request, *args, **kwargs):
        try:
            # Langkah 1: Validasi Data Sesi
            session_data_result = get_session_data_from_body(request)
            if isinstance(session_data_result, dict) and 'error' in session_data_result:
                session_data_str = request.GET.get('session_data') or request.headers.get('X-Session-Data')
                if session_data_str:
                    try:
                        session_data = json.loads(session_data_str)
                    except json.JSONDecodeError:
                        return Response({"status": "error", "message": "Format data sesi tidak valid"}, status=400)
                else:
                    return Response({"status": "error", "message": session_data_result['error']}, status=400)
            else:
                session_data = session_data_result

            # Langkah 2: Pemeriksaan Otorisasi Pengguna
            is_admin = is_admin_user(session_data)
            if isinstance(is_admin, dict) and 'error' in is_admin:
                return Response({"status": "error", "message": is_admin['error']}, status=400)

            # Langkah 3: Validasi Akses Lokasi
            locations = fetch_user_locations(session_data)
            if isinstance(locations, dict) and 'error' in locations:
                return Response({"status": "error", "message": locations['error']}, status=400)

            # Langkah 4: Arahkan ke metode tampilan yang sesuai
            if request.path.endswith('bylocations'):
                response = self.view_by_locations(locations)
            else:
                response = self.view_all(locations)

            return response

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

    def filter_member_data(self, queryset, target_date):
        """
        Memfilter data member berdasarkan tanggal.
        Jika belum melewati tanggal cutoff, data member akan dihilangkan sepenuhnya.
        """
        show_member_data = self.should_show_member_data(target_date)
        
        if not show_member_data:
            # Hilangkan data member sepenuhnya
            return queryset.exclude(kendaraan='MEMBER')
        
        return queryset

    def view_all(self, locations):
        """
        Mengambil data pendapatan agregat untuk semua lokasi dengan proteksi data member.
        """
        try:
            # Ambil timestamp terbaru
            latest_waktu = RevenueRealtime.objects.filter(
                id_lokasi__in=locations
            ).aggregate(Max('waktu'))['waktu__max']
            
            if not latest_waktu:
                return Response({"detail": "Data tidak tersedia"}, status=404)

            # Filter dan agregasi data
            base_queryset = RevenueRealtime.objects.filter(
                id_lokasi__in=locations,
                tanggal=latest_waktu.date(),
                waktu__lte=latest_waktu
            )
            
            # Terapkan filter data member
            filtered_queryset = self.filter_member_data(base_queryset, latest_waktu.date())
            
            # Agregasi data
            aggregated_data = filtered_queryset.values(
                'kendaraan'
            ).annotate(
                jumlah_transaksi=Sum('qty'),
                jumlah_pendapatan=Sum('jumlah')
            )

            # Format data respons
            data_list = []
            for kendaraan in aggregated_data:
                data = {
                    "waktu": latest_waktu,
                    "jenis_kendaraan": kendaraan['kendaraan'],
                    "jumlah_transaksi": kendaraan['jumlah_transaksi'],
                    "jumlah_pendapatan": int(kendaraan['jumlah_pendapatan'])
                }
                serializer = RevenueRealtimeSerializer(data)
                data_list.append(serializer.data)

            return Response(data_list)

        except Exception as e:
            return Response({"status": "error", "message": f"Error dalam view_all: {str(e)}"}, status=500)

    def view_by_locations(self, locations):
        """
        Mengambil data pendapatan spesifik per lokasi dengan proteksi data member.
        """
        try:
            location_data = {}

            # Ambil timestamp terbaru
            latest_waktu = RevenueRealtime.objects.filter(
                id_lokasi__in=locations
            ).aggregate(Max('waktu'))['waktu__max']
            
            if not latest_waktu:
                return Response({"detail": "Data tidak tersedia"}, status=404)

            # Proses data untuk setiap lokasi
            for location in locations:
                site_name = location.site

                # Filter dan agregasi data untuk lokasi ini
                base_queryset = RevenueRealtime.objects.filter(
                    id_lokasi=location,
                    tanggal=latest_waktu.date(),
                    waktu__lte=latest_waktu
                )
                
                # Terapkan filter data member
                filtered_queryset = self.filter_member_data(base_queryset, latest_waktu.date())
                
                # Agregasi data
                aggregated_data = filtered_queryset.values(
                    'kendaraan'
                ).annotate(
                    jumlah_transaksi=Sum('qty'),
                    jumlah_pendapatan=Sum('jumlah')
                )

                # Format data spesifik lokasi
                location_data[site_name] = []
                for kendaraan in aggregated_data:
                    data = {
                        "waktu": latest_waktu,
                        "jenis_kendaraan": kendaraan['kendaraan'],
                        "jumlah_transaksi": kendaraan['jumlah_transaksi'],
                        "jumlah_pendapatan": int(kendaraan['jumlah_pendapatan'])
                    }
                    location_data[site_name].append(data)

            return Response(location_data)

        except Exception as e:
            return Response({"status": "error", "message": f"Error dalam view_by_locations: {str(e)}"}, status=500)