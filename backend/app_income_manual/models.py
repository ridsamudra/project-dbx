from django.db import models
from app_locations.models import Locations  

class IncomeManual(models.Model):
    id_lokasi = models.ForeignKey(Locations, on_delete=models.CASCADE, db_column='id_lokasi')
    tanggal = models.DateField()
    shift = models.CharField(max_length=20)    
    tgl = models.IntegerField()
    bln = models.IntegerField()
    thn = models.IntegerField()
    manual = models.DecimalField(max_digits=10, decimal_places=2)
    masalah = models.DecimalField(max_digits=10, decimal_places=2)
    
    class Meta:
        db_table = 'tt_sync_income_manual'
        managed = False


