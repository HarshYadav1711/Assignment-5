# Cloud Deployment Checklist

## Pre-Deployment

### 1. Environment Variables

- [ ] **DJANGO_SECRET_KEY**: Strong, unique secret key (generate with `python -c "from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())"`)
- [ ] **ALLOWED_HOSTS**: Comma-separated list of allowed domains (e.g., `api.example.com,www.example.com`)
- [ ] **SECURE_SSL_REDIRECT**: Set to `True` for HTTPS enforcement
- [ ] **CORS_ALLOWED_ORIGINS**: Comma-separated list of frontend origins (e.g., `https://app.example.com,https://www.example.com`)

### 2. Database (Managed PostgreSQL)

- [ ] **DATABASE_URL**: Full PostgreSQL connection string from managed service
  - Format: `postgresql://user:password@host:port/dbname`
  - Or individual variables:
    - `DB_NAME`: Database name
    - `DB_USER`: Database user
    - `DB_PASSWORD`: Database password
    - `DB_HOST`: Database host
    - `DB_PORT`: Database port (usually 5432)
- [ ] **Connection pooling**: Configured in managed service (recommended: 20-50 connections)
- [ ] **Backups**: Enabled in managed service (daily recommended)
- [ ] **SSL mode**: Set to `require` or `verify-full` for production

### 3. Redis (Managed Service)

- [ ] **REDIS_URL**: Full Redis connection string
  - Format: `redis://user:password@host:port/db`
  - Or: `rediss://user:password@host:port/db` (SSL)
- [ ] **REDIS_HOST**: Redis host (if not using REDIS_URL)
- [ ] **REDIS_PORT**: Redis port (if not using REDIS_URL)
- [ ] **Redis persistence**: Configured in managed service

### 4. HTTPS Configuration

- [ ] **SSL certificate**: Configured in load balancer/reverse proxy
- [ ] **SECURE_PROXY_SSL_HEADER**: Set correctly for your proxy
  - Common: `HTTP_X_FORWARDED_PROTO` header set to `https`
- [ ] **SECURE_SSL_REDIRECT**: Set to `True`
- [ ] **HSTS**: Enabled (already configured in production.py)

### 5. Static Files

- [ ] **Static files storage**: Configured (WhiteNoise or CDN)
- [ ] **STATIC_ROOT**: Set to appropriate directory
- [ ] **Static files collected**: Run `python manage.py collectstatic --noinput`

### 6. Media Files

- [ ] **Media storage**: Configured (S3, Azure Blob, etc.)
- [ ] **MEDIA_ROOT**: Set to cloud storage path
- [ ] **Storage credentials**: Configured via environment variables

### 7. Email Configuration

- [ ] **EMAIL_HOST**: SMTP server host
- [ ] **EMAIL_PORT**: SMTP port (usually 587 for TLS)
- [ ] **EMAIL_HOST_USER**: SMTP username
- [ ] **EMAIL_HOST_PASSWORD**: SMTP password
- [ ] **EMAIL_USE_TLS**: Set to `True`
- [ ] **DEFAULT_FROM_EMAIL**: Set to valid email address

### 8. Docker Configuration

- [ ] **Dockerfile**: Updated for production
- [ ] **Multi-stage build**: Enabled (already configured)
- [ ] **Non-root user**: Running as non-root (already configured)
- [ ] **Health check**: Configured (already in Dockerfile)
- [ ] **Gunicorn workers**: Set appropriately (4 workers default, adjust based on CPU)

### 9. Security

- [ ] **DEBUG**: Set to `False` (already in production.py)
- [ ] **Secret key**: Strong, unique, stored securely
- [ ] **CORS**: Strictly configured (no wildcards)
- [ ] **Rate limiting**: Enabled
- [ ] **Security headers**: All enabled (HSTS, XSS protection, etc.)

### 10. Monitoring & Logging

- [ ] **Logging**: Configured for cloud log aggregation
- [ ] **Health check endpoint**: `/health/` accessible
- [ ] **Monitoring**: Set up (e.g., Sentry, DataDog, CloudWatch)
- [ ] **Alerts**: Configured for critical errors

---

## Deployment Steps

### 1. Build Docker Image

```bash
docker build -f docker/Dockerfile -t smart-trip-planner-backend:latest .
```

### 2. Test Docker Image Locally

```bash
docker run -p 8000:8000 \
  -e DJANGO_SETTINGS_MODULE=config.settings.production \
  -e DJANGO_SECRET_KEY=your-secret-key \
  -e ALLOWED_HOSTS=localhost \
  -e DATABASE_URL=postgresql://user:pass@host:port/db \
  -e REDIS_URL=redis://host:port/db \
  smart-trip-planner-backend:latest
```

