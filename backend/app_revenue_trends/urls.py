# app_revenue_trends/urls.py

from django.urls import path
from . views_filter_by_days import RevenueByDaysView
from . views_filter_by_months import RevenueByMonthsView 
from . views_filter_by_years import RevenueByYearsView 

urlpatterns = [
    # Revenue filtered by the last 7 days
    path('revenue/filterbydays/all', RevenueByDaysView.as_view(), name='revenue_last_7_days'),
    path('revenue/filterbydays/bylocations', RevenueByDaysView.as_view(), name='revenue_last_7_days_by_locations'),
    
    # Revenue filtered by the last 6 months
    path('revenue/filterbymonths/all', RevenueByMonthsView.as_view(),name='revenue_last_6_months'),
    path('revenue/filterbymonths/bylocations', RevenueByMonthsView.as_view(),name='revenue_last_6_months_by_locations'),


    # Revenue filtered by the last 6 years
    path('revenue/filterbyyears/all', RevenueByYearsView.as_view(), name='revenue_last_6_years'),
    path('revenue/filterbyyears/bylocations', RevenueByYearsView.as_view(), name='revenue_last_6_years_by_locations'),
]

