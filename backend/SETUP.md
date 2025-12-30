# Setup Guide

## Initial Setup Steps

### 1. Database Setup

```bash
# Create PostgreSQL database
createdb trip_planner

# Or using psql
psql -U postgres
CREATE DATABASE trip_planner;
```

### 2. Environment Variables

Copy `.env.example` to `.env` and configure:

```bash
cp .env.example .env
```

Edit `.env` with your settings:
- `DJANGO_SECRET_KEY` - Generate a secure key
- Database credentials
- Other environment-specific settings

### 3. Install Dependencies

```bash
# Create virtual environment
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements/development.txt
```

### 4. Run Migrations

```bash
python manage.py makemigrations
python manage.py migrate
```

### 5. Create Superuser

```bash
python manage.py createsuperuser
```

### 6. Run Server

```bash
python manage.py runserver
```

## Generating Django Secret Key

```bash
python -c "from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())"
```

## Testing the API

### Register a User

```bash
curl -X POST http://localhost:8000/api/v1/auth/register/ \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "testpass123",
    "password_confirm": "testpass123",
    "first_name": "Test",
    "last_name": "User"
  }'
```

### Login

```bash
curl -X POST http://localhost:8000/api/v1/auth/login/ \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "testpass123"
  }'
```

### Create a Trip (with token)

```bash
curl -X POST http://localhost:8000/api/v1/trips/ \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -d '{
    "title": "Summer Vacation",
    "description": "Trip to Europe",
    "start_date": "2024-07-01",
    "end_date": "2024-07-15"
  }'
```

## Health Check

```bash
curl http://localhost:8000/health/
```

## Common Issues

### Database Connection Error
- Check PostgreSQL is running
- Verify database credentials in `.env`
- Ensure database exists

### Migration Errors
- Delete migration files (except `__init__.py`) and re-run `makemigrations`
- Check for model conflicts

### Import Errors
- Ensure virtual environment is activated
- Verify all dependencies are installed
- Check Python path

