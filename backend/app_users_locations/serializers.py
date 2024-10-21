# app_users_locations/serializers.py

from rest_framework import serializers
from .models import UsersLocations

class UsersLocationsSerializer(serializers.ModelSerializer):
    class Meta:
        model = UsersLocations
        fields = ['id', 'id_lokasi', 'id_user']
