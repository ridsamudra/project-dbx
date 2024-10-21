from django.db import models
from app_locations.models import Locations  

class IncomeParkir(models.Model):
    id_lokasi = models.ForeignKey(Locations, on_delete=models.CASCADE, db_column='id_lokasi')
    tanggal = models.DateField()
    shift = models.CharField(max_length=20)
    kendaraan = models.CharField(max_length=20)
    kategori = models.CharField(max_length=10)
    tgl = models.SmallIntegerField()
    bln = models.SmallIntegerField()
    thn = models.SmallIntegerField()
    tarif = models.DecimalField(max_digits=10, decimal_places=2)
    cash = models.DecimalField(max_digits=10, decimal_places=2)
    prepaid = models.DecimalField(max_digits=10, decimal_places=2)
    casual = models.IntegerField()
    pass_field = models.IntegerField(db_column='pass')  # db_column biar tetap sinkron ke database

    class Meta:
        db_table = 'tt_sync_income_parkir'
        managed = False


