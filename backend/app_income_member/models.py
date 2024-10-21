from django.db import models
from app_locations.models import Locations  

class IncomeMember(models.Model):
    id_lokasi = models.ForeignKey(Locations, on_delete=models.CASCADE, db_column='id_lokasi')
    tanggal = models.DateField()
    tgl = models.IntegerField()
    bln = models.IntegerField()
    thn = models.IntegerField()
    member = models.DecimalField(max_digits=10, decimal_places=2)

    class Meta:
        db_table = 'tt_sync_income_member'
        managed = False


