# Production Settings Guide

## Overview

This document explains the production settings configuration for cloud deployment, focusing on HTTPS, managed PostgreSQL, Docker, and environment variables.

---

## HTTPS Configuration

### Settings

All HTTPS settings are in `config/settings/production.py`:

```python
# Force HTTPS redirects
SECURE_SSL_REDIRECT = True

# HSTS (HTTP Strict Transport Security)
SECURE_HSTS_SECONDS = 31536000  # 1 year
SECURE_HSTS_INCLUDE_SUBDOMAINS = True
SECURE_HSTS_PRELOAD = True

# Trust proxy headers (for load balancers)
SECURE_PROXY_SSL_HEADER = ('HTTP_X_FORWARDED_PROTO', 'https')

# Secure cookies
SESSION_COOKIE_SECURE = True
CSRF_COOKIE_SECURE = True
```

### How It Works

1. **SECURE_SSL_REDIRECT**: Automatically redirects HTTP to HTTPS
2. **HSTS**: Tells browsers to always use HTTPS for this domain
3. **SECURE_PROXY_SSL_HEADER**: Trusts the `X-Forwarded-Proto` header from your load balancer
4. **Secure Cookies**: Cookies only sent over HTTPS

### Load Balancer Configuration

Your load balancer/reverse proxy must:
1. Terminate SSL/TLS
2. Set `X-Forwarded-Proto: https` header
3. Forward requests to Django on HTTP (internal)

**Example Nginx config:**
```nginx
server {
    listen 443 ssl;
    server_name api.example.com;
    
    ssl_certificate /path/to/cert.pem;
    ssl_certificate_key /path/to/key.pem;
    
    location / {
        proxy_pass http://django:8000;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

---

## Managed PostgreSQL Configuration

### Database URL Format

Use a full connection string:

```bash
DATABASE_URL=postgresql://user:password@host:port/dbname?sslmode=require
```

### Individual Variables (Alternative)

If your cloud provider doesn't provide a connection string:

```python
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': os.environ.get('DB_NAME'),
        'USER': os.environ.get('DB_USER'),
        'PASSWORD': os.environ.get('DB_PASSWORD'),
        'HOST': os.environ.get('DB_HOST'),
        'PORT': os.environ.get('DB_PORT', '5432'),
        'OPTIONS': {
            'sslmode': 'require',  # Require SSL
        },
        'CONN_MAX_AGE': 600,  # Connection pooling
    }
}
```

### Connection Pooling

**In Django:**
```python
DATABASES['default']['CONN_MAX_AGE'] = 600  # 10 minutes
```

**In Managed Service:**
- Configure connection pool size (20-50 connections recommended)
- Set max connections based on your plan

### SSL/TLS

Always require SSL for production:

```python
'OPTIONS': {
    'sslmode': 'require',  # or 'verify-full' for certificate verification
}
```

---

## Docker Configuration

### Production Dockerfile

The Dockerfile uses a multi-stage build:

1. **Builder stage**: Installs dependencies
2. **Runtime stage**: Minimal image with only runtime dependencies

### Key Features

- **Non-root user**: Runs as `appuser` (UID 1000)
- **Health check**: Checks `/health/` endpoint
- **Gunicorn**: Production WSGI server
- **Multi-stage**: Smaller final image

### Running in Production

```bash
docker run -d \
  --name trip-planner-backend \
  -p 8000:8000 \
  -e DJANGO_SETTINGS_MODULE=config.settings.production \
  -e DJANGO_SECRET_KEY=your-secret-key \
  -e ALLOWED_HOSTS=api.example.com \
  -e DATABASE_URL=postgresql://... \
  -e REDIS_URL=redis://... \
  smart-trip-planner-backend:latest
```

### Gunicorn Configuration

Default: 4 workers

Adjust based on CPU cores:
- **2x CPU cores**: `--workers 4` (default)
- **4x CPU cores**: `--workers 8`
- **8x CPU cores**: `--workers 16`

Formula: `(2 × CPU cores) + 1`

---

## Environment Variables

### Required Variables

```bash
# Django
DJANGO_SECRET_KEY=your-secret-key-here
DJANGO_SETTINGS_MODULE=config.settings.production
ALLOWED_HOSTS=api.example.com,www.example.com

# Database
DATABASE_URL=postgresql://user:password@host:port/dbname?sslmode=require

# Redis
REDIS_URL=redis://host:port/db

# CORS
CORS_ALLOWED_ORIGINS=https://app.example.com,https://www.example.com
```

### Optional Variables

```bash
# HTTPS
SECURE_SSL_REDIRECT=True

# Email
EMAIL_HOST=smtp.example.com
EMAIL_PORT=587
EMAIL_HOST_USER=your-email@example.com
EMAIL_HOST_PASSWORD=your-password
DEFAULT_FROM_EMAIL=noreply@example.com

# Rate Limiting
RATE_LIMIT_ENABLED=True
RATE_LIMIT_DEFAULT=100
RATE_LIMIT_WINDOW=60

