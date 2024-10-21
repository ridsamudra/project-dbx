# app_revenue_trends/views_filter_by_days.py

import json
from django.utils.decorators import method_decorator
from django.views.decorators.csrf import csrf_exempt
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.parsers import JSONParser
from django.db.models import Sum, Max
from django.utils import timezone
from datetime import timedelta
from decimal import Decimal
from app_income_parkir.models import IncomeParkir
from app_income_member.models import IncomeMember
from app_income_manual.models import IncomeManual
from app_users.utils import get_session_data_from_body, fetch_user_locations, is_admin_user

@method_decorator(csrf_exempt, name='dispatch')
class RevenueByDaysView(APIView):
    """
    API View untuk mengambil data pendapatan berdasarkan hari dengan aturan proteksi data member.
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
                return self.view_by_locations(locations)
            else:
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
        """
        Mengambil data pendapatan agregat untuk semua lokasi dengan proteksi data member.
        """
        try:
            latest_date = IncomeParkir.objects.order_by('-tanggal').first().tanggal
            start_date = latest_date - timedelta(days=6)

            # Ambil data parkir
            parkir_data = IncomeParkir.objects.filter(
                id_lokasi__in=locations, 
                tanggal__range=[start_date, latest_date]
            ).values('tanggal').annotate(
                cash=Sum('cash'), 
                prepaid=Sum('prepaid')
            ).order_by('tanggal')

            # Ambil data member
            member_data = IncomeMember.objects.filter(
                id_lokasi__in=locations, 
                tanggal__range=[start_date, latest_date]
            ).values('tanggal').annotate(
                member=Sum('member')
            )

            # Ambil data manual
            manual_data = IncomeManual.objects.filter(
                id_lokasi__in=locations, 
                tanggal__range=[start_date, latest_date]
            ).values('tanggal').annotate(
                manual=Sum('manual'), 
                masalah=Sum('masalah')
            ).order_by('tanggal')

            result = []
            for date in parkir_data:
                date_value = date['tanggal']
                cash = Decimal(date['cash'] or 0)
                prepaid = Decimal(date['prepaid'] or 0)
                
                # Terapkan filter data member
                raw_member = next((item['member'] for item in member_data if item['tanggal'] == date_value), 0)
                member = self.filter_member_data(Decimal(raw_member or 0), date_value)
                
                manual = Decimal(next((item['manual'] for item in manual_data if item['tanggal'] == date_value), 0))
                masalah = Decimal(next((item['masalah'] for item in manual_data if item['tanggal'] == date_value), 0))

                total = cash + prepaid + manual + member - masalah

                result.append({
                    'tanggal': date_value,
                    'cash': cash,
                    'prepaid': prepaid,
                    'member': member,
                    'manual': manual,
                    'masalah': masalah,
                    'total': total
                })

            return Response(result, status=200)

        except Exception as e:
            return Response({"status": "error", "message": f"Error dalam view_all: {str(e)}"}, status=500)

    def view_by_locations(self, locations):
        """
        Mengambil data pendapatan spesifik per lokasi dengan proteksi data member.
        """
        try:
            latest_date = IncomeParkir.objects.order_by('-tanggal').first().tanggal
            start_date = latest_date - timedelta(days=6)

            # Ambil data parkir per lokasi
            parkir_data = IncomeParkir.objects.filter(
                id_lokasi__in=locations, 
                tanggal__range=[start_date, latest_date]
            ).values('tanggal', 'id_lokasi__site').annotate(
                cash=Sum('cash'), 
                prepaid=Sum('prepaid')
            ).order_by('tanggal')

            # Ambil data member per lokasi
            member_data = IncomeMember.objects.filter(
                id_lokasi__in=locations, 
                tanggal__range=[start_date, latest_date]
            ).values('tanggal', 'id_lokasi__site').annotate(
                member=Sum('member')
            )

            # Ambil data manual per lokasi
            manual_data = IncomeManual.objects.filter(
                id_lokasi__in=locations, 
                tanggal__range=[start_date, latest_date]
            ).values('tanggal', 'id_lokasi__site').annotate(
                manual=Sum('manual'), 
                masalah=Sum('masalah')
            ).order_by('tanggal')

            location_data = {}
            for location in locations:
                site_name = location.site
                location_data[site_name] = []

                location_parkir_data = [item for item in parkir_data if item['id_lokasi__site'] == site_name]
                for date in location_parkir_data:
                    date_value = date['tanggal']
                    cash = Decimal(date['cash'] or 0)
                    prepaid = Decimal(date['prepaid'] or 0)
                    
                    # Terapkan filter data member per lokasi
                    raw_member = next((
                        item['member'] for item in member_data 
                        if item['tanggal'] == date_value and item['id_lokasi__site'] == site_name
                    ), 0)
                    member = self.filter_member_data(Decimal(raw_member or 0), date_value)
                    
                    manual = Decimal(next((
                        item['manual'] for item in manual_data 
                        if item['tanggal'] == date_value and item['id_lokasi__site'] == site_name
                    ), 0))
                    masalah = Decimal(next((
                        item['masalah'] for item in manual_data 
                        if item['tanggal'] == date_value and item['id_lokasi__site'] == site_name
                    ), 0))

                    total = cash + prepaid + manual + member - masalah

                    location_data[site_name].append({
                        'tanggal': date_value,
                        'cash': cash,
                        'prepaid': prepaid,
                        'member': member,
                        'manual': manual,
                        'masalah': masalah,
                        'total': total
                    })

            return Response(location_data, status=200)

        except Exception as e:
            return Response({"status": "error", "message": f"Error dalam view_by_locations: {str(e)}"}, status=500)