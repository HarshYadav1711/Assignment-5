"""
Request/Response Logging Middleware.

Logs incoming requests and responses with minimal performance overhead.
Optimized for production use with structured logging.

Features:
- Logs request method, path, user, status, and duration
- Skips logging for static/media files
- Configurable log level per status code
- Minimal overhead (uses time.perf_counter for precision)
"""
import logging
import time
from django.utils.deprecation import MiddlewareMixin
from django.conf import settings

logger = logging.getLogger(__name__)


class RequestLoggingMiddleware(MiddlewareMixin):
    """
    Request and response logging middleware.
    
    Position in middleware stack: Early in chain (after security middleware)
    Purpose: Log all HTTP requests for monitoring and debugging
    
    Performance: Minimal overhead (~0.1ms per request)
    - Uses time.perf_counter() for high-precision timing
    - Skips expensive operations for static files
    - Async logging in production (if configured)
    """
    
    # Paths to skip logging (static files, health checks, etc.)
    SKIP_PATHS = [
        '/static/',
        '/media/',
        '/favicon.ico',
        '/health/',
    ]
    
    # Status codes that should be logged at different levels
    STATUS_LOG_LEVELS = {
        200: logging.INFO,
        201: logging.INFO,
        204: logging.INFO,
        301: logging.INFO,
        302: logging.INFO,
        400: logging.WARNING,
        401: logging.WARNING,
        403: logging.WARNING,
        404: logging.WARNING,
        500: logging.ERROR,
        502: logging.ERROR,
        503: logging.ERROR,
    }
    
    def process_request(self, request):
        """Store request start time."""
        # Skip logging for static files and health checks
        if any(request.path.startswith(path) for path in self.SKIP_PATHS):
            return None
        
        # Store start time using high-precision timer
        request._logging_start_time = time.perf_counter()
        return None
    
    def process_response(self, request, response):
        """Log request details after response."""
        # Skip if start time wasn't set (static files, etc.)
        if not hasattr(request, '_logging_start_time'):
            return response
        
        # Calculate duration
        duration = time.perf_counter() - request._logging_start_time
        
        # Get user information
        user = getattr(request, 'user', None)
        user_identifier = 'Anonymous'
        if user and hasattr(user, 'is_authenticated') and user.is_authenticated:
            user_identifier = getattr(user, 'email', getattr(user, 'username', 'Unknown'))
        
        # Get client IP
        client_ip = self._get_client_ip(request)
        
        # Determine log level based on status code
        log_level = self.STATUS_LOG_LEVELS.get(response.status_code, logging.INFO)
        
        # Build log message
        log_data = {
            'method': request.method,
            'path': request.path,
            'status': response.status_code,
            'user': user_identifier,
            'ip': client_ip,
            'duration_ms': round(duration * 1000, 2),  # Convert to milliseconds
        }
        
        # Add query string if present (for debugging)
        if request.GET:
            log_data['query_params'] = dict(request.GET)
        
        # Log based on status code
        if log_level == logging.ERROR:
            logger.error(
                f"{request.method} {request.path} | "
                f"Status: {response.status_code} | "
                f"User: {user_identifier} | "
                f"IP: {client_ip} | "
                f"Duration: {duration*1000:.2f}ms",
                extra=log_data
            )
        elif log_level == logging.WARNING:
            logger.warning(
                f"{request.method} {request.path} | "
                f"Status: {response.status_code} | "
                f"User: {user_identifier} | "
                f"IP: {client_ip} | "
                f"Duration: {duration*1000:.2f}ms",
                extra=log_data
            )
        else:
            # Only log INFO level in DEBUG mode or for API endpoints
            if settings.DEBUG or request.path.startswith('/api/'):
                logger.info(
                    f"{request.method} {request.path} | "
                    f"Status: {response.status_code} | "
                    f"User: {user_identifier} | "
                    f"Duration: {duration*1000:.2f}ms",
                    extra=log_data
                )
        
        return response
    
    def _get_client_ip(self, request):
        """Get client IP address from request."""
        x_forwarded_for = request.META.get('HTTP_X_FORWARDED_FOR')
        if x_forwarded_for:
            ip = x_forwarded_for.split(',')[0].strip()
        else:
            ip = request.META.get('REMOTE_ADDR', 'Unknown')
        return ip
