# app_users/models.py

from django.db import models

class Users(models.Model):
    id = models.AutoField(primary_key=True)
    id_user = models.CharField(max_length=64, unique=True)
    nama_user = models.CharField(max_length=64)
    password = models.CharField(max_length=64)  # Plain text, bisa nanti dihash pas save
    admin = models.IntegerField(default=0)  # 1 = Admin, 0 = Non-admin

    class Meta:
        db_table = 'tm_user'
        managed = False

    def __str__(self):
        return self.nama_user

