# app_post_status/models.py

from django.db import models
from app_locations.models import Locations

class PostStatus(models.Model):
    id_lokasi = models.ForeignKey(Locations, on_delete=models.CASCADE, db_column='id_lokasi')
    pos = models.CharField(max_length=255)
    aktif = models.BooleanField(default=False)
    trafic = models.IntegerField()

    class Meta:
        db_table = 'tt_pos_aktif'
        managed = False
    