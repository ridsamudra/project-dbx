# app_locations/models.py

from django.db import models

class Locations(models.Model):
    id = models.AutoField(primary_key=True)
    pengelola = models.CharField(max_length=255)
    site = models.CharField(max_length=255)
    alamat = models.CharField(max_length=255)
    
    class Meta:
        db_table = 'tm_lokasi'
        managed = False

    def __str__(self):
        return self.site