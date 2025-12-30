"""
URL patterns for Itinerary endpoints.
"""
from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import ItineraryViewSet, ItineraryItemViewSet

router = DefaultRouter()
router.register(r'', ItineraryViewSet, basename='itinerary')
router.register(r'items', ItineraryItemViewSet, basename='itinerary-item')

urlpatterns = [
    path('', include(router.urls)),
]

