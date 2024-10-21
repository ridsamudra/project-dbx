# app_locations/serializers.py

from rest_framework import serializers
from .models import Locations

class LocationsSerializers(serializers.ModelSerializer):
    class Meta:
        model = Locations
        fields = fields = ['id', 'pengelola', 'site', 'alamat']
