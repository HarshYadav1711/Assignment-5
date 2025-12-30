"""
Views for Trip management.
"""
from rest_framework import viewsets, status, permissions
from rest_framework.decorators import action
from rest_framework.response import Response
from django.shortcuts import get_object_or_404
from .models import Trip, TripMember
from .serializers import TripSerializer, TripCreateSerializer, TripMemberSerializer
from .permissions import IsTripMember, IsTripOwnerOrEditor


class TripViewSet(viewsets.ModelViewSet):
    """
    ViewSet for Trip CRUD operations.
    
    List: Returns trips user is member of
    Create: Creates new trip and adds creator as owner
    Retrieve: Returns trip details (if member)
    Update: Updates trip (if owner/editor)
    Destroy: Deletes trip (if owner)
    """
    queryset = Trip.objects.all()
    permission_classes = [permissions.IsAuthenticated]
    
    def get_serializer_class(self):
        if self.action == 'create':
            return TripCreateSerializer
        return TripSerializer
    
    def get_queryset(self):
        """Return trips where user is a member."""
        user = self.request.user
        return Trip.objects.filter(members__user=user).distinct()
    
    def get_permissions(self):
        """Set permissions based on action."""
        if self.action in ['list', 'create']:
            return [permissions.IsAuthenticated()]
        elif self.action in ['retrieve', 'update', 'partial_update', 'destroy']:
            return [permissions.IsAuthenticated(), IsTripMember()]
        return super().get_permissions()
    
    @action(detail=True, methods=['get', 'post', 'delete'], url_path='members')
    def members(self, request, pk=None):
        """Manage trip members."""
        trip = self.get_object()
        
        if request.method == 'GET':
            members = trip.members.all()
            serializer = TripMemberSerializer(members, many=True)
            return Response(serializer.data)
        
        elif request.method == 'POST':
            # Add member (only owner/editor can add)
            if not IsTripOwnerOrEditor().has_object_permission(request, self, trip):
                return Response(
                    {'detail': 'Only owners and editors can add members.'},
                    status=status.HTTP_403_FORBIDDEN
                )
            
            user_id = request.data.get('user_id')
            role = request.data.get('role', 'viewer')
            
            if not user_id:
                return Response(
                    {'detail': 'user_id is required.'},
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            from django.contrib.auth import get_user_model
            User = get_user_model()
            user = get_object_or_404(User, id=user_id)
            
            member, created = TripMember.objects.get_or_create(
                trip=trip,
                user=user,
                defaults={'role': role, 'invited_by': request.user}
            )
            
            if not created:
                return Response(
                    {'detail': 'User is already a member.'},
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            serializer = TripMemberSerializer(member)
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        
        elif request.method == 'DELETE':
            # Remove member
            user_id = request.data.get('user_id')
            if not user_id:
                return Response(
                    {'detail': 'user_id is required.'},
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            member = get_object_or_404(TripMember, trip=trip, user_id=user_id)
            # Only owner can remove members, or user can remove themselves
            if request.user != trip.creator and request.user != member.user:
                return Response(
                    {'detail': 'Only owner can remove members.'},
                    status=status.HTTP_403_FORBIDDEN
                )
            
            member.delete()
            return Response(status=status.HTTP_204_NO_CONTENT)

