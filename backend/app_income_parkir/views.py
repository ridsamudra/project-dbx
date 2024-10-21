from rest_framework.generics import ListAPIView, RetrieveAPIView
from .models import IncomeParkir
from .serializers import IncomeParkirSerializers

class IncomeParkirListView(ListAPIView):
    queryset = IncomeParkir.objects.all()
    serializer_class = IncomeParkirSerializers


# View baru untuk filter berdasarkan id_lokasi
class IncomeParkirByLokasiView(ListAPIView):
    serializer_class = IncomeParkirSerializers

    def get_queryset(self):
        id_lokasi = self.kwargs['id_lokasi']
        return IncomeParkir.objects.filter(id_lokasi=id_lokasi)