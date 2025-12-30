"""
WebSocket URL routing for chat.

Maps WebSocket URLs to consumers.
"""
from django.urls import re_path
from . import consumers

websocket_urlpatterns = [
    re_path(r'ws/chat/(?P<trip_id>[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})/$', 
            consumers.ChatConsumer.as_asgi()),
]

