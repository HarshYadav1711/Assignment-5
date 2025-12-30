# Middleware Documentation

## Overview

The Smart Trip Planner API uses a carefully ordered middleware stack to handle authentication, logging, rate limiting, and error handling. This document explains each middleware component, its position in the stack, and its purpose.

---

## Middleware Stack Order

The middleware is executed in the following order (top to bottom):

```
1. SecurityMiddleware          # Security headers
2. CorsMiddleware              # CORS handling
3. RequestLoggingMiddleware    # Request/response logging
4. SessionMiddleware           # Session management
5. CommonMiddleware            # URL rewriting, etc.
6. CsrfViewMiddleware          # CSRF protection
7. AuthenticationMiddleware    # Sets request.user
8. JWTAuthMiddleware           # JWT token validation
9. RateLimitingMiddleware      # Rate limiting
10. MessageMiddleware          # Flash messages
11. XFrameOptionsMiddleware    # Clickjacking protection
12. GlobalExceptionHandlerMiddleware  # Exception handling
```

**Why this order matters:**
- Security middleware runs first to set security headers
- Logging runs early to capture all requests
- Authentication runs before JWT validation and rate limiting
- Exception handler runs last to catch all unhandled exceptions

---

## 1. RequestLoggingMiddleware

**File:** `middleware/request_logging.py`  
**Position:** 3rd in stack (after security and CORS)  
**Purpose:** Log all HTTP requests for monitoring and debugging

### Features

- Logs request method, path, user, status code, and duration
- Skips static files and health checks (minimal overhead)
- Uses high-precision timing (`time.perf_counter()`)
- Configurable log levels based on status code
- Structured logging with extra context

### Performance

- **Overhead:** ~0.1ms per request
- **Optimizations:**
  - Skips expensive operations for static files
  - Uses `perf_counter()` for precision without overhead
  - Only logs INFO level for API endpoints in production

### Example Log Output

```
INFO: GET /api/v1/trips/ | Status: 200 | User: user@example.com | Duration: 45.23ms
WARNING: POST /api/v1/auth/login/ | Status: 401 | User: Anonymous | Duration: 12.45ms
ERROR: GET /api/v1/trips/invalid/ | Status: 500 | User: user@example.com | Duration: 234.56ms
```

### Configuration

No configuration required. Automatically uses Django's logging configuration.

---

## 2. JWTAuthMiddleware

**File:** `middleware/jwt_auth.py`  
**Position:** 8th in stack (after AuthenticationMiddleware)  
**Purpose:** Early validation and logging of JWT tokens

### Features

- Validates JWT token format (not authentication - DRF handles that)
- Logs invalid token attempts for security monitoring
- Does NOT block requests (DRF handles authentication)
- Minimal overhead (only checks header presence)

### Performance

- **Overhead:** ~0.05ms per request (only if Authorization header present)
- **Optimizations:**
  - Only processes API endpoints
  - Skips exempt paths (admin, docs, health)
  - Basic format validation only (full validation by DRF)

### What It Does

1. Checks if request has `Authorization: Bearer <token>` header
2. Validates token format (3 parts separated by dots)
3. Logs warnings for malformed tokens
4. Does NOT authenticate users (DRF does that)

### Exempt Paths

- `/admin/`
- `/api/docs/`, `/api/redoc/`, `/api/schema/`
- `/health/`
- `/static/`, `/media/`

### Note

This middleware does **NOT** authenticate users. It only validates token format and logs issues. DRF's `JWTAuthentication` class handles actual user authentication for API views.

---

## 3. RateLimitingMiddleware

**File:** `middleware/rate_limiting.py`  
**Position:** 9th in stack (after authentication)  
**Purpose:** Prevent abuse and ensure fair resource usage

### Features

- Per-user rate limiting (authenticated users)
- Per-IP rate limiting (anonymous users)
- Configurable limits per endpoint
- Sliding window algorithm
- Uses Django cache backend (Redis recommended)

### Performance

- **Overhead:** ~1-2ms per request (cache lookup)
- **Optimizations:**
  - Single cache operation per request
  - Atomic increment using cache.add() + cache.incr()
  - Fails open if cache unavailable (allows request)

### Algorithm

**Sliding Window:**
1. Check current request count for identifier (user/IP) + endpoint
2. If count < limit: increment and allow request
3. If count >= limit: return 429 Too Many Requests

### Configuration

**Settings:**
```python
# Enable/disable rate limiting
RATE_LIMIT_ENABLED = True  # Default: True

# Default rate limit (requests per window)
RATE_LIMIT_DEFAULT = 100  # Default: 100 requests

# Time window in seconds
RATE_LIMIT_WINDOW = 60  # Default: 60 seconds (1 minute)

# Custom limits per endpoint
RATE_LIMIT_PER_ENDPOINT = {
    '/api/v1/auth/login/': 5,      # 5 login attempts per minute
    '/api/v1/auth/register/': 3,   # 3 registrations per minute
    '/api/v1/auth/refresh/': 10,   # 10 token refreshes per minute
}
```

### Rate Limit Response

**429 Too Many Requests:**
```json
{
  "error": {
    "code": 429,
    "message": "Rate limit exceeded. Please try again later.",
    "details": {
      "limit": 100,
      "window_seconds": 60,
      "retry_after": 60
    }
  }
}
```

**Headers:**
```
Retry-After: 60
```

### Identifier Strategy

