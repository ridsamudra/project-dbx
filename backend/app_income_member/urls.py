from django.urls import path
from .views import IncomeMemberListView, IncomeMemberByLokasiView

urlpatterns = [
    path('incomemember/', IncomeMemberListView.as_view(), name='income_member'),
    path('incomemember/lokasi/<int:id_lokasi>/', IncomeMemberByLokasiView.as_view(), name='income_member_by_lokasi'),
]
