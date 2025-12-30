"""
Testing settings for Smart Trip Planner.

These settings are used when running tests.
Fast, isolated, and predictable.
"""
from .base import *

# Use in-memory SQLite for fast tests
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.sqlite3',
        'NAME': ':memory:',
    }
}

# Disable migrations during tests for speed
# Uncomment if you want to test migrations
# class DisableMigrations:
#     def __contains__(self, item):
#         return True
#     def __getitem__(self, item):
#         return None
# MIGRATION_MODULES = DisableMigrations()

# Password hashing: Use faster algorithm for tests
PASSWORD_HASHERS = [
    'django.contrib.auth.hashers.MD5PasswordHasher',  # Fast but insecure - only for tests
]

# Disable logging during tests (optional, comment out if you need test logs)
LOGGING['handlers']['console']['level'] = 'CRITICAL'

# Email: Use in-memory backend for tests
EMAIL_BACKEND = 'django.core.mail.backends.locmem.EmailBackend'

# CORS: Allow all in tests
CORS_ALLOW_ALL_ORIGINS = True

# JWT: Short token lifetime for tests
SIMPLE_JWT['ACCESS_TOKEN_LIFETIME'] = timedelta(minutes=5)
SIMPLE_JWT['REFRESH_TOKEN_LIFETIME'] = timedelta(hours=1)

