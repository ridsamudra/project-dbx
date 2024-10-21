# app_users_locations/models.py

from django.db import models
from app_users.models import Users  # Import dari app_users
from app_locations.models import Locations  # Import dari app_locations


class UsersLocations(models.Model):
    id = models.AutoField(primary_key=True)
    id_lokasi = models.ForeignKey(Locations, on_delete=models.CASCADE, db_column='id_lokasi')
    id_user = models.ForeignKey(Users, on_delete=models.CASCADE, db_column='id_user')

    class Meta:
        db_table = 'tm_lokasi_user'
        managed = False