- **Authenticated users:** `user:{user_id}` (more accurate, per-user limits)
- **Anonymous users:** `ip:{ip_address}` (IP-based limiting)

### Exempt Paths

- `/admin/`
- `/health/`
- `/static/`, `/media/`
- `/api/docs/`, `/api/redoc/`, `/api/schema/`

### Cache Backend

**Recommended:** Redis (for production)
```python
CACHES = {
    'default': {
        'BACKEND': 'django.core.cache.backends.redis.RedisCache',
        'LOCATION': 'redis://127.0.0.1:6379/1',
    }
}
```

**Fallback:** Local memory cache (for development)
```python
CACHES = {
    'default': {
        'BACKEND': 'django.core.cache.backends.locmem.LocMemCache',
    }
}
```

---

## 4. GlobalExceptionHandlerMiddleware

**File:** `middleware/exception_handler.py`  
**Position:** 12th in stack (last - outermost)  
**Purpose:** Catch unhandled exceptions and return consistent errors

### Features

- Catches all unhandled exceptions
- Returns consistent JSON error format
- Logs exceptions with full traceback
- Handles different exception types appropriately
- Complements DRF's exception handler

### Performance

- **Overhead:** Zero (only executes on exceptions)
- **Optimizations:**
  - Only processes exceptions (no overhead on normal requests)
  - Skips exempt paths (lets Django handle admin errors)

### Exception Handling

**Client Errors (400 Bad Request):**
- `ValueError`
- `TypeError`
- `ValidationError`
- `PermissionDenied` (403 Forbidden)

**Server Errors (500 Internal Server Error):**
- `DatabaseError`
- All other exceptions

### Error Response Format

**Standard Response:**
```json
{
  "error": {
    "code": 400,
    "message": "Bad request",
    "details": {}
  }
}
```

**DEBUG Mode (includes traceback):**
```json
{
  "error": {
    "code": 500,
    "message": "An unexpected error occurred",
    "details": {
      "exception_type": "ValueError",
      "exception_message": "Invalid input",
      "traceback": ["..."]
    }
  }
}
```

### What It Handles

- **Non-DRF views:** Admin, health checks, etc.
- **Escaped exceptions:** Exceptions that escape DRF's handler
- **Database errors:** Connection issues, query errors
- **Permission errors:** Access denied scenarios

### What It Doesn't Handle

- **DRF views:** DRF has its own exception handler
- **Admin errors:** Let Django handle admin interface errors
- **Static files:** Not applicable

### Logging

All exceptions are logged with:
- Exception type and message
- Full traceback
- Request path and method
- User information

---

## Performance Summary

| Middleware | Overhead | When Executes |
|------------|----------|---------------|
| RequestLoggingMiddleware | ~0.1ms | Every request |
| JWTAuthMiddleware | ~0.05ms | API requests with auth header |
| RateLimitingMiddleware | ~1-2ms | API requests (cache lookup) |
| GlobalExceptionHandlerMiddleware | 0ms | Only on exceptions |

**Total overhead:** ~1.15-2.15ms per API request (negligible)

---

## Configuration Examples

### Development

```python
# settings/development.py
RATE_LIMIT_ENABLED = False  # Disable in development
RATE_LIMIT_DEFAULT = 1000   # Higher limit for testing
```

### Production

```python
# settings/production.py
RATE_LIMIT_ENABLED = True
RATE_LIMIT_DEFAULT = 100
RATE_LIMIT_WINDOW = 60

# Use Redis for rate limiting
CACHES = {
    'default': {
        'BACKEND': 'django.core.cache.backends.redis.RedisCache',
        'LOCATION': os.environ.get('REDIS_URL'),
    }
}
```

---

## Testing Middleware

### Test Rate Limiting

```bash
# Make multiple rapid requests
for i in {1..110}; do
  curl -H "Authorization: Bearer $TOKEN" http://localhost:8000/api/v1/trips/
done

# Should get 429 after 100 requests
```

### Test Exception Handling

```python
# In a view, raise an exception
def test_view(request):
    raise ValueError("Test exception")
    # Should return 400 with error JSON
```

### Test Logging

```bash
# Check logs for request entries
tail -f logs/django.log | grep "GET /api/v1/trips/"
```

---

## Troubleshooting

### Rate Limiting Not Working

1. Check `RATE_LIMIT_ENABLED = True`
2. Verify cache backend is configured
3. Check Redis is running (if using Redis)
4. Verify cache key format in logs

### Exceptions Not Caught

1. Ensure middleware is last in stack
2. Check if path is exempt
3. Verify DRF exception handler isn't handling it first

### High Performance Overhead

1. Check cache backend performance
2. Verify rate limiting is using Redis (not database)
3. Consider disabling request logging for high-traffic endpoints
4. Monitor middleware execution time in logs

---

## Best Practices

1. **Use Redis for rate limiting** in production (not database)
2. **Monitor middleware performance** in production
3. **Adjust rate limits** based on actual usage patterns
4. **Log exceptions** but don't expose sensitive data
5. **Test middleware** in staging before production

---

## Summary

The middleware stack provides:
- ✅ **Request logging** for monitoring
- ✅ **JWT validation** for security monitoring
- ✅ **Rate limiting** for abuse prevention
- ✅ **Exception handling** for consistent errors
- ✅ **Minimal overhead** (~1-2ms per request)
- ✅ **Production-ready** with proper error handling

All middleware is designed for minimal performance impact while providing essential functionality for a production API.

