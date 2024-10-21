# app_post_status/serializers.py

from rest_framework import serializers
from .models import PostStatus

class PostStatusSerializer(serializers.ModelSerializer):      
    total_transaksi_pos_online = serializers.IntegerField()
    total_transaksi_pos_ofline = serializers.IntegerField()
    jumlah_pos_online = serializers.IntegerField()
    jumlah_pos_offline = serializers.IntegerField()

