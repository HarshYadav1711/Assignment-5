# Common Deployment Pitfalls and Solutions

## Overview

This document outlines common pitfalls when deploying Django to the cloud and how to avoid them.

---

## 1. HTTPS Configuration Issues

### Pitfall: Mixed Content or Redirect Loops

**Symptoms:**
- Infinite redirect loops
- Mixed content warnings
- HTTPS not enforced

**Causes:**
- `SECURE_PROXY_SSL_HEADER` not set correctly
- Load balancer not setting `X-Forwarded-Proto` header
- `SECURE_SSL_REDIRECT` enabled behind proxy without proper headers

**Solution:**
```python
# In production.py
SECURE_PROXY_SSL_HEADER = ('HTTP_X_FORWARDED_PROTO', 'https')
```

**Verify:**
```bash
curl -H "X-Forwarded-Proto: https" http://localhost:8000/
```

**Prevention:**
- Always set `SECURE_PROXY_SSL_HEADER` when behind a proxy
- Test HTTPS redirects in staging first
- Check load balancer configuration

---

## 2. Database Connection Issues

### Pitfall: Connection Timeouts or "Too Many Connections"

**Symptoms:**
- Database connection errors
- "Too many connections" errors
- Slow queries

**Causes:**
- No connection pooling
- Connections not closed properly
- Too many workers/processes

**Solution:**
```python
# In production.py
DATABASES['default']['CONN_MAX_AGE'] = 600  # 10 minutes
```

**Also:**
- Use managed PostgreSQL connection pooling
- Limit Gunicorn workers based on database connection limit
- Monitor connection usage

**Prevention:**
- Set `CONN_MAX_AGE` for connection reuse
- Use connection pooling in managed service
- Monitor database connections

---

## 3. Static Files Not Serving

### Pitfall: 404 Errors for Static Files

**Symptoms:**
- CSS/JS files return 404
- Admin interface broken
- Static files not found

**Causes:**
- `collectstatic` not run
- `STATIC_ROOT` not set correctly
- Static files not in Docker image
- CDN not configured

**Solution:**
```bash
# Run collectstatic during build or deployment
python manage.py collectstatic --noinput
```

**In Dockerfile:**
```dockerfile
RUN python manage.py collectstatic --noinput
```

**Prevention:**
- Always run `collectstatic` before deployment
- Use CDN for static files
- Verify static files in Docker image

---

## 4. Environment Variables Not Set

### Pitfall: Missing or Incorrect Environment Variables

**Symptoms:**
- Application crashes on startup
- Default values used (insecure)
- Configuration errors

**Causes:**
- Environment variables not set in cloud provider
- Typos in variable names
- Missing required variables

**Solution:**
```python
# In production.py - fail fast if required vars missing
SECRET_KEY = os.environ.get('DJANGO_SECRET_KEY')
if not SECRET_KEY:
    raise ValueError("DJANGO_SECRET_KEY environment variable is required")
```

**Prevention:**
- Document all required environment variables
- Use validation in settings
- Test with missing variables in staging

---

## 5. CORS Configuration Errors

### Pitfall: CORS Errors in Browser

**Symptoms:**
- "CORS policy" errors in browser console
- API requests blocked
- Frontend can't connect to backend

**Causes:**
- `CORS_ALLOWED_ORIGINS` not set
- Wildcard `*` used in production
- Missing credentials configuration

**Solution:**
```python
# In production.py
CORS_ALLOWED_ORIGINS = os.environ.get('CORS_ALLOWED_ORIGINS', '').split(',')
CORS_ALLOW_CREDENTIALS = True
CORS_ALLOW_ALL_ORIGINS = False  # Never True in production
```

**Prevention:**
- Always set `CORS_ALLOWED_ORIGINS` explicitly
- Never use wildcards in production
- Test CORS in staging

---

## 6. Secret Key Exposure

### Pitfall: Secret Key in Code or Logs

**Symptoms:**
- Security warnings
- Potential security breach
- Secrets visible in version control

**Causes:**
- Hardcoded secret key
- Secret key in Docker image layers
- Secret key in logs

**Solution:**
```python
# Always use environment variable
SECRET_KEY = os.environ.get('DJANGO_SECRET_KEY')
if not SECRET_KEY:
    raise ValueError("DJANGO_SECRET_KEY is required")
```

**Prevention:**
- Never commit secrets to version control
- Use environment variables for all secrets
- Use secret management services (AWS Secrets Manager, etc.)
- Rotate secrets regularly

---

## 7. Debug Mode Enabled

### Pitfall: DEBUG = True in Production

**Symptoms:**
- Detailed error pages exposed
- Sensitive information in errors
- Performance issues

**Causes:**
- Forgot to set `DEBUG = False`
- Environment variable not set
- Wrong settings module

**Solution:**
```python
# In production.py
DEBUG = False  # Always False in production
```

**Prevention:**
- Always set `DEBUG = False` in production.py
- Use environment variable as backup
- Test with DEBUG=False in staging

---

## 8. Database Migrations Not Run

### Pitfall: Database Schema Out of Sync

**Symptoms:**
- Application errors
- Missing tables/columns
- Migration errors

**Causes:**
- Migrations not run during deployment
- Migrations run in wrong order
- Database state inconsistent

**Solution:**
```bash
# Always run migrations during deployment
python manage.py migrate --noinput
```

