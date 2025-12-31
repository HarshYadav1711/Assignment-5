"""
Views for Chat management.

Real-time messaging is handled via WebSocket consumers.
These REST endpoints are for message history and fallback message creation when WebSocket is unavailable.
"""
from rest_framework import viewsets, permissions
from rest_framework.decorators import action
from rest_framework.response import Response
from django.shortcuts import get_object_or_404
from .models import ChatRoom, ChatMessage
from .serializers import ChatRoomSerializer, MessageSerializer, MessageCreateSerializer


class ChatRoomViewSet(viewsets.ReadOnlyModelViewSet):
    """
    ViewSet for ChatRoom read operations.
    
    Chat rooms are created automatically when trips are created.
    """
    queryset = ChatRoom.objects.all()
    serializer_class = ChatRoomSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        """Only show chat rooms for trips user is member of."""
        from trips.models import Collaborator
        user = self.request.user
        user_trips = Collaborator.objects.filter(user=user).values_list('trip_id', flat=True)
        return ChatRoom.objects.filter(trip_id__in=user_trips)
    
    def check_object_permissions(self, request, obj):
        """Verify user is collaborator of the trip."""
        from trips.models import Collaborator
        if not Collaborator.objects.filter(trip=obj.trip, user=request.user).exists():
            from rest_framework.exceptions import PermissionDenied
            raise PermissionDenied("You must be a member of this trip to access its chat room.")
        super().check_object_permissions(request, obj)
    
    @action(detail=True, methods=['get'], url_path='messages')
    def messages(self, request, pk=None):
        """Get messages for a chat room."""
        chat_room = self.get_object()
        messages = chat_room.messages.all()[:50]  # Last 50 messages
        serializer = MessageSerializer(messages, many=True)
        return Response(serializer.data)


class MessageViewSet(viewsets.ModelViewSet):
    """
    ViewSet for ChatMessage CRUD operations.
    
    Used for message history and fallback message creation (if WebSocket fails).
    """
    queryset = ChatMessage.objects.all()
    permission_classes = [permissions.IsAuthenticated]
    
    def get_serializer_class(self):
        if self.action == 'create':
            return MessageCreateSerializer
        return MessageSerializer
    
    def get_queryset(self):
        """Filter by chat room if provided."""
        queryset = ChatMessage.objects.all()
        chat_room_id = self.request.query_params.get('chat_room_id')
        if chat_room_id:
            queryset = queryset.filter(chat_room_id=chat_room_id)
        return queryset

