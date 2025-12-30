"""
Chat models for Smart Trip Planner.

Real-time messaging for trip discussions.
"""
import uuid
from django.db import models
from django.conf import settings
from django.utils.translation import gettext_lazy as _


class ChatRoom(models.Model):
    """
    Chat room model - one room per trip.
    
    Simplifies access control (inherits from trip membership).
    """
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    trip = models.OneToOneField(
        'trips.Trip',
        on_delete=models.CASCADE,
        related_name='chat_room',
        verbose_name=_('trip')
    )
    created_at = models.DateTimeField(_('created at'), auto_now_add=True)
    
    class Meta:
        db_table = 'chat_rooms'
        verbose_name = _('chat room')
        verbose_name_plural = _('chat rooms')
    
    def __str__(self):
        return f"Chat Room: {self.trip.title}"


class Message(models.Model):
    """
    Message model for chat room.
    
    All messages are persisted for history and offline sync.
    """
    MESSAGE_TYPE_CHOICES = [
        ('text', _('Text')),
        ('system', _('System')),
        ('file', _('File')),
    ]
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    chat_room = models.ForeignKey(
        ChatRoom,
        on_delete=models.CASCADE,
        related_name='messages',
        verbose_name=_('chat room')
    )
    sender = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='messages',
        verbose_name=_('sender')
    )
    content = models.TextField(_('content'))
    message_type = models.CharField(
        _('message type'),
        max_length=20,
        choices=MESSAGE_TYPE_CHOICES,
        default='text'
    )
    reply_to = models.ForeignKey(
        'self',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='replies',
        verbose_name=_('reply to')
    )
    is_edited = models.BooleanField(_('is edited'), default=False)
    
    # Timestamps
    created_at = models.DateTimeField(_('created at'), auto_now_add=True)
    updated_at = models.DateTimeField(_('updated at'), auto_now=True)
    
    class Meta:
        db_table = 'messages'
        verbose_name = _('message')
        verbose_name_plural = _('messages')
        ordering = ['created_at']
        indexes = [
            models.Index(fields=['chat_room', 'created_at']),
            models.Index(fields=['sender']),
        ]
    
    def __str__(self):
        return f"{self.sender.email}: {self.content[:50]}"