**Prevention:**
- Include migrations in deployment process
- Test migrations in staging first
- Use `--noinput` flag for automated deployments
- Backup database before migrations

---

## 9. Redis Connection Issues

### Pitfall: Redis Not Available or Wrong Configuration

**Symptoms:**
- Cache not working
- WebSocket connections fail
- Rate limiting not working

**Causes:**
- Redis URL incorrect
- Redis not accessible
- Wrong Redis database number

**Solution:**
```python
# In production.py
REDIS_URL = os.environ.get('REDIS_URL')
if not REDIS_URL:
    raise ValueError("REDIS_URL is required")
```

**Prevention:**
- Test Redis connection during deployment
- Use managed Redis service
- Verify Redis URL format
- Monitor Redis connection health

---

## 10. Gunicorn Worker Configuration

### Pitfall: Too Many or Too Few Workers

**Symptoms:**
- High memory usage
- Slow response times
- Worker timeouts

**Causes:**
- Wrong number of workers
- Workers not optimized for workload
- Memory limits exceeded

**Solution:**
```dockerfile
# In Dockerfile - adjust based on CPU cores
CMD ["gunicorn", "config.wsgi:application", "--bind", "0.0.0.0:8000", "--workers", "4"]
```

**Formula:**
- `(2 × CPU cores) + 1` workers
- Adjust based on memory and workload

**Prevention:**
- Start with default (4 workers)
- Monitor performance
- Adjust based on metrics
- Consider threads for I/O-bound workloads

---

## 11. Health Check Failures

### Pitfall: Health Check Endpoint Not Working

**Symptoms:**
- Container marked as unhealthy
- Automatic restarts
- Deployment failures

**Causes:**
- Health check endpoint not accessible
- Health check too strict
- Database/Redis dependencies in health check

**Solution:**
```python
# In config/views.py - simple health check
def health_check(request):
    return JsonResponse({'status': 'healthy'})
```

**Prevention:**
- Keep health check simple
- Don't check database/Redis in health check
- Use separate endpoint for readiness check if needed

---

## 12. Time Zone Issues

### Pitfall: Incorrect Time Zones

**Symptoms:**
- Dates/times displayed incorrectly
- Database timestamps wrong
- User confusion

**Causes:**
- `USE_TZ = False` in production
- Time zone not set correctly
- Database time zone mismatch

**Solution:**
```python
# In base.py (already set)
USE_TZ = True
TIME_ZONE = 'UTC'
```

**Prevention:**
- Always use UTC in backend
- Convert to user timezone in frontend
- Set `USE_TZ = True`

---

## 13. Logging Configuration

### Pitfall: Too Much or Too Little Logging

**Symptoms:**
- Log storage costs high
- Important errors not logged
- Logs not accessible

**Causes:**
- DEBUG level in production
- Too verbose logging
- Logs not sent to aggregation service

**Solution:**
```python
# In production.py
LOGGING['root']['level'] = 'INFO'
LOGGING['loggers']['django']['level'] = 'WARNING'
```

**Prevention:**
- Use INFO level for application logs
- Use WARNING for Django logs
- Send logs to cloud log aggregation
- Set up log retention policies

---

## 14. Rate Limiting Issues

### Pitfall: Rate Limiting Too Strict or Not Working

**Symptoms:**
- Legitimate users blocked
- Rate limiting not enforced
- Performance issues

**Causes:**
- Rate limits too low
- Redis not available
- Cache backend not configured

**Solution:**
```python
# In production.py
RATE_LIMIT_ENABLED = True
RATE_LIMIT_DEFAULT = 100  # Adjust based on needs
```

**Prevention:**
- Test rate limiting in staging
- Monitor rate limit hits
- Adjust limits based on usage
- Ensure Redis is available

---

## 15. Docker Image Size

### Pitfall: Large Docker Images

**Symptoms:**
- Slow deployments
- High storage costs
- Long build times

**Causes:**
- Not using multi-stage builds
- Including unnecessary files
- Not using .dockerignore

**Solution:**
```dockerfile
# Use multi-stage build (already in Dockerfile)
FROM python:3.11-slim as builder
# ... build stage

FROM python:3.11-slim
# ... runtime stage
```

**Prevention:**
- Use multi-stage builds
- Use .dockerignore
- Use slim base images
- Remove build dependencies in final stage

---

## Prevention Checklist

- [ ] Test HTTPS configuration in staging
- [ ] Verify database connection pooling
- [ ] Run collectstatic during deployment
- [ ] Document all required environment variables
- [ ] Configure CORS correctly
- [ ] Never commit secrets
- [ ] Always set DEBUG = False
- [ ] Run migrations during deployment
- [ ] Test Redis connection
- [ ] Configure Gunicorn workers appropriately
- [ ] Keep health check simple
- [ ] Use UTC for time zones
- [ ] Configure logging levels
- [ ] Test rate limiting
- [ ] Optimize Docker image size

---

## Summary

Most deployment issues stem from:
1. **Configuration errors**: Missing or incorrect settings
2. **Environment variables**: Not set or incorrect
3. **Security misconfigurations**: DEBUG=True, secrets in code
4. **Resource limits**: Database connections, memory
5. **Missing steps**: Migrations, collectstatic

**Best Practices:**
- Test in staging first
- Use environment variables for all configuration
- Monitor logs and metrics
- Have a rollback plan
- Document deployment process

Following this guide helps avoid common pitfalls and ensures a smooth deployment.

