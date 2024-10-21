# app_revenue_realtime/urls.py

from django.urls import path
from .views_summary_cards import SummaryCardsView
from .views_revenue_realtime import RevenueRealtimeView
from .views_revenue_by_locations import RevenueByLocationsView

urlpatterns = [
    path('summarycards/', SummaryCardsView.as_view(), name='summary_cards'),
    
    # path('revenuerealtime/', RevenueRealtimeView.as_view(), name='revenue_realtime'),
    path('revenuerealtime/all', RevenueRealtimeView.as_view(), name='revenue_realtime_all'),
    path('revenuerealtime/bylocations', RevenueRealtimeView.as_view(), name='revenue_realtime_bylocations'),
    
    # path('revenuebylocations/', RevenueByLocationsView.as_view(), name='revenue_by_locations'),
    path('revenuebylocations/all', RevenueByLocationsView.as_view(), name='revenue_by_locations_all'),
    path('revenuebylocations/bylocations', RevenueByLocationsView.as_view(), name='revenue_by_locations_by_locations'),
]

