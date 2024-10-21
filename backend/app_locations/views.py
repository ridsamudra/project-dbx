# app_locations/views.py

from rest_framework.generics import ListAPIView, RetrieveAPIView
from .models import Locations
from .serializers import LocationsSerializers

class LocationsListView(ListAPIView):
    queryset = Locations.objects.all()
    serializer_class = LocationsSerializers 

class LocationsDetailView(RetrieveAPIView):
    queryset = Locations.objects.all()
    serializer_class = LocationsSerializers
    lookup_field = 'id'
