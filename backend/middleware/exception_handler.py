"""
Global Exception Handling Middleware.

Catches unhandled exceptions and returns consistent error responses.
Complements DRF's exception handler for non-DRF views.

Features:
- Catches all unhandled exceptions
- Returns consistent JSON error format
- Logs exceptions for debugging
- Minimal performance overhead (only on exceptions)
"""
import logging
import traceback
from django.utils.deprecation import MiddlewareMixin
from django.http import JsonResponse
from django.core.exceptions import PermissionDenied, ValidationError
from django.db import DatabaseError
from django.conf import settings

logger = logging.getLogger(__name__)


class GlobalExceptionHandlerMiddleware(MiddlewareMixin):
    """
    Global exception handling middleware.
    
    Position in middleware stack: Last in chain (outermost)
    Purpose: Catch unhandled exceptions and return consistent errors
    
    Note: DRF views use DRF's exception handler. This middleware handles:
    - Non-DRF views (admin, health checks, etc.)
    - Exceptions that escape DRF's handler
    - Database errors
    - Permission errors
    """
    
    # Exceptions that should return 400 Bad Request
    CLIENT_ERROR_EXCEPTIONS = (
        ValueError,
        TypeError,
        ValidationError,
        PermissionDenied,
    )
    
    # Exceptions that should return 500 Internal Server Error
    SERVER_ERROR_EXCEPTIONS = (
        DatabaseError,
        Exception,  # Catch-all for unexpected errors
    )
    
    def process_exception(self, request, exception):
        """
        Handle unhandled exceptions.
        
        Returns JsonResponse with error details, or None to let Django handle it.
        """
        # Don't handle exceptions for exempt paths (let Django handle them)
        exempt_paths = ['/admin/', '/static/', '/media/']
        if any(request.path.startswith(path) for path in exempt_paths):
            return None
        
        # Log the exception
        logger.error(
            f"Unhandled exception: {type(exception).__name__}: {str(exception)}",
            exc_info=True,
            extra={
                'path': request.path,
                'method': request.method,
                'user': getattr(request.user, 'email', 'Anonymous') if hasattr(request, 'user') else 'Unknown',
            }
        )
        
        # Determine status code and error message
        if isinstance(exception, self.CLIENT_ERROR_EXCEPTIONS):
            status_code = 400
            error_message = str(exception) or 'Bad request'
        elif isinstance(exception, PermissionDenied):
            status_code = 403
            error_message = 'Permission denied'
        elif isinstance(exception, DatabaseError):
            status_code = 500
            error_message = 'Database error occurred'
        else:
            status_code = 500
            error_message = 'An unexpected error occurred'
        
        # Build error response
        error_response = {
            'error': {
                'code': status_code,
                'message': error_message,
                'details': {}
            }
        }
        
        # Add detailed error information in DEBUG mode
        if settings.DEBUG:
            error_response['error']['details'] = {
                'exception_type': type(exception).__name__,
                'exception_message': str(exception),
                'traceback': traceback.format_exc().split('\n') if settings.DEBUG else None,
            }
        
        return JsonResponse(error_response, status=status_code)

