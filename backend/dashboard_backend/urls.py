# project_dashboard/urls.py
from django.contrib import admin
from django.urls import path, include

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/users/', include('app_users.urls')),

    path('api/', include('app_locations.urls')),
    path('api/', include('app_users_locations.urls')),


    path('api/', include('app_revenue_realtime.urls')),
    path('api/', include('app_post_status.urls')),

    path('api/', include('app_income_parkir.urls')),
    path('api/', include('app_income_member.urls')),
    path('api/', include('app_income_manual.urls')),

    path('api/', include('app_revenue_trends.urls')),
    path('api/', include('app_revenue_details.urls')),
    path('api/', include('app_revenue_trends_by_locations.urls')),

    path('api/', include('app_trouble_transactions.urls')),

    path('api/', include('app_traffic_hours.urls')),


    # path('api/', include('app_traffic_per_hours.urls')),
    # path('api/revenue/', include('app_revenue_trends.urls')),  # Include this line
    # path('api/', include('app_revenue_by_locations.urls')),
    # path('api/', include('app_summary_cards.urls')),
    # path('api/', include('app_revenue_trends.urls')),
    # path('api/', include('app_transaction_quantity.urls')),
    # path('api/', include('app_vehicle_demographics.urls')),
]