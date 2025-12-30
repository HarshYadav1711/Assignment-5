"""
Custom exception handlers for REST API.

Provides consistent error response format across the application.
"""
from rest_framework.views import exception_handler
from rest_framework import status
from rest_framework.response import Response


def custom_exception_handler(exc, context):
    """
    Custom exception handler for DRF.
    
    Returns consistent error response format:
    {
        "error": {
            "code": "ERROR_CODE",
            "message": "Human-readable message",
            "details": {}  # Optional additional details
        }
    }
    """
    # Call REST framework's default exception handler first
    response = exception_handler(exc, context)
    
    if response is not None:
        # Customize the response data structure
        custom_response_data = {
            'error': {
                'code': response.status_code,
                'message': 'An error occurred',
                'details': {}
            }
        }
        
        # Extract error details
        if hasattr(exc, 'detail'):
            if isinstance(exc.detail, dict):
                custom_response_data['error']['details'] = exc.detail
                # Get first error message as main message
                first_key = list(exc.detail.keys())[0] if exc.detail else None
                if first_key:
                    first_error = exc.detail[first_key]
                    if isinstance(first_error, list) and first_error:
                        custom_response_data['error']['message'] = str(first_error[0])
                    else:
                        custom_response_data['error']['message'] = str(first_error)
            elif isinstance(exc.detail, list):
                custom_response_data['error']['message'] = str(exc.detail[0]) if exc.detail else 'An error occurred'
            else:
                custom_response_data['error']['message'] = str(exc.detail)
        
        response.data = custom_response_data
    
    return response

