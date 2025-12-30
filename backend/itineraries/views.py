"""
Views for Itinerary management.

Includes CRUD operations and item reordering.
"""
from rest_framework import viewsets, status, permissions
from rest_framework.decorators import action
from rest_framework.response import Response
from django.db import transaction, models
from .models import Itinerary, ItineraryItem
from .serializers import (
    ItinerarySerializer,
    ItineraryCreateSerializer,
    ItineraryItemSerializer,
    ReorderItemsSerializer
)
from trips.permissions import IsTripOwnerOrEditor


class ItineraryViewSet(viewsets.ModelViewSet):
    """
    ViewSet for Itinerary CRUD operations.
    
    Only trip collaborators can access itineraries.
    Owners and editors can create/update/delete.
    """
    queryset = Itinerary.objects.all()
    permission_classes = [permissions.IsAuthenticated]
    
    def get_serializer_class(self):
        if self.action == 'create':
            return ItineraryCreateSerializer
        return ItinerarySerializer
    
    def get_queryset(self):
        """Filter by trip if provided, and only show trips user is collaborator on."""
        from trips.models import Collaborator
        user = self.request.user
        user_trips = Collaborator.objects.filter(user=user).values_list('trip_id', flat=True)
        queryset = Itinerary.objects.filter(trip_id__in=user_trips).select_related('trip').prefetch_related('items')
        
        trip_id = self.request.query_params.get('trip_id')
        if trip_id:
            queryset = queryset.filter(trip_id=trip_id)
        
        return queryset.order_by('date', 'created_at')
    
    def get_permissions(self):
        """Set permissions based on action."""
        if self.action in ['list', 'retrieve']:
            return [permissions.IsAuthenticated()]
        elif self.action in ['create', 'update', 'partial_update', 'destroy']:
            return [permissions.IsAuthenticated(), IsTripOwnerOrEditor()]
        return super().get_permissions()
    
    def check_object_permissions(self, request, obj):
        """Verify user is collaborator of the trip."""
        from trips.models import Collaborator
        if not Collaborator.objects.filter(trip=obj.trip, user=request.user).exists():
            from rest_framework.exceptions import PermissionDenied
            raise PermissionDenied("You must be a collaborator of this trip to access its itineraries.")
        super().check_object_permissions(request, obj)
    
    @action(detail=True, methods=['post'], url_path='items/reorder')
    def reorder_items(self, request, pk=None):
        """
        Reorder items within an itinerary.
        
        POST /api/v1/itineraries/{id}/items/reorder/
        {
            "item_ids": ["uuid1", "uuid2", "uuid3"]
        }
        
        Items will be reordered: first ID gets order=0, second gets order=1, etc.
        """
        itinerary = self.get_object()
        
        # Check permission: only owner/editor can reorder
        if not IsTripOwnerOrEditor().has_object_permission(request, self, itinerary.trip):
            return Response(
                {'detail': 'Only owners and editors can reorder items.'},
                status=status.HTTP_403_FORBIDDEN
            )
        
        serializer = ReorderItemsSerializer(
            data=request.data,
            context={'itinerary': itinerary}
        )
        serializer.is_valid(raise_exception=True)
        
        item_ids = serializer.validated_data['item_ids']
        
        # Reorder items in a transaction
        with transaction.atomic():
            # Update order for each item
            for order, item_id in enumerate(item_ids):
                ItineraryItem.objects.filter(
                    id=item_id,
                    itinerary=itinerary
                ).update(order=order)
        
        # Return updated items
        items = ItineraryItem.objects.filter(
            itinerary=itinerary
        ).order_by('order')
        
        return Response({
            'detail': 'Items reordered successfully.',
            'items': ItineraryItemSerializer(items, many=True).data
        }, status=status.HTTP_200_OK)


class ItineraryItemViewSet(viewsets.ModelViewSet):
    """
    ViewSet for ItineraryItem CRUD operations.
    
    Only trip collaborators can access items.
    Owners and editors can create/update/delete.
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
        return queryset.order_by('order', 'start_time')
    
    def get_permissions(self):
        """Set permissions based on action."""
        if self.action in ['list', 'retrieve']:
            return [permissions.IsAuthenticated()]
        elif self.action in ['create', 'update', 'partial_update', 'destroy']:
            return [permissions.IsAuthenticated(), IsTripOwnerOrEditor()]
        return super().get_permissions()
    
    def check_object_permissions(self, request, obj):
        """Verify user is collaborator of the trip."""
        from trips.models import Collaborator
        if not Collaborator.objects.filter(trip=obj.itinerary.trip, user=request.user).exists():
            from rest_framework.exceptions import PermissionDenied
            raise PermissionDenied("You must be a collaborator of this trip to access its items.")
        
        # For write operations, check owner/editor permission
        if request.method not in ['GET', 'HEAD', 'OPTIONS']:
            if not IsTripOwnerOrEditor().has_object_permission(request, self, obj.itinerary.trip):
                from rest_framework.exceptions import PermissionDenied
                raise PermissionDenied("Only owners and editors can modify items.")
        
        super().check_object_permissions(request, obj)
    
    def perform_create(self, serializer):
        """Create item and assign order."""
        itinerary = serializer.validated_data['itinerary']
        
        # Auto-assign order if not provided
        if 'order' not in serializer.validated_data or serializer.validated_data.get('order') == 0:
            max_order = ItineraryItem.objects.filter(itinerary=itinerary).aggregate(
                max_order=models.Max('order')
            )['max_order'] or 0
            serializer.save(order=max_order + 1)
        else:
            serializer.save()
