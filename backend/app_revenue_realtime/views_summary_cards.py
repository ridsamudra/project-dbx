# app_revenue_realtime/views_summary_cards.py

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
from .models import RevenueRealtime
from .serializers import SummaryCardsSerializer
from app_users.utils import get_session_data_from_body, fetch_user_locations, is_admin_user
from app_income_parkir.models import IncomeParkir
from app_income_member.models import IncomeMember
from app_income_manual.models import IncomeManual

@method_decorator(csrf_exempt, name='dispatch')
class SummaryCardsView(APIView):
    """
    API View for generating summary cards containing revenue and transaction statistics.
    Handles both real-time and historical data aggregation with member data protection rules.
    """
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

            # Step 4: Latest Data Timestamp Retrieval
            latest_waktu = RevenueRealtime.objects.filter(
                id_lokasi__in=locations
            ).aggregate(Max('waktu'))['waktu__max']

            if not latest_waktu:
                return Response({"detail": "No data available"}, status=404)

            # Step 5: Member Data Protection Logic
            current_time = timezone.now()
            
            def should_show_member_data(date):
                if date.month != current_time.month or date.year != current_time.year:
                    next_month = (date.replace(day=1) + timedelta(days=32)).replace(day=5)
                    return current_time.date() >= next_month
                return False

            # Step 6: Calculate Today's Revenue and Transactions
            today_date = latest_waktu.date()
            show_today_member = should_show_member_data(today_date)
            
            # Calculate today's revenue excluding member data
            today_base_revenue = RevenueRealtime.objects.filter(
                tanggal=today_date,
                waktu__lte=latest_waktu,
                id_lokasi__in=locations
            ).exclude(kendaraan='MEMBER').aggregate(total=Sum('jumlah'))['total'] or 0

            # Add member revenue only if protection period has passed
            if show_today_member:
                today_member_revenue = RevenueRealtime.objects.filter(
                    tanggal=today_date,
                    waktu__lte=latest_waktu,
                    id_lokasi__in=locations,
                    kendaraan='MEMBER'
                ).aggregate(total=Sum('jumlah'))['total'] or 0
            else:
                today_member_revenue = 0

            pendapatan_hari_ini = today_base_revenue + today_member_revenue

            # Calculate today's transactions (qty) excluding MEMBER
            transaksi_hari_ini = RevenueRealtime.objects.filter(
                tanggal=today_date,
                waktu__lte=latest_waktu,
                id_lokasi__in=locations
            ).exclude(kendaraan='MEMBER').aggregate(total=Sum('qty'))['total'] or 0

            # Step 7: Define Date Range for Historical Data (excluding today)
            end_date = latest_waktu.date() - timedelta(days=1)  # Yesterday
            start_date = end_date - timedelta(days=5)  # Previous 6 days

            # Step 8: Process Historical Data for Previous 6 Days
            historical_pendapatan = 0
            historical_transaksi = 0

            for single_date in (start_date + timedelta(n) for n in range(6)):  # 6 days, excluding today
                show_member = should_show_member_data(single_date)
                
                # Fetch parking revenue data
                parkir_day = IncomeParkir.objects.filter(
                    id_lokasi__in=locations,
                    tanggal=single_date
                ).aggregate(
                    cash=Sum('cash'),
                    prepaid=Sum('prepaid'),
                    casual=Sum('casual'),
                    pass_field=Sum('pass_field')
                )

                # Fetch membership revenue data with protection
                if show_member:
                    member_day = IncomeMember.objects.filter(
                        id_lokasi__in=locations,
                        tanggal=single_date
                    ).aggregate(member=Sum('member'))
                else:
                    member_day = {'member': 0}

                # Fetch manual transaction data
                manual_day = IncomeManual.objects.filter(
                    id_lokasi__in=locations,
                    tanggal=single_date
                ).aggregate(
                    manual=Sum('manual'),
                    masalah=Sum('masalah')
                )

                # Calculate daily revenue
                daily_revenue = (
                    Decimal(parkir_day['cash'] or 0) +
                    Decimal(parkir_day['prepaid'] or 0) +
                    Decimal(manual_day['manual'] or 0) +
                    Decimal(member_day['member'] or 0) -
                    Decimal(manual_day['masalah'] or 0)
                )

                # Calculate daily transactions
                daily_transactions = (
                    Decimal(parkir_day['casual'] or 0) +
                    Decimal(parkir_day['pass_field'] or 0)
                )

                historical_pendapatan += daily_revenue
                historical_transaksi += daily_transactions

            # Step 9: Add today's data to the historical totals
            total_pendapatan = historical_pendapatan + pendapatan_hari_ini
            total_transaksi = historical_transaksi + transaksi_hari_ini

            # Step 10: Prepare Final Summary Data
            summary_data = {
                "total_pendapatan": int(total_pendapatan),
                "pendapatan_hari_ini": int(pendapatan_hari_ini),
                "total_transaksi": int(total_transaksi),
                "transaksi_hari_ini": int(transaksi_hari_ini),
                "waktu": latest_waktu,
            }

            # Step 11: Serialize and Return Response
            serializer = SummaryCardsSerializer(summary_data)
            return Response(serializer.data)

        except Exception as e:
            return Response({
                "status": "error", 
                "message": f"An error occurred: {str(e)}"
            }, status=500)