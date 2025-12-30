"""
Views for Poll management.
"""
from rest_framework import viewsets, status, permissions
from rest_framework.decorators import action
from rest_framework.response import Response
from django.shortcuts import get_object_or_404
from .models import Poll, PollOption, PollVote
from .serializers import (
    PollSerializer,
    PollCreateSerializer,
    PollOptionSerializer,
    PollVoteSerializer
)
from trips.permissions import IsTripMember


class PollViewSet(viewsets.ModelViewSet):
    """
    ViewSet for Poll CRUD operations.
    
    Only trip members can access polls.
    """
    queryset = Poll.objects.all()
    permission_classes = [permissions.IsAuthenticated]
    
    def get_serializer_class(self):
        if self.action == 'create':
            return PollCreateSerializer
        return PollSerializer
    
    def get_queryset(self):
        """Filter by trip if provided, and only show trips user is member of."""
        from trips.models import TripMember
        user = self.request.user
        user_trips = TripMember.objects.filter(user=user).values_list('trip_id', flat=True)
        queryset = Poll.objects.filter(trip_id__in=user_trips)
        trip_id = self.request.query_params.get('trip_id')
        if trip_id:
            queryset = queryset.filter(trip_id=trip_id)
        return queryset
    
    def check_object_permissions(self, request, obj):
        """Verify user is member of the trip."""
        from trips.models import TripMember
        if not TripMember.objects.filter(trip=obj.trip, user=request.user).exists():
            from rest_framework.exceptions import PermissionDenied
            raise PermissionDenied("You must be a member of this trip to access its polls.")
        super().check_object_permissions(request, obj)
    
    @action(detail=True, methods=['post', 'delete'], url_path='vote')
    def vote(self, request, pk=None):
        """Vote for a poll option or remove vote."""
        poll = self.get_object()
        
        if request.method == 'POST':
            option_id = request.data.get('option_id')
            if not option_id:
                return Response(
                    {'detail': 'option_id is required.'},
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            option = get_object_or_404(PollOption, id=option_id, poll=poll)
            
            # Check if user already voted for this option
            vote, created = PollVote.objects.get_or_create(
                poll=poll,
                option=option,
                user=request.user
            )
            
            if not created:
                return Response(
                    {'detail': 'You have already voted for this option.'},
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            serializer = PollVoteSerializer(vote)
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        
        elif request.method == 'DELETE':
            option_id = request.data.get('option_id')
            if not option_id:
                return Response(
                    {'detail': 'option_id is required.'},
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            vote = get_object_or_404(
                PollVote,
                poll=poll,
                option_id=option_id,
                user=request.user
            )
            vote.delete()
            return Response(status=status.HTTP_204_NO_CONTENT)

