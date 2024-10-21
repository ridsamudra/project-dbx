# app_users_locations/urls.py

from django.urls import path
from .views import UsersLocationsViewSet

# Define action untuk list dan create
userslocations_list = UsersLocationsViewSet.as_view({
    'get': 'list',   # Buat melihat data (list all)
    'post': 'create' # Kalau loe mau tambah data
})

# Define action untuk retrieve, update, dan delete (detail)
userslocations_detail = UsersLocationsViewSet.as_view({
    'get': 'retrieve',        # Buat lihat detail data (specific id)
    'put': 'update',          # Full update
    'patch': 'partial_update',# Partial update
    'delete': 'destroy'       # Hapus data
})

# URL patterns
urlpatterns = [
    path('userslocations/', userslocations_list, name='userslocations-list'),    
    path('userslocations/<int:pk>/', userslocations_detail, name='userslocations-detail'), 
]
