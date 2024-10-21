# app_trouble_transactions/urls.py

from django.urls import path
from . views_filter_by_days import TroubleByDaysView
from . views_filter_by_months import TroubleByMonthsView
from . views_filter_by_years import TroubleByYearsView

urlpatterns = [
    path('trouble/filterbydays/', TroubleByDaysView.as_view(), name='trouble_last_7_days'),
    
    path('trouble/filterbymonths/', TroubleByMonthsView.as_view(), name='trouble_last_6_months'),
    
    path('trouble/filterbyyears/', TroubleByYearsView.as_view(), name='trouble_last_6_years'),
]

