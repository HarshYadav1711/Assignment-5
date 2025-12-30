"""
Views for Poll management.

Includes CRUD operations and voting functionality.
"""
from rest_framework import viewsets, status, permissions
from rest_framework.decorators import action
from rest_framework.response import Response
from django.shortcuts import get_object_or_404
from django.db import transaction, models
from .models import Poll, PollOption, Vote
from .serializers import (
    PollSerializer,
    PollCreateSerializer,
    PollOptionSerializer,
    VoteSerializer,
    VoteRequestSerializer
)
from trips.permissions import IsTripOwnerOrEditor


class PollViewSet(viewsets.ModelViewSet):
    """
    ViewSet for Poll CRUD operations.
    
    Only trip collaborators can access polls.
    Owners and editors can create/update/delete.
    """
    queryset = Poll.objects.all()
    permission_classes = [permissions.IsAuthenticated]
    
    def get_serializer_class(self):
        if self.action == 'create':
            return PollCreateSerializer
        return PollSerializer
    
    def get_queryset(self):
        """Filter by trip if provided, and only show trips user is collaborator on."""
        from trips.models import Collaborator
        user = self.request.user
        user_trips = Collaborator.objects.filter(user=user).values_list('trip_id', flat=True)
        queryset = Poll.objects.filter(
            trip_id__in=user_trips
        ).select_related('created_by', 'trip').prefetch_related(
            'options__votes'
        )
        
        trip_id = self.request.query_params.get('trip_id')
        if trip_id:
            queryset = queryset.filter(trip_id=trip_id)
        
        # Filter by active status if provided
        is_active = self.request.query_params.get('is_active')
        if is_active is not None:
            queryset = queryset.filter(is_active=is_active.lower() == 'true')
        
        return queryset.order_by('-created_at')
    
    def get_permissions(self):
        """Set permissions based on action."""
        if self.action in ['list', 'retrieve']:
            return [permissions.IsAuthenticated()]
        elif self.action in ['create', 'update', 'partial_update', 'destroy']:
            return [permissions.IsAuthenticated(), IsTripOwnerOrEditor()]
        return super().get_permissions()
    
    def get_serializer_context(self):
        """Add request to serializer context."""
        context = super().get_serializer_context()
        context['request'] = self.request
        return context
    
    def check_object_permissions(self, request, obj):
        """Verify user is collaborator of the trip."""
        from trips.models import Collaborator
        if not Collaborator.objects.filter(trip=obj.trip, user=request.user).exists():
            from rest_framework.exceptions import PermissionDenied
            raise PermissionDenied("You must be a collaborator of this trip to access its polls.")
        super().check_object_permissions(request, obj)
    
    @action(detail=True, methods=['post', 'delete'], url_path='vote')
    def vote(self, request, pk=None):
        """
        Vote for a poll option or remove vote.
        
        POST /api/v1/polls/{id}/vote/
        {
            "option_id": "uuid"
        }
        
        DELETE /api/v1/polls/{id}/vote/
        {
            "option_id": "uuid"
        }
        """
        poll = self.get_object()
        
        if request.method == 'POST':
            serializer = VoteRequestSerializer(data=request.data)
            serializer.is_valid(raise_exception=True)
            option_id = serializer.validated_data['option_id']
            
            option = get_object_or_404(PollOption, id=option_id, poll=poll)
            
            # Check if poll is active
            if not poll.is_active:
                return Response(
                    {'detail': 'Cannot vote on an inactive poll.'},
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            # Check if poll has closed
            if poll.closes_at:
                from django.utils import timezone
                if poll.closes_at < timezone.now():
                    return Response(
                        {'detail': 'This poll has closed.'},
                        status=status.HTTP_400_BAD_REQUEST
                    )
            
            # Check if user already voted for this option
            vote, created = Vote.objects.get_or_create(
                poll=poll,
                option=option,
                user=request.user
            )
            
            if not created:
                return Response(
                    {'detail': 'You have already voted for this option.'},
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            vote_serializer = VoteSerializer(vote, context={'request': request})
            return Response(vote_serializer.data, status=status.HTTP_201_CREATED)
        
        elif request.method == 'DELETE':
            serializer = VoteRequestSerializer(data=request.data)
            serializer.is_valid(raise_exception=True)
            option_id = serializer.validated_data['option_id']
            
            vote = get_object_or_404(
                Vote,
                poll=poll,
                option_id=option_id,
                user=request.user
            )
            vote.delete()
            return Response(status=status.HTTP_204_NO_CONTENT)
    
    @action(detail=True, methods=['get'], url_path='results')
    def results(self, request, pk=None):
        """
        Get poll results with vote counts.
        
        GET /api/v1/polls/{id}/results/
        """
        poll = self.get_object()
        
        # Annotate options with vote counts
        options = PollOption.objects.filter(poll=poll).annotate(
            vote_count=models.Count('votes')
        ).order_by('order')
        
        option_serializer = PollOptionSerializer(
            options,
            many=True,
            context={'request': request}
        )
        
        total_votes = Vote.objects.filter(poll=poll).count()
        
        return Response({
            'poll_id': str(poll.id),
            'question': poll.question,
            'total_votes': total_votes,
            'options': option_serializer.data
        })
