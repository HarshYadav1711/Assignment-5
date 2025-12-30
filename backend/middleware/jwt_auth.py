"""
JWT Authentication Middleware (Placeholder).

This middleware can be used for additional JWT validation or logging.
Currently, JWT authentication is handled by DRF's JWTAuthentication class.

Uncomment and customize if you need middleware-level JWT processing.
"""
# from django.utils.deprecation import MiddlewareMixin
# from rest_framework_simplejwt.exceptions import InvalidToken, TokenError
# from rest_framework_simplejwt.tokens import UntypedToken
# import logging
# 
# logger = logging.getLogger(__name__)
# 
# 
# class JWTAuthMiddleware(MiddlewareMixin):
#     """
#     Custom JWT authentication middleware.
#     
#     This is a placeholder for additional JWT processing if needed.
#     DRF's JWTAuthentication handles most JWT validation automatically.
#     """
#     
#     def process_request(self, request):
#         """
#         Process request to extract and validate JWT token.
#         
#         Note: DRF's authentication classes handle this automatically.
#         This middleware is only needed for non-DRF views or custom logic.
#         """
#         # Extract token from Authorization header
#         auth_header = request.META.get('HTTP_AUTHORIZATION', '')
#         
#         if auth_header.startswith('Bearer '):
#             token = auth_header.split(' ')[1]
#             try:
#                 # Validate token (example - customize as needed)
#                 UntypedToken(token)
#                 # Additional custom validation can go here
#             except (InvalidToken, TokenError) as e:
#                 logger.warning(f"Invalid JWT token: {e}")
#                 # Don't block request - let DRF handle it
#         
#         return None

