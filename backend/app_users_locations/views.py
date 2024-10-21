# app_users_locations/views.py

from rest_framework import viewsets
from .models import UsersLocations
from .serializers import UsersLocationsSerializer

class UsersLocationsViewSet(viewsets.ModelViewSet):
    queryset = UsersLocations.objects.all()
    serializer_class = UsersLocationsSerializer
