"""
JWT Authentication Middleware for WebSocket connections.

Validates JWT tokens from WebSocket connections and attaches user to scope.
"""
from urllib.parse import parse_qs
from channels.middleware import BaseMiddleware
from channels.db import database_sync_to_async
from django.contrib.auth import get_user_model
from django.contrib.auth.models import AnonymousUser
from rest_framework_simplejwt.exceptions import InvalidToken, TokenError
from rest_framework_simplejwt.tokens import UntypedToken
from rest_framework_simplejwt.authentication import JWTAuthentication
import logging

logger = logging.getLogger(__name__)
User = get_user_model()


@database_sync_to_async
def get_user_from_token(token_string):
    """
    Get user from JWT token.
    
    Returns user object or None if token is invalid.
    """
    try:
        # Validate token
        UntypedToken(token_string)
        
        # Get user from token
        jwt_auth = JWTAuthentication()
        validated_token = jwt_auth.get_validated_token(token_string)
        user = jwt_auth.get_user(validated_token)
        
        return user
    except (InvalidToken, TokenError, Exception) as e:
        logger.warning(f"Invalid JWT token in WebSocket connection: {e}")
        return None


class JWTAuthMiddleware(BaseMiddleware):
    """
    JWT Authentication middleware for WebSocket connections.
    
    Extracts JWT token from:
    1. Query string: ?token=<jwt_token>
    2. Authorization header: Authorization: Bearer <jwt_token>
    
    Attaches authenticated user to scope['user'].
    """
    
    async def __call__(self, scope, receive, send):
        """
        Process WebSocket connection and authenticate user.
        """
        # Only process WebSocket connections
        if scope['type'] != 'websocket':
            return await super().__call__(scope, receive, send)
        
        # Extract token from query string or headers
        token = None
        
        # Try query string first (common for WebSocket clients)
        query_string = scope.get('query_string', b'').decode()
        if query_string:
            query_params = parse_qs(query_string)
            token = query_params.get('token', [None])[0]
        
        # Try Authorization header if not in query string
        if not token:
            headers = dict(scope.get('headers', []))
            auth_header = headers.get(b'authorization', b'').decode()
            if auth_header.startswith('Bearer '):
                token = auth_header.split(' ')[1]
        
        # Authenticate user
        if token:
            user = await get_user_from_token(token)
            if user:
                scope['user'] = user
            else:
                scope['user'] = AnonymousUser()
        else:
            scope['user'] = AnonymousUser()
        
        return await super().__call__(scope, receive, send)


def JWTAuthMiddlewareStack(inner):
    """
    Stack JWT auth middleware.
    
    Usage:
        application = ProtocolTypeRouter({
            "websocket": JWTAuthMiddlewareStack(
                URLRouter(websocket_urlpatterns)
            ),
        })
    """
    return JWTAuthMiddleware(inner)

