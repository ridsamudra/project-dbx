# app_revenue_realtime/serializers.py

from rest_framework import serializers

# data JSON untuk widget/views views_summary_cards.py
class SummaryCardsSerializer(serializers.Serializer):
    total_pendapatan = serializers.IntegerField()
    pendapatan_hari_ini = serializers.IntegerField()
    total_transaksi = serializers.IntegerField()
    transaksi_hari_ini = serializers.IntegerField()
    waktu = serializers.DateTimeField()

# data JSON untuk widget/views views_revenue_realtime.py
class RevenueRealtimeSerializer(serializers.Serializer):
    # id_lokasi = serializers.CharField(max_length=255)  # Ditambahkan sesuai request
    waktu = serializers.DateTimeField()
    jenis_kendaraan = serializers.CharField(max_length=50)
    jumlah_transaksi = serializers.IntegerField()
    jumlah_pendapatan = serializers.IntegerField()

# data JSON untuk widget/views views_revenue_by_locations.py
class RevenueByLocationsSerializer(serializers.Serializer):
    waktu = serializers.DateTimeField()
    id_lokasi = serializers.CharField(max_length=255)
    total_transaksi = serializers.IntegerField()
    total_pendapatan = serializers.IntegerField()
    # lihat_detail = serializers.CharField(max_length=50)
