# app_revenue_trends_by_locations/urls.py

from django.urls import path
from . views_filter_by_days import RevenueByDaysView
from . views_filter_by_months import RevenueByMonthsView
from . views_filter_by_years import RevenueByYearsView


urlpatterns = [
    path('revenuebylocations/filterbydays/', RevenueByDaysView.as_view(), name='revenue_last_7_days'),

    path('revenuebylocations/filterbymonths/', RevenueByMonthsView.as_view(), name='revenue_last_6_months'),

    path('revenuebylocations/filterbyyears/', RevenueByYearsView.as_view(), name='revenue_last_7_years'),
]
