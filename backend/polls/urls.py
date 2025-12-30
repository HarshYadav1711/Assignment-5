"""
URL patterns for Poll endpoints.
"""
from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import PollViewSet

router = DefaultRouter()
router.register(r'', PollViewSet, basename='poll')

urlpatterns = [
    path('', include(router.urls)),
]

