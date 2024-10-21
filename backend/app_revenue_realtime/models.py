# app_revenue_realtime/models.py

from django.db import models
from app_locations.models import Locations

class RevenueRealtime(models.Model):
    id_lokasi = models.ForeignKey(Locations, on_delete=models.CASCADE, db_column='id_lokasi')
    tanggal = models.DateField()
    shift = models.CharField(max_length=50)
    waktu = models.DateTimeField()
    kendaraan = models.CharField(max_length=100)
    qty = models.IntegerField()
    jumlah = models.DecimalField(max_digits=10, decimal_places=2)

    class Meta:
        db_table = 'tt_sync_realtime'
        managed = False

