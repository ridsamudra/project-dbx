from rest_framework import serializers
from .models import IncomeMember

class IncomeMemberSerializers(serializers.ModelSerializer):

    member = serializers.DecimalField(max_digits=10, decimal_places=2, 
    coerce_to_string=False)
    
    class Meta:
        model = IncomeMember
        # fields = '__all__'  
        fields = fields = ['id', 'id_lokasi', 'tanggal', 'tgl', 'bln', 'thn', 'member']