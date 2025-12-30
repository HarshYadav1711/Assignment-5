"""
Serializers for Chat models.
"""
from rest_framework import serializers
from .models import ChatRoom, Message
from users.serializers import UserSerializer


class MessageSerializer(serializers.ModelSerializer):
    """Serializer for Message model."""
    sender = UserSerializer(read_only=True)
    reply_to = serializers.SerializerMethodField()
    
    class Meta:
        model = Message
        fields = [
            'id', 'chat_room', 'sender', 'content', 'message_type',
            'reply_to', 'is_edited', 'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'sender', 'created_at', 'updated_at']
    
    def get_reply_to(self, obj):
        """Return reply_to message if exists."""
        if obj.reply_to:
            return {
                'id': str(obj.reply_to.id),
                'content': obj.reply_to.content[:100],
                'sender': obj.reply_to.sender.email
            }
        return None


class ChatRoomSerializer(serializers.ModelSerializer):
    """Serializer for ChatRoom model."""
    trip_title = serializers.CharField(source='trip.title', read_only=True)
    message_count = serializers.SerializerMethodField()
    last_message = serializers.SerializerMethodField()
    
    class Meta:
        model = ChatRoom
        fields = ['id', 'trip', 'trip_title', 'message_count', 'last_message', 'created_at']
        read_only_fields = ['id', 'created_at']
    
    def get_message_count(self, obj):
        """Return number of messages."""
        return obj.messages.count()
    
    def get_last_message(self, obj):
        """Return last message if exists."""
        last_msg = obj.messages.last()
        if last_msg:
            return MessageSerializer(last_msg).data
        return None


class MessageCreateSerializer(serializers.ModelSerializer):
    """Serializer for creating a message."""
    
    class Meta:
        model = Message
        fields = ['chat_room', 'content', 'message_type', 'reply_to']
    
    def create(self, validated_data):
        """Create message with current user as sender."""
        return Message.objects.create(
            sender=self.context['request'].user,
            **validated_data
        )

