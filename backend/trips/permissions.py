"""
Custom permissions for Trip operations.
"""
from rest_framework import permissions
from .models import Collaborator


class IsTripMember(permissions.BasePermission):
    """Permission to check if user is a collaborator of the trip."""
    
    def has_object_permission(self, request, view, obj):
        return Collaborator.objects.filter(trip=obj, user=request.user).exists()


class IsTripOwnerOrEditor(permissions.BasePermission):
    """Permission to check if user is owner or editor of the trip."""
    
    def has_object_permission(self, request, view, obj):
        collaboration = Collaborator.objects.filter(trip=obj, user=request.user).first()
        if not collaboration:
            return False
        return collaboration.role in ['owner', 'editor']


class IsTripOwner(permissions.BasePermission):
    """Permission to check if user is owner of the trip."""
    
    def has_object_permission(self, request, view, obj):
        collaboration = Collaborator.objects.filter(trip=obj, user=request.user).first()
        if not collaboration:
            return False
        return collaboration.role == 'owner'
