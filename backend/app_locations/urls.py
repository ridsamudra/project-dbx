# app_locations/urls.py

from django.urls import path
from .views import LocationsListView, LocationsDetailView

urlpatterns = [
    path('locations/', LocationsListView.as_view(), name='locations'),
    path('locations/<int:id>/', LocationsDetailView.as_view(), name='locations_detail'),
]

