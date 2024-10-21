from rest_framework.generics import ListAPIView, RetrieveAPIView
from .models import IncomeManual
from .serializers import IncomeManualSerializers

class IncomeManualListView(ListAPIView):
    queryset = IncomeManual.objects.all()
    serializer_class = IncomeManualSerializers


# View baru untuk filter berdasarkan id_lokasi
class IncomeManualByLokasiView(ListAPIView):
    serializer_class = IncomeManualSerializers

    def get_queryset(self):
        id_lokasi = self.kwargs['id_lokasi']
        return IncomeManual.objects.filter(id_lokasi=id_lokasi)