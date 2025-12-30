"""
Views for Trip management.

Includes CRUD operations, collaborator management, and email invitations.
"""
from rest_framework import viewsets, status, permissions
from rest_framework.decorators import action
from rest_framework.response import Response
from django.shortcuts import get_object_or_404
from django.contrib.auth import get_user_model
from django.core.mail import send_mail
from django.conf import settings
from django.template.loader import render_to_string
from .models import Trip, Collaborator
from .serializers import (
    TripSerializer,
    TripCreateSerializer,
    TripUpdateSerializer,
    CollaboratorSerializer,
    InviteCollaboratorSerializer
)
from .permissions import IsTripMember, IsTripOwnerOrEditor, IsTripOwner

User = get_user_model()


class TripViewSet(viewsets.ModelViewSet):
    """
    ViewSet for Trip CRUD operations.
    
    List: Returns trips user is collaborator on
    Create: Creates new trip and adds creator as owner
    Retrieve: Returns trip details (if collaborator)
    Update: Updates trip (if owner/editor)
    Destroy: Deletes trip (if owner)
    """
    queryset = Trip.objects.all()
    permission_classes = [permissions.IsAuthenticated]
    
    def get_serializer_class(self):
        if self.action == 'create':
            return TripCreateSerializer
        elif self.action in ['update', 'partial_update']:
            return TripUpdateSerializer
        return TripSerializer
    
    def get_queryset(self):
        """Return trips where user is a collaborator."""
        user = self.request.user
        return Trip.objects.filter(
            collaborators__user=user
        ).select_related('creator').prefetch_related(
            'collaborators__user',
            'collaborators__invited_by'
        ).distinct().order_by('-created_at')
    
    def get_permissions(self):
        """Set permissions based on action."""
        if self.action in ['list', 'create']:
            return [permissions.IsAuthenticated()]
        elif self.action == 'retrieve':
            return [permissions.IsAuthenticated(), IsTripMember()]
        elif self.action in ['update', 'partial_update']:
            return [permissions.IsAuthenticated(), IsTripOwnerOrEditor()]
        elif self.action == 'destroy':
            return [permissions.IsAuthenticated(), IsTripOwner()]
        return super().get_permissions()
    
    def get_serializer_context(self):
        """Add request to serializer context."""
        context = super().get_serializer_context()
        context['request'] = self.request
        return context
    
    @action(detail=True, methods=['get'], url_path='collaborators')
    def collaborators(self, request, pk=None):
        """
        List all collaborators for a trip.
        
        GET /api/v1/trips/{id}/collaborators/
        """
        trip = self.get_object()
        collaborators = trip.collaborators.select_related('user', 'invited_by').all()
        serializer = CollaboratorSerializer(collaborators, many=True)
        return Response(serializer.data)
    
    @action(detail=True, methods=['post'], url_path='invite')
    def invite(self, request, pk=None):
        """
        Invite a collaborator via email.
        
        POST /api/v1/trips/{id}/invite/
        {
            "email": "user@example.com",
            "role": "editor",
            "message": "Optional personal message"
        }
        """
        trip = self.get_object()
        
        # Check permission: only owner/editor can invite
        if not IsTripOwnerOrEditor().has_object_permission(request, self, trip):
            return Response(
                {'detail': 'Only owners and editors can invite collaborators.'},
                status=status.HTTP_403_FORBIDDEN
            )
        
        serializer = InviteCollaboratorSerializer(
            data=request.data,
            context={'trip': trip, 'request': request}
        )
        serializer.is_valid(raise_exception=True)
        
        email = serializer.validated_data['email']
        role = serializer.validated_data.get('role', 'viewer')
        message = serializer.validated_data.get('message', '')
        
        # Get or create user by email
        try:
            user = User.objects.get(email=email)
            user_exists = True
        except User.DoesNotExist:
            # User doesn't exist - create account invitation
            # In a real app, you might want to create a pending invitation record
            user = None
            user_exists = False
        
        # If user exists, add as collaborator immediately
        if user_exists:
            collaborator, created = Collaborator.objects.get_or_create(
                trip=trip,
                user=user,
                defaults={
                    'role': role,
                    'invited_by': request.user
                }
            )
            
            if not created:
                return Response(
                    {'detail': 'User is already a collaborator on this trip.'},
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            # Send invitation email
            self._send_invitation_email(trip, user, request.user, message, is_new_user=False)
            
            return Response(
                CollaboratorSerializer(collaborator).data,
                status=status.HTTP_201_CREATED
            )
        else:
            # User doesn't exist - send invitation to register
            # In production, you might store a pending invitation
            self._send_invitation_email(trip, None, request.user, message, email=email, is_new_user=True)
            
            return Response(
                {
                    'detail': 'Invitation sent. User will need to register to join the trip.',
                    'email': email
                },
                status=status.HTTP_202_ACCEPTED
            )
    
    def _send_invitation_email(self, trip, user, inviter, message='', email=None, is_new_user=False):
        """Send invitation email to collaborator."""
        recipient_email = user.email if user else email
        inviter_name = inviter.get_full_name() or inviter.email
        
        # Build email content
        subject = f'Invitation to collaborate on trip: {trip.title}'
        
        # Simple text email (in production, use HTML templates)
        email_body = f"""
Hello,

{inviter_name} has invited you to collaborate on the trip "{trip.title}".

"""
        
        if message:
            email_body += f"Message from {inviter_name}:\n{message}\n\n"
        
        if is_new_user:
            email_body += """
To join this trip, please register at [APP_URL]/register using this email address.

After registering, you'll automatically be added to the trip.
"""
        else:
            email_body += """
You can view and collaborate on this trip by logging into your account.

[APP_URL]/trips/{trip_id}
"""
        
        email_body += f"""
Best regards,
Smart Trip Planner Team
"""
        
        # Send email (synchronous - no Celery)
        try:
            send_mail(
                subject=subject,
                message=email_body,
                from_email=settings.DEFAULT_FROM_EMAIL,
                recipient_list=[recipient_email],
                fail_silently=False,
            )
        except Exception as e:
            # Log error but don't fail the request
            import logging
            logger = logging.getLogger(__name__)
            logger.error(f"Failed to send invitation email: {e}")
    
    @action(detail=True, methods=['post', 'delete'], url_path='collaborators/(?P<user_id>[^/.]+)')
    def collaborator_detail(self, request, pk=None, user_id=None):
        """
        Add or remove a collaborator.
        
        POST /api/v1/trips/{id}/collaborators/{user_id}/
        DELETE /api/v1/trips/{id}/collaborators/{user_id}/
        """
        trip = self.get_object()
        user = get_object_or_404(User, id=user_id)
        
        if request.method == 'POST':
            # Add collaborator (only owner/editor can add)
            if not IsTripOwnerOrEditor().has_object_permission(request, self, trip):
                return Response(
                    {'detail': 'Only owners and editors can add collaborators.'},
                    status=status.HTTP_403_FORBIDDEN
                )
            
            role = request.data.get('role', 'viewer')
            
            collaborator, created = Collaborator.objects.get_or_create(
                trip=trip,
                user=user,
                defaults={'role': role, 'invited_by': request.user}
            )
            
            if not created:
                return Response(
                    {'detail': 'User is already a collaborator on this trip.'},
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            serializer = CollaboratorSerializer(collaborator)
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        
        elif request.method == 'DELETE':
            # Remove collaborator
            collaborator = get_object_or_404(Collaborator, trip=trip, user=user)
            
            # Only owner can remove collaborators, or user can remove themselves
            # Prevent removing the last owner
            if collaborator.role == 'owner':
                owner_count = Collaborator.objects.filter(trip=trip, role='owner').count()
                if owner_count <= 1:
                    return Response(
                        {'detail': 'Cannot remove the last owner of a trip.'},
                        status=status.HTTP_400_BAD_REQUEST
                    )
            
            if request.user != trip.creator and request.user != collaborator.user:
                return Response(
                    {'detail': 'Only owner can remove collaborators, or you can remove yourself.'},
                    status=status.HTTP_403_FORBIDDEN
                )
            
            collaborator.delete()
            return Response(status=status.HTTP_204_NO_CONTENT)
