# app_revenue_details/views_filter_by_years.py

import json
from django.utils.decorators import method_decorator
from django.views.decorators.csrf import csrf_exempt
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.parsers import JSONParser
from django.db.models import Sum
from django.utils import timezone
from datetime import datetime
from decimal import Decimal
from app_income_parkir.models import IncomeParkir
from app_income_member.models import IncomeMember
from app_income_manual.models import IncomeManual
from app_users.utils import get_session_data_from_body, fetch_user_locations, is_admin_user

@method_decorator(csrf_exempt, name='dispatch')
class RevenueDetailsByYearsView(APIView):
    """
    API View to retrieve yearly revenue details with member data protection rules.
    Handles both location listing and detailed revenue data views.
    """
    parser_classes = [JSONParser]

    def should_show_member_data(self, target_date):
        """
        Determines if member data for a specific month should be displayed.
        Member data is only shown after the 5th of the following month.
        
        Args:
            target_date (datetime): The date for which to check member data visibility
        
        Returns:
            bool: True if member data should be shown, False otherwise
        """
        current_date = timezone.now().date()
        
        # Calculate cutoff date (6th of next month)
        if target_date.month == 12:
            cutoff_date = target_date.replace(year=target_date.year + 1, month=1, day=6)
        else:
            cutoff_date = target_date.replace(month=target_date.month + 1, day=6)
        
        return current_date >= cutoff_date

    def filter_member_data(self, member_data, target_date):
        """
        Filters member revenue data based on date cutoff rules.
        Returns zero for member revenue if cutoff date hasn't passed.
        
        Args:
            member_data (Decimal): The original member revenue value
            target_date (datetime): The date for which to filter member data
        
        Returns:
            Decimal: Filtered member revenue value
        """
        show_member_data = self.should_show_member_data(target_date)
        
        if not show_member_data:
            return Decimal('0')
        
        return member_data

    def get(self, request, *args, **kwargs):
        """
        Main GET method handling request validation and routing.
        Manages session data validation and routes to appropriate view method.
        """
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

            # Route to appropriate view method based on path
            if 'locations' in request.path:
                return self.get_locations(request)
            else:
                return self.view_by_locations(request, locations)
          
        except Exception as e:
            return Response({"status": "error", "message": f"An error occurred: {str(e)}"}, status=500)

    def get_locations(self, request):
        """
        Handles requests for listing available locations.
        Returns a list of unique locations accessible to the user.
        """
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

            # Step 2: Authorization Check
            is_admin = is_admin_user(session_data)
            if isinstance(is_admin, dict) and 'error' in is_admin:
                return Response({"status": "error", "message": is_admin['error']}, status=400)

            # Step 3: Fetch User Locations
            locations = fetch_user_locations(session_data)
            if isinstance(locations, dict) and 'error' in locations:
                return Response({"status": "error", "message": locations['error']}, status=400)

            # Step 4: Get Unique Locations
            unique_locations = IncomeParkir.objects.filter(id_lokasi__in=locations) \
                .values_list('id_lokasi__site', flat=True) \
                .distinct() \
                .order_by('id_lokasi')

            return Response({
                "status": "success",
                "locations": list(unique_locations)
            }, status=200)

        except Exception as e:
            return Response({
                "status": "error",
                "message": f"Failed to fetch locations: {str(e)}"
            }, status=500)

    def view_by_locations(self, request, locations):
        """
        Retrieves and processes yearly revenue data with member data protection rules.
        Applies data protection for member revenue based on date cutoffs.
        """
        try:
            # Fetch base parking data
            parkir_data = IncomeParkir.objects.filter(id_lokasi__in=locations) \
                .values('id_lokasi__site', 'tanggal__year', 'tanggal__month') \
                .annotate(
                    cash=Sum('cash'),
                    prepaid=Sum('prepaid'),
                    casual=Sum('casual'),
                    pass_field=Sum('pass_field')
                ) \
                .order_by('id_lokasi__site', 'tanggal__year', 'tanggal__month')

            # Fetch member data
            member_data = IncomeMember.objects.filter(id_lokasi__in=locations) \
                .values('id_lokasi__site', 'tanggal__year', 'tanggal__month') \
                .annotate(member=Sum('member'))

            # Fetch manual transaction data
            manual_data = IncomeManual.objects.filter(id_lokasi__in=locations) \
                .values('id_lokasi__site', 'tanggal__year', 'tanggal__month') \
                .annotate(
                    manual=Sum('manual'),
                    masalah=Sum('masalah')
                ) \
                .order_by('id_lokasi__site', 'tanggal__year', 'tanggal__month')

            # Initialize result structure
            result = {}

            # Process each year's data with monthly member data protection
            for parkir in parkir_data:
                lokasi = parkir['id_lokasi__site']
                tahun = parkir['tanggal__year']
                bulan = parkir['tanggal__month']

                # Get base revenue values
                cash = Decimal(parkir['cash'] or 0)
                prepaid = Decimal(parkir['prepaid'] or 0)
                casual = Decimal(parkir['casual'] or 0)
                pass_field = Decimal(parkir['pass_field'] or 0)
                
                # Create target date for member data protection check
                target_date = datetime(tahun, bulan, 1).date()
                
                # Get and filter member data based on protection rules
                raw_member = Decimal(next(
                    (m['member'] for m in member_data 
                     if m['tanggal__year'] == tahun 
                     and m['tanggal__month'] == bulan 
                     and m['id_lokasi__site'] == lokasi),
                    0
                ))
                member = self.filter_member_data(raw_member, target_date)
                
                # Get manual transaction data
                manual = Decimal(next(
                    (man['manual'] for man in manual_data 
                     if man['tanggal__year'] == tahun 
                     and man['tanggal__month'] == bulan 
                     and man['id_lokasi__site'] == lokasi),
                    0
                ) or 0)
                masalah = Decimal(next(
                    (man['masalah'] for man in manual_data 
                     if man['tanggal__year'] == tahun 
                     and man['tanggal__month'] == bulan 
                     and man['id_lokasi__site'] == lokasi),
                    0
                ) or 0)

                # Calculate totals for the period
                total_qty = casual + pass_field
                total_pendapatan = cash + prepaid + manual + member - masalah

                # Initialize location in result if not exists
                if lokasi not in result:
                    result[lokasi] = []

                # Find existing year entry or create new one
                year_entry = next(
                    (entry for entry in result[lokasi] if isinstance(entry, dict) and entry.get('tahun') == tahun),
                    None
                )

                if year_entry is None:
                    year_entry = {
                        'tahun': tahun,
                        'tarif_tunai': Decimal('0'),
                        'tarif_non_tunai': Decimal('0'),
                        'member': Decimal('0'),
                        'manual': Decimal('0'),
                        'tiket_masalah': Decimal('0'),
                        'total_pendapatan': Decimal('0'),
                        'qty_casual': Decimal('0'),
                        'qty_pass': Decimal('0'),
                        'total_qty': Decimal('0')
                    }
                    result[lokasi].append(year_entry)

                # Update year totals
                year_entry['tarif_tunai'] += cash
                year_entry['tarif_non_tunai'] += prepaid
                year_entry['member'] += member  # Using protected member data
                year_entry['manual'] += manual
                year_entry['tiket_masalah'] += masalah
                year_entry['total_pendapatan'] += total_pendapatan
                year_entry['qty_casual'] += casual
                year_entry['qty_pass'] += pass_field
                year_entry['total_qty'] += total_qty

            # Calculate statistics for each location
            for lokasi, data_list in result.items():
                # Filter out the statistics entry if it exists
                year_entries = [entry for entry in data_list if 'tahun' in entry]

                # Calculate totals
                totals = {
                    'tarif_tunai': sum(d['tarif_tunai'] for d in year_entries),
                    'tarif_non_tunai': sum(d['tarif_non_tunai'] for d in year_entries),
                    'member': sum(d['member'] for d in year_entries),
                    'manual': sum(d['manual'] for d in year_entries),
                    'tiket_masalah': sum(d['tiket_masalah'] for d in year_entries),
                    'total_pendapatan': sum(d['total_pendapatan'] for d in year_entries),
                    'qty_casual': sum(d['qty_casual'] for d in year_entries),
                    'qty_pass': sum(d['qty_pass'] for d in year_entries),
                    'total_qty': sum(d['total_qty'] for d in year_entries)
                }

                # Calculate min, max, and average values
                minimal = {key: min(d[key] for d in year_entries) for key in totals.keys()}
                maksimal = {key: max(d[key] for d in year_entries) for key in totals.keys()}
                rerata = {key: value / len(year_entries) for key, value in totals.items()}

                # Append statistics to location data
                result[lokasi].append({
                    'total': totals,
                    'minimal': minimal,
                    'maksimal': maksimal,
                    'rata-rata': rerata
                })

            return Response(result, status=200)

        except Exception as e:
            return Response({
                "status": "error",
                "message": f"Error processing revenue data: {str(e)}"
            }, status=500)