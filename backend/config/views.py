"""
Root-level views (health check, etc.).
"""
from django.http import JsonResponse
from django.views.decorators.http import require_http_methods
from django.db import connection


@require_http_methods(["GET"])
def health_check(request):
    """
    Health check endpoint for monitoring and load balancers.
    
    Returns 200 if service is healthy, 503 if unhealthy.
    """
    try:
        # Check database connection
        with connection.cursor() as cursor:
            cursor.execute("SELECT 1")
        
        return JsonResponse({
            'status': 'healthy',
            'service': 'smart-trip-planner-api'
        }, status=200)
    except Exception as e:
        return JsonResponse({
            'status': 'unhealthy',
            'error': str(e)
        }, status=503)

