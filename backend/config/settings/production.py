"""
Production settings for Smart Trip Planner.

These settings are used in production deployment.
Strict security and performance optimizations.
"""
import os
from .base import *

# SECURITY WARNING: don't run with debug turned on in production!
DEBUG = False

# Allowed hosts: Set via environment variable
ALLOWED_HOSTS = os.environ.get('ALLOWED_HOSTS', '').split(',')

# Security settings for production
SECURE_SSL_REDIRECT = os.environ.get('SECURE_SSL_REDIRECT', 'True').lower() == 'true'
SECURE_HSTS_SECONDS = 31536000  # 1 year
SECURE_HSTS_INCLUDE_SUBDOMAINS = True
SECURE_HSTS_PRELOAD = True
SECURE_PROXY_SSL_HEADER = ('HTTP_X_FORWARDED_PROTO', 'https')
SESSION_COOKIE_SECURE = True
CSRF_COOKIE_SECURE = True

# CORS: Strict configuration for production
CORS_ALLOWED_ORIGINS = os.environ.get('CORS_ALLOWED_ORIGINS', '').split(',')
CORS_ALLOW_CREDENTIALS = True
CORS_ALLOW_ALL_ORIGINS = False  # Never allow all in production

# Database: Must use PostgreSQL in production
# Use DATABASE_URL if provided, otherwise use individual variables
if 'DATABASE_URL' in os.environ:
    try:
        import dj_database_url
        DATABASES['default'] = dj_database_url.config(
            conn_max_age=600,
            conn_health_checks=True,
        )
    except ImportError:
        # Fallback to manual parsing if dj-database-url not installed
        import urllib.parse
        db_url = urllib.parse.urlparse(os.environ['DATABASE_URL'])
        DATABASES['default'].update({
            'NAME': db_url.path[1:],  # Remove leading '/'
            'USER': db_url.username,
            'PASSWORD': db_url.password,
            'HOST': db_url.hostname,
            'PORT': db_url.port or '5432',
            'CONN_MAX_AGE': 600,
        })
else:
    # Individual database variables
    DATABASES['default'].update({
        'NAME': os.environ.get('DB_NAME', ''),
        'USER': os.environ.get('DB_USER', ''),
        'PASSWORD': os.environ.get('DB_PASSWORD', ''),
        'HOST': os.environ.get('DB_HOST', ''),
        'PORT': os.environ.get('DB_PORT', '5432'),
        'OPTIONS': {
            'sslmode': os.environ.get('DB_SSLMODE', 'require'),
        },
        'CONN_MAX_AGE': 600,  # Persistent connections (10 minutes)
    })

# Static files: Use WhiteNoise or CDN in production
# STATICFILES_STORAGE = 'whitenoise.storage.CompressedManifestStaticFilesStorage'

# Media files: Use cloud storage (S3, etc.) in production
# DEFAULT_FILE_STORAGE = 'storages.backends.s3boto3.S3Boto3Storage'
# AWS_STORAGE_BUCKET_NAME = os.environ.get('AWS_STORAGE_BUCKET_NAME')

# Email backend: Use SMTP or service (SendGrid, SES, etc.)
EMAIL_BACKEND = 'django.core.mail.backends.smtp.EmailBackend'
EMAIL_HOST = os.environ.get('EMAIL_HOST', 'smtp.gmail.com')
EMAIL_PORT = int(os.environ.get('EMAIL_PORT', '587'))
EMAIL_USE_TLS = True
EMAIL_HOST_USER = os.environ.get('EMAIL_HOST_USER', '')
EMAIL_HOST_PASSWORD = os.environ.get('EMAIL_HOST_PASSWORD', '')
DEFAULT_FROM_EMAIL = os.environ.get('DEFAULT_FROM_EMAIL', 'noreply@trip-planner.com')

# Logging: JSON formatter for production log aggregation
LOGGING['handlers']['console']['formatter'] = 'json'
LOGGING['handlers']['file']['formatter'] = 'json'
LOGGING['root']['level'] = 'INFO'
LOGGING['loggers']['django']['level'] = 'WARNING'  # Reduce Django noise

# JWT: Shorter token lifetime in production for security
SIMPLE_JWT['ACCESS_TOKEN_LIFETIME'] = timedelta(minutes=15)
SIMPLE_JWT['REFRESH_TOKEN_LIFETIME'] = timedelta(days=7)

# Cache: Use Redis in production
CACHES = {
    'default': {
        'BACKEND': 'django.core.cache.backends.redis.RedisCache',
        'LOCATION': os.environ.get('REDIS_URL', 'redis://127.0.0.1:6379/1'),
    }
}

# Session: Use cache-backed sessions in production
SESSION_ENGINE = 'django.contrib.sessions.backends.cache'
SESSION_CACHE_ALIAS = 'default'

