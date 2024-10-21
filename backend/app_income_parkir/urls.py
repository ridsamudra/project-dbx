from django.urls import path
# from .views import IncomeParkirListView, IncomeParkirDetailView
from .views import IncomeParkirListView, IncomeParkirByLokasiView


urlpatterns = [
    path('incomeparkir/', IncomeParkirListView.as_view(), name='income_parkir'),
    path('incomeparkir/lokasi/<int:id_lokasi>/', IncomeParkirByLokasiView.as_view(), name='income_parkir_by_lokasi'),
]
