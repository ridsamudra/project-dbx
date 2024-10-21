# app_post_status/urls.py

from django.urls import path
from .views import PostStatusSummaryView

urlpatterns = [
    path('poststatus/all', PostStatusSummaryView.as_view(), name='post-status-summary-all'),
    path('poststatus/bylocations', PostStatusSummaryView.as_view(), name='post-status-summary-bylocations'),
]