### 3. Run Migrations

```bash
docker run --rm \
  -e DJANGO_SETTINGS_MODULE=config.settings.production \
  -e DATABASE_URL=postgresql://user:pass@host:port/db \
  smart-trip-planner-backend:latest \
  python manage.py migrate --noinput
```

### 4. Collect Static Files

```bash
docker run --rm \
  -e DJANGO_SETTINGS_MODULE=config.settings.production \
  smart-trip-planner-backend:latest \
  python manage.py collectstatic --noinput
```

### 5. Deploy to Cloud

**Option A: Container Service (ECS, GKE, AKS)**
- Push image to container registry
- Deploy using service configuration
- Set environment variables in service

**Option B: App Service (Heroku, Railway, Render)**
- Connect repository or push image
- Set environment variables in dashboard
- Deploy

**Option C: VM (EC2, GCE, Azure VM)**
- Pull image on VM
- Run with docker-compose or systemd
- Configure reverse proxy (Nginx)

### 6. Verify Deployment

- [ ] Health check endpoint responds: `curl https://api.example.com/health/`
- [ ] API endpoints accessible: `curl https://api.example.com/api/v1/`
- [ ] HTTPS redirects working
- [ ] Database connection working
- [ ] Redis connection working
- [ ] Static files serving correctly
- [ ] Logs accessible

---

## Post-Deployment

### 1. Verify Functionality

- [ ] User registration works
- [ ] User login works
- [ ] JWT tokens issued correctly
- [ ] API endpoints respond correctly
- [ ] WebSocket connections work (if applicable)
- [ ] File uploads work (if applicable)

### 2. Performance Checks

- [ ] Response times acceptable (<200ms for API calls)
- [ ] Database queries optimized
- [ ] Caching working (Redis)
- [ ] Static files loading quickly

### 3. Security Checks

- [ ] HTTPS enforced
- [ ] Security headers present
- [ ] CORS configured correctly
- [ ] Rate limiting working
- [ ] No sensitive data in logs

### 4. Monitoring

- [ ] Error tracking configured (Sentry, etc.)
- [ ] Log aggregation working
- [ ] Alerts configured
- [ ] Performance monitoring active

---

## Rollback Plan

If deployment fails:

1. **Immediate**: Revert to previous Docker image version
2. **Database**: Restore from backup if needed
3. **Environment**: Rollback environment variables if changed
4. **Investigate**: Check logs for errors
5. **Fix**: Address issues before redeploying

---

## Environment Variables Reference

### Required

```bash
DJANGO_SECRET_KEY=your-secret-key-here
ALLOWED_HOSTS=api.example.com,www.example.com
DATABASE_URL=postgresql://user:password@host:port/dbname
REDIS_URL=redis://host:port/db
CORS_ALLOWED_ORIGINS=https://app.example.com
DJANGO_SETTINGS_MODULE=config.settings.production
```

### Optional (but recommended)

```bash
SECURE_SSL_REDIRECT=True
EMAIL_HOST=smtp.example.com
EMAIL_PORT=587
EMAIL_HOST_USER=your-email@example.com
EMAIL_HOST_PASSWORD=your-email-password
DEFAULT_FROM_EMAIL=noreply@example.com
RATE_LIMIT_ENABLED=True
RATE_LIMIT_DEFAULT=100
RATE_LIMIT_WINDOW=60
```

---

## Cloud Provider Specific Notes

### AWS (ECS/EKS)

- Use AWS RDS for PostgreSQL
- Use ElastiCache for Redis
- Use ALB/NLB for load balancing
- Use CloudWatch for logging

### Google Cloud (GKE/Cloud Run)

- Use Cloud SQL for PostgreSQL
- Use Memorystore for Redis
- Use Cloud Load Balancing
- Use Cloud Logging

### Azure (AKS/App Service)

- Use Azure Database for PostgreSQL
- Use Azure Cache for Redis
- Use Application Gateway
- Use Azure Monitor

### Heroku

- Use Heroku Postgres addon
- Use Heroku Redis addon
- Automatic HTTPS via Heroku
- Use Heroku Logs

### Railway

- Use Railway PostgreSQL
- Use Railway Redis
- Automatic HTTPS
- Use Railway Logs

---

## Summary

This checklist ensures a smooth, secure cloud deployment. Follow each step carefully and verify before moving to the next step.

