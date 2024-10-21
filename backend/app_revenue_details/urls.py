# app_revenue_details/urls.py

from django.urls import path
from . views_filter_by_days import RevenueDetailsByDaysView
from . views_filter_by_months import RevenueDetailsByMonthsView
from . views_filter_by_years import RevenueDetailsByYearsView

urlpatterns = [
    # for locations data
    path('revenuedetails/locations/', RevenueDetailsByDaysView.as_view(), name='revenue_details_locations'),
    
    # filter by days
    path('revenuedetails/filterbydays/', RevenueDetailsByDaysView.as_view(), name='revenue_details_filter_by_days'),

    # filter by months
    path('revenuedetails/filterbymonths/', RevenueDetailsByMonthsView.as_view(), name='revenue_details_filter_by_months'),

    # filter by years
    path('revenuedetails/filterbyyears/', RevenueDetailsByYearsView.as_view(), name='revenue_details_filter_by_years'),
]

