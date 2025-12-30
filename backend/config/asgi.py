"""
ASGI config for Smart Trip Planner project.

It exposes the ASGI callable as a module-level variable named ``application``.

Supports both HTTP and WebSocket connections.
"""
import os

from django.core.asgi import get_asgi_application

# Set default settings module before importing Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings.development')

# Initialize Django ASGI application early to ensure the AppRegistry
# is populated before importing code that may import ORM models.
django_asgi_app = get_asgi_application()

# Import Channels components after Django is initialized
from channels.routing import ProtocolTypeRouter, URLRouter
from channels.security.websocket import AllowedHostsOriginValidator
from chat.routing import websocket_urlpatterns
from chat.middleware import JWTAuthMiddlewareStack

# ASGI application that handles both HTTP and WebSocket protocols
application = ProtocolTypeRouter({
    # HTTP requests go to Django
    "http": django_asgi_app,
    
    # WebSocket connections go through JWT auth middleware and routing
    "websocket": AllowedHostsOriginValidator(
        JWTAuthMiddlewareStack(
            URLRouter(websocket_urlpatterns)
        )
    ),
})

