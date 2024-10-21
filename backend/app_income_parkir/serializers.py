from rest_framework import serializers
from .models import IncomeParkir

class IncomeParkirSerializers(serializers.ModelSerializer):
    
    tarif = serializers.DecimalField(max_digits=10, decimal_places=2, coerce_to_string=False)
    cash = serializers.DecimalField(max_digits=10, decimal_places=2, coerce_to_string=False)
    prepaid = serializers.DecimalField(max_digits=10, decimal_places=2, 
    coerce_to_string=False)
    
    class Meta:
        model = IncomeParkir
        # fields = '__all__'  
        fields = fields = ['id', 'id_lokasi', 'tanggal', 'shift', 'kendaraan', 'kategori', 'tgl', 'bln', 'thn', 'tarif', 'cash', 'prepaid', 'casual', 'pass_field']
