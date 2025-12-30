"""
WebSocket consumers for real-time chat.

Handles WebSocket connections, message broadcasting, and room management.
"""
import json
import logging
from channels.generic.websocket import AsyncWebsocketConsumer
from channels.db import database_sync_to_async
from django.contrib.auth import get_user_model
from django.core.exceptions import ValidationError
from .models import ChatRoom, ChatMessage
from trips.models import Collaborator

logger = logging.getLogger(__name__)
User = get_user_model()


class ChatConsumer(AsyncWebsocketConsumer):
    """
    WebSocket consumer for trip chat rooms.
    
    Handles:
    - Connection/disconnection
    - Message sending and broadcasting
    - Room subscription
    - Typing indicators
    - Message editing
    """
    
    async def connect(self):
        """
        Handle WebSocket connection.
        
        Validates:
        1. User is authenticated
        2. User has access to the trip (is a collaborator)
        3. Chat room exists (creates if needed)
        """
        self.trip_id = self.scope['url_route']['kwargs']['trip_id']
        self.room_group_name = f'chat_trip_{self.trip_id}'
        self.user = self.scope['user']
        
        # Check authentication
        if self.user.is_anonymous:
            logger.warning(f"Unauthenticated WebSocket connection attempt for trip {self.trip_id}")
            await self.close(code=4001)  # Unauthorized
            return
        
        # Check trip access
        has_access = await self.check_trip_access()
        if not has_access:
            logger.warning(f"User {self.user.email} attempted to access trip {self.trip_id} without permission")
            await self.close(code=4003)  # Forbidden
            return
        
        # Ensure chat room exists
        await self.ensure_chat_room()
        
        # Join room group
        await self.channel_layer.group_add(
            self.room_group_name,
            self.channel_name
        )
        
        # Accept connection
        await self.accept()
        
        logger.info(f"User {self.user.email} connected to chat room for trip {self.trip_id}")
        
        # Send recent message history
        await self.send_recent_messages()
    
    async def disconnect(self, close_code):
        """
        Handle WebSocket disconnection.
        
        Removes user from room group and logs disconnection.
        """
        # Leave room group
        await self.channel_layer.group_discard(
            self.room_group_name,
            self.channel_name
        )
        
        logger.info(f"User {self.user.email} disconnected from chat room for trip {self.trip_id}")
    
    async def receive(self, text_data):
        """
        Handle incoming WebSocket messages.
        
        Message types:
        - chat_message: Send a new message
        - edit_message: Edit an existing message
        - typing: Typing indicator
        """
        try:
            data = json.loads(text_data)
            message_type = data.get('type')
            
            if message_type == 'chat_message':
                await self.handle_chat_message(data)
            elif message_type == 'edit_message':
                await self.handle_edit_message(data)
            elif message_type == 'typing':
                await self.handle_typing(data)
            else:
                await self.send_error('Unknown message type')
        
        except json.JSONDecodeError:
            await self.send_error('Invalid JSON format')
        except Exception as e:
            logger.error(f"Error processing WebSocket message: {e}", exc_info=True)
            await self.send_error('An error occurred processing your message')
    
    async def handle_chat_message(self, data):
        """
        Handle new chat message.
        
        Validates message, saves to database, and broadcasts to room.
        """
        content = data.get('content', '').strip()
        reply_to_id = data.get('reply_to')
        message_type = data.get('message_type', 'text')
        
        # Validate content
        if not content:
            await self.send_error('Message content cannot be empty')
            return
        
        if len(content) > 10000:  # Reasonable limit
            await self.send_error('Message is too long (max 10000 characters)')
            return
        
        # Save message to database
        message = await self.save_message(content, reply_to_id, message_type)
        
        if not message:
            await self.send_error('Failed to save message')
            return
        
        # Broadcast to room group
        await self.channel_layer.group_send(
            self.room_group_name,
            {
                'type': 'chat_message',
                'message': await self.serialize_message(message)
            }
        )
    
    async def handle_edit_message(self, data):
        """
        Handle message edit.
        
        Validates ownership, updates message, and broadcasts update.
        """
        message_id = data.get('message_id')
        new_content = data.get('content', '').strip()
        
        if not message_id:
            await self.send_error('message_id is required')
            return
        
        if not new_content:
            await self.send_error('Message content cannot be empty')
            return
        
        # Update message
        message = await self.update_message(message_id, new_content)
        
        if not message:
            await self.send_error('Message not found or you do not have permission to edit it')
            return
        
        # Broadcast update to room group
        await self.channel_layer.group_send(
            self.room_group_name,
            {
                'type': 'message_edited',
                'message': await self.serialize_message(message)
            }
        )
    
    async def handle_typing(self, data):
        """
        Handle typing indicator.
        
        Broadcasts typing status to other users in the room.
        """
        is_typing = data.get('is_typing', False)
        
        # Broadcast typing indicator to others (not sender)
        await self.channel_layer.group_send(
            self.room_group_name,
            {
                'type': 'typing_indicator',
                'user_id': str(self.user.id),
                'user_email': self.user.email,
                'is_typing': is_typing
            }
        )
    
    # WebSocket message handlers (called by channel layer)
    
    async def chat_message(self, event):
        """
        Send chat message to WebSocket.
        """
        await self.send(text_data=json.dumps({
            'type': 'chat_message',
            'message': event['message']
        }))
    
    async def message_edited(self, event):
        """
        Send message edit notification to WebSocket.
        """
        await self.send(text_data=json.dumps({
            'type': 'message_edited',
            'message': event['message']
        }))
    
    async def typing_indicator(self, event):
        """
        Send typing indicator to WebSocket.
        """
        # Don't send typing indicator to the user who is typing
        if event['user_id'] != str(self.user.id):
            await self.send(text_data=json.dumps({
                'type': 'typing',
                'user_id': event['user_id'],
                'user_email': event['user_email'],
                'is_typing': event['is_typing']
            }))
    
    # Helper methods
    
    @database_sync_to_async
    def check_trip_access(self):
        """Check if user is a collaborator of the trip."""
        try:
            return Collaborator.objects.filter(
                trip_id=self.trip_id,
                user=self.user
            ).exists()
        except Exception as e:
            logger.error(f"Error checking trip access: {e}")
            return False
    
    @database_sync_to_async
    def ensure_chat_room(self):
        """Ensure chat room exists for the trip."""
        try:
            from trips.models import Trip
            trip = Trip.objects.get(id=self.trip_id)
            ChatRoom.objects.get_or_create(trip=trip)
        except Trip.DoesNotExist:
            logger.error(f"Trip {self.trip_id} does not exist")
        except Exception as e:
            logger.error(f"Error ensuring chat room: {e}")
    
    @database_sync_to_async
    def save_message(self, content, reply_to_id=None, message_type='text'):
        """Save message to database."""
        try:
            chat_room = ChatRoom.objects.get(trip_id=self.trip_id)
            
            reply_to = None
            if reply_to_id:
                try:
                    reply_to = ChatMessage.objects.get(id=reply_to_id, chat_room=chat_room)
                except ChatMessage.DoesNotExist:
                    logger.warning(f"Reply target message {reply_to_id} not found")
            
            message = ChatMessage.objects.create(
                chat_room=chat_room,
                sender=self.user,
                content=content,
                message_type=message_type,
                reply_to=reply_to
            )
            
            return message
        except ValidationError as e:
            logger.error(f"Validation error saving message: {e}")
            return None
        except Exception as e:
            logger.error(f"Error saving message: {e}", exc_info=True)
            return None
    
    @database_sync_to_async
    def update_message(self, message_id, new_content):
        """Update message if user is the sender."""
        try:
            message = ChatMessage.objects.get(
                id=message_id,
                chat_room__trip_id=self.trip_id,
                sender=self.user
            )
            
            message.content = new_content
            message.save()
            
            return message
        except ChatMessage.DoesNotExist:
            return None
        except Exception as e:
            logger.error(f"Error updating message: {e}")
            return None
    
    @database_sync_to_async
    def get_recent_messages(self, limit=50):
        """Get recent messages for the chat room."""
        try:
            chat_room = ChatRoom.objects.get(trip_id=self.trip_id)
            messages = chat_room.messages.select_related(
                'sender', 'reply_to', 'reply_to__sender'
            ).order_by('-created_at')[:limit]
            
            # Reverse to get chronological order
            return list(reversed(messages))
        except Exception as e:
            logger.error(f"Error getting recent messages: {e}")
            return []
    
    async def send_recent_messages(self):
        """Send recent message history to newly connected user."""
        messages = await self.get_recent_messages()
        
        serialized_messages = []
        for message in messages:
            serialized_messages.append(await self.serialize_message(message))
        
        await self.send(text_data=json.dumps({
            'type': 'message_history',
            'messages': serialized_messages
        }))
    
    @database_sync_to_async
    def serialize_message(self, message):
        """Serialize message for JSON transmission."""
        return {
            'id': str(message.id),
            'chat_room_id': str(message.chat_room.id),
            'sender': {
                'id': str(message.sender.id),
                'email': message.sender.email,
                'username': message.sender.username or message.sender.email,
                'full_name': message.sender.get_full_name()
            },
            'content': message.content,
            'message_type': message.message_type,
            'reply_to': {
                'id': str(message.reply_to.id),
                'content': message.reply_to.content[:100],
                'sender_email': message.reply_to.sender.email
            } if message.reply_to else None,
            'is_edited': message.is_edited,
            'created_at': message.created_at.isoformat(),
            'updated_at': message.updated_at.isoformat()
        }
    
    async def send_error(self, error_message):
        """Send error message to client."""
        await self.send(text_data=json.dumps({
            'type': 'error',
            'message': error_message
        }))

