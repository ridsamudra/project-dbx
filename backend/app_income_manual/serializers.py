from rest_framework import serializers
from .models import IncomeManual

class IncomeManualSerializers(serializers.ModelSerializer):
    
    manual = serializers.DecimalField(max_digits=10, decimal_places=2, coerce_to_string=False)
    masalah = serializers.DecimalField(max_digits=10, decimal_places=2, coerce_to_string=False)
    
    class Meta:
        model = IncomeManual
        # fields = '__all__'  
        fields = fields = [
            'id', 
            'id_lokasi', 
            'tanggal', 
            'shift',  
            'tgl', 
            'bln', 
            'thn', 
            'manual',
            'masalah'
        ]
