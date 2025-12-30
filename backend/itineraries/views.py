"""
Views for Itinerary management.
"""
from rest_framework import viewsets, permissions
from .models import Itinerary, ItineraryItem
from .serializers import (
    ItinerarySerializer,
    ItineraryCreateSerializer,
    ItineraryItemSerializer
)
from trips.permissions import IsTripMember


class ItineraryViewSet(viewsets.ModelViewSet):
    """
    ViewSet for Itinerary CRUD operations.
    
    Only trip members can access itineraries.
    """
    queryset = Itinerary.objects.all()
    serializer_class = ItinerarySerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_serializer_class(self):
        if self.action == 'create':
            return ItineraryCreateSerializer
        return ItinerarySerializer
    
    def get_queryset(self):
        """Filter by trip if provided, and only show trips user is member of."""
        from trips.models import TripMember
        user = self.request.user
        user_trips = TripMember.objects.filter(user=user).values_list('trip_id', flat=True)
        queryset = Itinerary.objects.filter(trip_id__in=user_trips)
        trip_id = self.request.query_params.get('trip_id')
        if trip_id:
            queryset = queryset.filter(trip_id=trip_id)
        return queryset
    
    def get_permissions(self):
        """Check trip membership for object-level permissions."""
        if self.action in ['retrieve', 'update', 'partial_update', 'destroy']:
            # Check if user is member of the trip
            return [permissions.IsAuthenticated()]
        return super().get_permissions()
    
    def check_object_permissions(self, request, obj):
        """Verify user is member of the trip."""
        from trips.models import TripMember
        if not TripMember.objects.filter(trip=obj.trip, user=request.user).exists():
            from rest_framework.exceptions import PermissionDenied
            raise PermissionDenied("You must be a member of this trip to access its itineraries.")
        super().check_object_permissions(request, obj)


class ItineraryItemViewSet(viewsets.ModelViewSet):
    """
    ViewSet for ItineraryItem CRUD operations.
    """
    queryset = ItineraryItem.objects.all()
    serializer_class = ItineraryItemSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        """Filter by itinerary if provided."""
        queryset = ItineraryItem.objects.all()
        itinerary_id = self.request.query_params.get('itinerary_id')
        if itinerary_id:
            queryset = queryset.filter(itinerary_id=itinerary_id)
        return queryset

