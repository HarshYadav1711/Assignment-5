"""
Admin configuration for Chat models.
"""
from django.contrib import admin
from .models import ChatRoom, ChatMessage


@admin.register(ChatRoom)
class ChatRoomAdmin(admin.ModelAdmin):
    list_display = ('trip', 'created_at')
    search_fields = ('trip__title',)
    raw_id_fields = ('trip',)


@admin.register(ChatMessage)
class ChatMessageAdmin(admin.ModelAdmin):
    list_display = ('sender', 'chat_room', 'content_preview', 'message_type', 'created_at')
    list_filter = ('message_type', 'is_edited', 'created_at')
    search_fields = ('content', 'sender__email')
    raw_id_fields = ('chat_room', 'sender', 'reply_to')
    
    def content_preview(self, obj):
        return obj.content[:50] + '...' if len(obj.content) > 50 else obj.content
    content_preview.short_description = 'Content'

