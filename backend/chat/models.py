"""
Chat models for Smart Trip Planner.

Optimized for read-heavy workloads with proper indexing for message history.
"""
import uuid
from django.db import models
from django.conf import settings
from django.utils.translation import gettext_lazy as _
from django.core.exceptions import ValidationError


class ChatRoom(models.Model):
    """
    Chat room model - one room per trip.
    
    Simplifies access control (inherits from trip membership).
    
    Optimizations:
    - OneToOne with Trip for fast lookup
    - Indexed on trip for reverse lookups
    """
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    
    # CASCADE: if trip deleted, chat room deleted
    trip = models.OneToOneField(
        'trips.Trip',
        on_delete=models.CASCADE,
        related_name='chat_room',
        verbose_name=_('trip'),
        db_index=True
    )
    
    created_at = models.DateTimeField(_('created at'), auto_now_add=True)
    
    class Meta:
        db_table = 'chat_rooms'
        verbose_name = _('chat room')
        verbose_name_plural = _('chat rooms')
    
    def __str__(self):
        return f"Chat Room: {self.trip.title}"


class ChatMessage(models.Model):
    """
    Chat message model (renamed from Message for clarity).
    
    All messages are persisted for history and offline sync.
    
    Optimizations:
    - Indexed on chat_room + created_at for chronological retrieval (most common)
    - Indexed on sender for user message queries
    - Indexed on reply_to for thread navigation
    - Indexed on created_at for pagination
    - Partial index on is_edited for edited messages
    """
    MESSAGE_TYPE_CHOICES = [
        ('text', _('Text')),
        ('system', _('System')),
        ('file', _('File')),
    ]
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    
    # CASCADE: if chat room deleted, all messages deleted
    chat_room = models.ForeignKey(
        ChatRoom,
        on_delete=models.CASCADE,
        related_name='messages',
        verbose_name=_('chat room'),
        db_index=True
    )
    
    # CASCADE: if sender deleted, messages kept but sender reference removed
    # Note: Consider SET_NULL if you want to keep messages with "Deleted User"
    sender = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,  # Messages deleted if user deleted
        related_name='chat_messages',  # Changed from 'messages' for clarity
        verbose_name=_('sender'),
        db_index=True
    )
    
    content = models.TextField(_('content'))
    
    message_type = models.CharField(
        _('message type'),
        max_length=20,
        choices=MESSAGE_TYPE_CHOICES,
        default='text'
    )
    
    # SET_NULL: if replied message deleted, keep reply but null reference
    reply_to = models.ForeignKey(
        'self',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='replies',
        verbose_name=_('reply to'),
        db_index=True
    )
    
    is_edited = models.BooleanField(_('is edited'), default=False, db_index=True)
    
    # Timestamps
    created_at = models.DateTimeField(_('created at'), auto_now_add=True, db_index=True)
    updated_at = models.DateTimeField(_('updated at'), auto_now=True)
    
    class Meta:
        db_table = 'chat_messages'  # Changed from 'messages' for clarity
        verbose_name = _('chat message')
        verbose_name_plural = _('chat messages')
        ordering = ['created_at']
        
        # Optimized indexes for read-heavy workloads
        indexes = [
            # Most common: get messages for room, ordered by creation (pagination)
            models.Index(fields=['chat_room', 'created_at'], name='message_room_created_idx'),
            
            # Reverse chronological (newest first) - common for chat UIs
            models.Index(fields=['chat_room', '-created_at'], name='message_room_created_desc_idx'),
            
            # User's messages across all rooms
            models.Index(fields=['sender', '-created_at'], name='message_sender_created_idx'),
            
            # Thread navigation: get replies to a message
            models.Index(fields=['reply_to'], name='message_reply_to_idx'),
            
            # Edited messages (for showing edit indicators)
            models.Index(
                fields=['chat_room', 'is_edited', '-updated_at'],
                name='message_room_edited_idx',
                condition=models.Q(is_edited=True)
            ),
            
            # Recent messages (for "last message" queries)
            models.Index(fields=['chat_room', '-created_at'], name='message_room_recent_idx'),
        ]
    
    def clean(self):
        """Model-level validation."""
        super().clean()
        if not self.content.strip():
            raise ValidationError({
                'content': 'Message content cannot be empty.'
            })
        
        # Ensure reply_to belongs to same chat room
        if self.reply_to and self.reply_to.chat_room != self.chat_room:
            raise ValidationError({
                'reply_to': 'Reply must be to a message in the same chat room.'
            })
    
    def save(self, *args, **kwargs):
        """Override save to run validation and set is_edited flag."""
        # Set is_edited if this is an update (not creation)
        if self.pk:
            self.is_edited = True
        
        self.full_clean()
        super().save(*args, **kwargs)
    
    def __str__(self):
        return f"{self.sender.email}: {self.content[:50]}"
