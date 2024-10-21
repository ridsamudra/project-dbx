from rest_framework.generics import ListAPIView, RetrieveAPIView
from .models import IncomeMember
from .serializers import IncomeMemberSerializers

class IncomeMemberListView(ListAPIView):
    queryset = IncomeMember.objects.all()
    serializer_class = IncomeMemberSerializers


# View baru untuk filter berdasarkan id_lokasi
class IncomeMemberByLokasiView(ListAPIView):
    serializer_class = IncomeMemberSerializers

    def get_queryset(self):
        id_lokasi = self.kwargs['id_lokasi']
        return IncomeMember.objects.filter(id_lokasi=id_lokasi)