# Static/Media (if using cloud storage)
AWS_STORAGE_BUCKET_NAME=your-bucket
AWS_ACCESS_KEY_ID=your-key
AWS_SECRET_ACCESS_KEY=your-secret
```

### Setting in Cloud Providers

**AWS (ECS):**
- Task definition → Environment variables

**Google Cloud (Cloud Run):**
- Service configuration → Environment variables

**Azure (App Service):**
- Configuration → Application settings

**Heroku:**
```bash
heroku config:set DJANGO_SECRET_KEY=your-key
```

**Railway:**
- Project → Variables

---

## Static Files

### Option 1: WhiteNoise (Simple)

```python
# In production.py
STATICFILES_STORAGE = 'whitenoise.storage.CompressedManifestStaticFilesStorage'

# Install
pip install whitenoise
```

**Pros:**
- Simple setup
- No external service needed
- Works with most cloud providers

**Cons:**
- Served by Django (less efficient)
- Not ideal for high traffic

### Option 2: CDN (Recommended for Production)

```python
# In production.py
STATICFILES_STORAGE = 'storages.backends.s3boto3.S3Boto3Storage'
AWS_STORAGE_BUCKET_NAME = os.environ.get('AWS_STORAGE_BUCKET_NAME')
AWS_S3_CUSTOM_DOMAIN = f'{AWS_STORAGE_BUCKET_NAME}.s3.amazonaws.com'
```

**Pros:**
- Fast delivery
- Offloads Django
- Better for high traffic

**Cons:**
- Requires cloud storage setup
- Additional cost

---

## Media Files

### Cloud Storage (Recommended)

```python
# In production.py
DEFAULT_FILE_STORAGE = 'storages.backends.s3boto3.S3Boto3Storage'
AWS_STORAGE_BUCKET_NAME = os.environ.get('AWS_STORAGE_BUCKET_NAME')
AWS_ACCESS_KEY_ID = os.environ.get('AWS_ACCESS_KEY_ID')
AWS_SECRET_ACCESS_KEY = os.environ.get('AWS_SECRET_ACCESS_KEY')
```

**Install:**
```bash
pip install django-storages boto3
```

**Providers:**
- AWS S3
- Google Cloud Storage
- Azure Blob Storage

---

## Logging

### Production Logging

```python
# In production.py
LOGGING['handlers']['console']['formatter'] = 'json'
LOGGING['root']['level'] = 'INFO'
LOGGING['loggers']['django']['level'] = 'WARNING'
```

### Cloud Log Aggregation

**AWS:**
- CloudWatch Logs
- Set `AWS_REGION` environment variable

**Google Cloud:**
- Cloud Logging
- Automatic if running on GCP

**Azure:**
- Azure Monitor
- Automatic if running on Azure

**Heroku:**
- Heroku Logs
- Automatic

---

## Security Checklist

- [x] **DEBUG = False**: Already set in production.py
- [x] **SECRET_KEY**: Must be set via environment variable
- [x] **ALLOWED_HOSTS**: Must include your domain
- [x] **HTTPS**: Enforced via SECURE_SSL_REDIRECT
- [x] **HSTS**: Enabled for 1 year
- [x] **Secure Cookies**: SESSION_COOKIE_SECURE and CSRF_COOKIE_SECURE
- [x] **CORS**: Strictly configured (no wildcards)
- [x] **Rate Limiting**: Enabled
- [x] **Database SSL**: Required
- [x] **No Secrets in Code**: All secrets via environment variables

---

## Performance Optimization

### Database

- **Connection Pooling**: `CONN_MAX_AGE = 600`
- **Indexes**: Ensure all foreign keys and frequently queried fields are indexed
- **Query Optimization**: Use `select_related` and `prefetch_related`

### Caching

- **Redis**: Configured for sessions and cache
- **Cache Backend**: `django.core.cache.backends.redis.RedisCache`

### Static Files

- **CDN**: Use CDN for static files
- **Compression**: Enable gzip compression in load balancer

### Gunicorn

- **Workers**: Adjust based on CPU cores
- **Threads**: Use `--threads` for I/O-bound workloads

---

## Monitoring

### Health Check

Endpoint: `/health/`

```python
# In config/views.py
def health_check(request):
    return JsonResponse({'status': 'healthy'})
```

### Error Tracking

**Sentry (Recommended):**
```python
# Install
pip install sentry-sdk

# In production.py
import sentry_sdk
from sentry_sdk.integrations.django import DjangoIntegration

sentry_sdk.init(
    dsn=os.environ.get('SENTRY_DSN'),
    integrations=[DjangoIntegration()],
    traces_sample_rate=0.1,
)
```

---

## Summary

### Key Settings

1. **HTTPS**: Fully configured with HSTS
2. **PostgreSQL**: Managed service with SSL
3. **Docker**: Multi-stage build, non-root user
4. **Environment Variables**: All configuration via env vars
5. **Security**: All security settings enabled
6. **Performance**: Optimized for production

### Next Steps

1. Set up managed PostgreSQL
2. Set up managed Redis
3. Configure environment variables
4. Build and deploy Docker image
5. Verify deployment
6. Set up monitoring

The production settings are ready for cloud deployment with proper HTTPS, managed PostgreSQL, and Docker support.

