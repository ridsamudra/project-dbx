from django.urls import path
from .views import IncomeManualListView, IncomeManualByLokasiView

urlpatterns = [
    path('incomemanual/', IncomeManualListView.as_view(), name='income_manual'),
    path('incomemanual/lokasi/<int:id_lokasi>/', IncomeManualByLokasiView.as_view(), name='income_manual_by_lokasi'),
]
