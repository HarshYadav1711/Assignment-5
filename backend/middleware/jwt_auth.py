"""
JWT Authentication Validation Middleware.

Validates JWT tokens early in the request cycle for non-DRF views.
For DRF views, authentication is handled by DRF's authentication classes.

This middleware:
- Validates JWT tokens in Authorization header
- Logs invalid tokens for security monitoring
- Does NOT block requests (DRF handles authentication)
- Minimal performance overhead (only checks header presence)
"""
import logging
from django.utils.deprecation import MiddlewareMixin
from django.conf import settings

logger = logging.getLogger(__name__)


class JWTAuthMiddleware(MiddlewareMixin):
    """
    JWT Authentication validation middleware.
    
    Position in middleware stack: After AuthenticationMiddleware
    Purpose: Early validation and logging of JWT tokens
    
    Note: This middleware does NOT authenticate users. It only validates
    token format and logs issues. DRF's JWTAuthentication handles actual
    user authentication for API views.
    """
    
    # Paths that don't need JWT validation
    EXEMPT_PATHS = [
        '/admin/',
        '/api/docs/',
        '/api/redoc/',
        '/api/schema/',
        '/health/',
        '/static/',
        '/media/',
    ]
    
    def process_request(self, request):
        """
        Validate JWT token format if present.
        
        Only validates format, not authentication. DRF handles actual auth.
        """
        # Skip validation for exempt paths
        if any(request.path.startswith(path) for path in self.EXEMPT_PATHS):
            return None
        
        # Only check API endpoints
        if not request.path.startswith('/api/'):
            return None
        
        # Extract token from Authorization header
        auth_header = request.META.get('HTTP_AUTHORIZATION', '')
        
        if auth_header.startswith('Bearer '):
            token = auth_header.split(' ', 1)[1] if ' ' in auth_header else None
            
            if token:
                # Basic format validation (JWT has 3 parts separated by dots)
                parts = token.split('.')
                if len(parts) != 3:
                    logger.warning(
                        f"Invalid JWT token format from {self._get_client_ip(request)} "
                        f"on {request.path}"
                    )
                # Full validation is done by DRF's JWTAuthentication
        
        return None
    
    def _get_client_ip(self, request):
        """Get client IP address from request."""
        x_forwarded_for = request.META.get('HTTP_X_FORWARDED_FOR')
        if x_forwarded_for:
            ip = x_forwarded_for.split(',')[0]
        else:
            ip = request.META.get('REMOTE_ADDR')
        return ip
