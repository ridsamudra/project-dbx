# app_traffic_hours/urls.py

from django.urls import path
# from . import views
from .views import TrafficHoursSummaryView

urlpatterns = [
    # path('traffic-data/', views.get_traffic_data, name='get_traffic_data'),
    path('traffichours/all', TrafficHoursSummaryView.as_view(), name='traffic-hours-all'),
    path('traffichours/bylocations', TrafficHoursSummaryView.as_view(), name='traffic-hours-bylocations'),
]
