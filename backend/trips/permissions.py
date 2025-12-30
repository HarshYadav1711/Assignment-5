"""
Custom permissions for Trip operations.
"""
from rest_framework import permissions
from .models import TripMember


class IsTripMember(permissions.BasePermission):
    """Permission to check if user is a member of the trip."""
    
    def has_object_permission(self, request, view, obj):
        return TripMember.objects.filter(trip=obj, user=request.user).exists()


class IsTripOwnerOrEditor(permissions.BasePermission):
    """Permission to check if user is owner or editor of the trip."""
    
    def has_object_permission(self, request, view, obj):
        membership = TripMember.objects.filter(trip=obj, user=request.user).first()
        if not membership:
            return False
        return membership.role in ['owner', 'editor']


class IsTripOwner(permissions.BasePermission):
    """Permission to check if user is owner of the trip."""
    
    def has_object_permission(self, request, view, obj):
        return obj.creator == request.user

