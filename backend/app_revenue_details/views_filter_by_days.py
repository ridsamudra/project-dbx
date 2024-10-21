# app_revenue_details/views_filter_by_days.py

import json
from django.utils.decorators import method_decorator
from django.views.decorators.csrf import csrf_exempt
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.parsers import JSONParser
from django.db.models import Sum
from django.utils import timezone
from datetime import datetime
from calendar import monthrange
from decimal import Decimal
from app_income_parkir.models import IncomeParkir
from app_income_member.models import IncomeMember
from app_income_manual.models import IncomeManual
from app_users.utils import get_session_data_from_body, fetch_user_locations, is_admin_user

@method_decorator(csrf_exempt, name='dispatch')
class RevenueDetailsByDaysView(APIView):
    """
    API View to retrieve daily revenue details with member data protection rules.
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
        """
        try:
            # Reuse session data validation from main GET method
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

            # Authorization check
            is_admin = is_admin_user(session_data)
            if isinstance(is_admin, dict) and 'error' in is_admin:
                return Response({"status": "error", "message": is_admin['error']}, status=400)

            # Get user's authorized locations
            locations = fetch_user_locations(session_data)
            if isinstance(locations, dict) and 'error' in locations:
                return Response({"status": "error", "message": locations['error']}, status=400)

            # Get unique locations from IncomeParkir model
            unique_locations = IncomeParkir.objects.filter(id_lokasi__in=locations) \
                .values_list('id_lokasi__site', flat=True) \
                .distinct() \
                .order_by('id_lokasi')

            return Response({
                "status": "success",
                "locations": list(unique_locations)
            }, status=200)

        except Exception as e:
            return Response({"status": "error", "message": f"Failed to fetch locations: {str(e)}"}, status=500)

    def view_by_locations(self, request, locations):
        """
        Retrieves and processes daily revenue data with member data protection rules.
        """
        try:
            # Date range validation
            year = request.GET.get('year')
            month = request.GET.get('month')

            if not year or not month:
                return Response({"status": "error", "message": "Month and year filter is required."}, status=400)

            try:
                year = int(year)
                month = int(month)
            except ValueError:
                return Response({"status": "error", "message": "Invalid month or year format."}, status=400)

            # Calculate date range
            days_in_month = monthrange(year, month)[1]
            start_date = datetime(year, month, 1)
            end_date = datetime(year, month, days_in_month)

            # Fetch base data from all models
            parkir_data = IncomeParkir.objects.filter(
                id_lokasi__in=locations,
                tanggal__range=[start_date, end_date]
            ).values('id_lokasi__site', 'tanggal') \
             .annotate(
                cash=Sum('cash'),
                prepaid=Sum('prepaid'),
                casual=Sum('casual'),
                pass_field=Sum('pass_field')
             ).order_by('id_lokasi__site', 'tanggal')

            member_data = IncomeMember.objects.filter(
                id_lokasi__in=locations,
                tanggal__range=[start_date, end_date]
            ).values('id_lokasi__site', 'tanggal') \
             .annotate(member=Sum('member'))

            manual_data = IncomeManual.objects.filter(
                id_lokasi__in=locations,
                tanggal__range=[start_date, end_date]
            ).values('id_lokasi__site', 'tanggal') \
             .annotate(
                manual=Sum('manual'),
                masalah=Sum('masalah')
             ).order_by('id_lokasi__site', 'tanggal')

            # Initialize result dictionary
            result = {}

            # Process data for each location and date
            for parkir in parkir_data:
                lokasi = parkir['id_lokasi__site']
                tanggal = parkir['tanggal']

                # Get base revenue values
                cash = Decimal(parkir['cash'] or 0)
                prepaid = Decimal(parkir['prepaid'] or 0)
                casual = Decimal(parkir['casual'] or 0)
                pass_field = Decimal(parkir['pass_field'] or 0)
                
                # Get and filter member data based on protection rules
                raw_member = Decimal(next(
                    (m['member'] for m in member_data 
                     if m['tanggal'] == tanggal and m['id_lokasi__site'] == lokasi),
                    0
                ))
                member = self.filter_member_data(raw_member, tanggal)
                
                # Get manual transaction data
                manual = Decimal(next(
                    (man['manual'] for man in manual_data 
                     if man['tanggal'] == tanggal and man['id_lokasi__site'] == lokasi),
                    0
                ) or 0)
                masalah = Decimal(next(
                    (man['masalah'] for man in manual_data 
                     if man['tanggal'] == tanggal and man['id_lokasi__site'] == lokasi),
                    0
                ) or 0)

                # Calculate totals
                total_qty = casual + pass_field
                total_pendapatan = cash + prepaid + manual + member - masalah

                # Add data to result dictionary
                if lokasi not in result:
                    result[lokasi] = []

                result[lokasi].append({
                    'tanggal': tanggal,
                    'tarif_tunai': cash,
                    'tarif_non_tunai': prepaid,
                    'member': member,  # Protected member data
                    'manual': manual,
                    'tiket_masalah': masalah,
                    'total_pendapatan': total_pendapatan,
                    'qty_casual': casual,
                    'qty_pass': pass_field,
                    'total_qty': total_qty
                })

            # Calculate statistics for each location
            for lokasi, data_list in result.items():
                # Calculate totals
                totals = {
                    'tarif_tunai': sum(d['tarif_tunai'] for d in data_list),
                    'tarif_non_tunai': sum(d['tarif_non_tunai'] for d in data_list),
                    'member': sum(d['member'] for d in data_list),
                    'manual': sum(d['manual'] for d in data_list),
                    'tiket_masalah': sum(d['tiket_masalah'] for d in data_list),
                    'total_pendapatan': sum(d['total_pendapatan'] for d in data_list),
                    'qty_casual': sum(d['qty_casual'] for d in data_list),
                    'qty_pass': sum(d['qty_pass'] for d in data_list),
                    'total_qty': sum(d['total_qty'] for d in data_list)
                }

                # Calculate min, max, and average values
                minimal = {key: min(d[key] for d in data_list) for key in totals.keys()}
                maksimal = {key: max(d[key] for d in data_list) for key in totals.keys()}
                rerata = {key: value / len(data_list) for key, value in totals.items()}

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