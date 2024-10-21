# app_traffic_hours/serializers.py

from rest_framework import serializers
from .models import TrafficHours

class TrafficHoursSerializer(serializers.ModelSerializer):
    total_transaksi = serializers.IntegerField() 
    total_pendapatan = serializers.IntegerField()   

