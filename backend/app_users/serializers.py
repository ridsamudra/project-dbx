# app_users/serializers.py

from rest_framework import serializers
from .models import Users

class UsersSerializer(serializers.ModelSerializer):
    class Meta:
        model = Users
        fields = ['id', 'id_user', 'nama_user', 'admin']  # password gak di-include untuk keamanan

