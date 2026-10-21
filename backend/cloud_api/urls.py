from django.urls import path
from . import views

urlpatterns = [
    path('health', views.health),
    path('auth/login', views.login),
    path('auth/logout', views.logout),
    path('auth/me', views.me),
    path('invoices', views.invoices),
    path('invoices/<str:invoice_id>', views.invoice_detail),
    path('invoices/<str:invoice_id>/<str:action>', views.invoice_transition),
]
