# app_users/urls.py

from django.urls import path
from .views import login_view, logout_view, list_user, add_user, update_user, delete_user, change_password, manage_user_locations, list_locations, get_user_locations

urlpatterns = [
    path('login/', login_view, name='login'),
    path('logout/', logout_view, name='logout'),
    path('list_user/', list_user, name='list_user'),
    path('add_user/', add_user, name='add_user'),
    path('update_user/', update_user, name='update_user'),
    path('delete_user/', delete_user, name='delete_user'),
    path('change_password/', change_password, name='change_password'),
    path('manage_user_locations/', manage_user_locations, name='manage_user_locations'),
    path('list_locations/', list_locations, name='list_locations'),
    path('get_user_locations/', get_user_locations, name='get_user_locations'),

]