# Quick Start Guide

Get the Smart Trip Planner up and running in minutes.

## Prerequisites

- **Python 3.11+** (for backend)
- **PostgreSQL 12+** (or use Docker)
- **Redis** (for WebSocket support, or use Docker)
- **Docker & Docker Compose** (optional, recommended)
- **Flutter 3.16+** (for frontend, optional)

---

## Option 1: Docker (Recommended - Easiest)

### Backend with Docker

1. **Navigate to backend directory:**
   ```bash
   cd backend/docker
   ```

2. **Create environment file:**
   ```bash
   cd ../..
   cp backend/.env.example backend/.env
   # Edit backend/.env with your settings (optional for local dev)
   ```

3. **Start services:**
   ```bash
   cd backend/docker
   docker-compose up --build
   ```

4. **Run migrations:**
   ```bash
   docker-compose exec web python manage.py migrate
   ```

5. **Create superuser:**
   ```bash
   docker-compose exec web python manage.py createsuperuser
   ```

6. **Access the API:**
   - API: http://localhost:8000
   - Admin: http://localhost:8000/admin
   - API Docs: http://localhost:8000/api/docs

**Stop services:**
```bash
docker-compose down
```

---

## Option 2: Local Development (Backend)

### Step 1: Set Up Python Environment

```bash
cd backend

# Create virtual environment
python -m venv venv

# Activate virtual environment
# On macOS/Linux:
source venv/bin/activate
# On Windows:
venv\Scripts\activate
```

### Step 2: Install Dependencies

```bash
# Install Python packages
pip install --upgrade pip
pip install -r requirements/development.txt
```

### Step 3: Set Up Database

**Option A: Use PostgreSQL (Recommended)**

1. **Install PostgreSQL** (if not installed)
   - macOS: `brew install postgresql`
   - Ubuntu: `sudo apt-get install postgresql`
   - Windows: Download from postgresql.org

2. **Create database:**
   ```bash
   createdb trip_planner
   # Or using psql:
   psql -U postgres
   CREATE DATABASE trip_planner;
   \q
   ```

3. **Set environment variables:**
   ```bash
   # Create .env file
   cp .env.example .env
   ```

4. **Edit `.env` file:**
   ```bash
   DJANGO_SECRET_KEY=your-secret-key-here
   DB_NAME=trip_planner
   DB_USER=postgres
   DB_PASSWORD=your-password
   DB_HOST=localhost
   DB_PORT=5432
   DJANGO_SETTINGS_MODULE=config.settings.development
   ```

**Option B: Use SQLite (Quick Start - Not for Production)**

Edit `backend/config/settings/development.py`:
```python
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.sqlite3',
        'NAME': BASE_DIR / 'db.sqlite3',
    }
}
```

### Step 4: Set Up Redis (for WebSocket support)

**Option A: Install Redis locally**
- macOS: `brew install redis`
- Ubuntu: `sudo apt-get install redis-server`
- Windows: Download from redis.io

**Option B: Use Docker for Redis**
```bash
docker run -d -p 6379:6379 redis:7-alpine
```

**Option C: Skip Redis (WebSocket won't work, but REST API will)**
- Set `REDIS_URL` to empty or comment out Channels config

### Step 5: Run Migrations

```bash
python manage.py migrate
```

### Step 6: Create Superuser

```bash
python manage.py createsuperuser
# Follow prompts to create admin user
```

### Step 7: Collect Static Files (Optional)

```bash
python manage.py collectstatic --noinput
```

### Step 8: Run Development Server

```bash
python manage.py runserver
```

**Access the API:**
- API: http://localhost:8000
- Admin: http://localhost:8000/admin
- API Docs: http://localhost:8000/api/docs

---

## Option 3: Frontend (Flutter)

### Step 1: Install Flutter

1. **Download Flutter SDK:**
   - Visit https://flutter.dev/docs/get-started/install
   - Follow platform-specific instructions

2. **Verify installation:**
   ```bash
   flutter doctor
   ```

### Step 2: Set Up Flutter Project

```bash
cd frontend

# Install dependencies
flutter pub get
```

### Step 3: Configure API Endpoint

Edit `frontend/core/config/api_config.dart`:
```dart
class ApiConfig {
  static const String baseUrl = 'http://localhost:8000';
  static const String apiVersion = 'v1';
}
```

**For Android emulator, use:**
```dart
static const String baseUrl = 'http://10.0.2.2:8000';  // Android emulator
```

**For iOS simulator, use:**
```dart
static const String baseUrl = 'http://localhost:8000';  // iOS simulator
```

### Step 4: Run Flutter App

```bash
# List available devices
flutter devices

# Run on specific device
flutter run

# Or run on specific device
flutter run -d <device-id>
```

---

## Testing the Setup

### Test Backend API

1. **Health Check:**
   ```bash
   curl http://localhost:8000/health/
   ```
   Should return: `{"status": "healthy"}`

2. **Register a User:**
   ```bash
   curl -X POST http://localhost:8000/api/v1/auth/register/ \
     -H "Content-Type: application/json" \
     -d '{
       "email": "test@example.com",
       "password": "testpass123",
       "password_confirm": "testpass123"
     }'
   ```

3. **Login:**
   ```bash
   curl -X POST http://localhost:8000/api/v1/auth/login/ \
     -H "Content-Type: application/json" \
     -d '{
       "email": "test@example.com",
       "password": "testpass123"
     }'
   ```

4. **Access API Docs:**
   - Open http://localhost:8000/api/docs in browser
   - Try endpoints interactively

### Test Frontend

1. **Run Flutter app:**
   ```bash
   cd frontend
   flutter run
   ```

2. **Test authentication:**
   - Register a new user
   - Login with credentials
   - Verify JWT tokens are stored

---

## Common Issues & Solutions

### Backend Issues

**Issue: Database connection error**
```bash
# Check PostgreSQL is running
# macOS/Linux:
pg_isready

# Windows:
# Check Services for PostgreSQL
```

**Issue: Port 8000 already in use**
```bash
# Use different port
python manage.py runserver 8001
```

**Issue: Redis connection error**
```bash
# Check Redis is running
redis-cli ping
# Should return: PONG
```

**Issue: Migration errors**
```bash
# Reset database (WARNING: deletes all data)
python manage.py flush
python manage.py migrate
```

### Frontend Issues

**Issue: Flutter dependencies error**
```bash
cd frontend
flutter clean
flutter pub get
```

**Issue: API connection refused**
- Check backend is running
- Verify API URL in `api_config.dart`
- For Android emulator, use `10.0.2.2:8000`
- For iOS simulator, use `localhost:8000`

**Issue: WebSocket connection fails**
- Ensure Redis is running
- Check `REDIS_URL` in backend `.env`
- Verify Channels is configured in `settings/base.py`

---

## Environment Variables Reference

### Backend (.env file)

```bash
# Django
DJANGO_SECRET_KEY=your-secret-key-here
DJANGO_SETTINGS_MODULE=config.settings.development
ALLOWED_HOSTS=localhost,127.0.0.1

# Database
DB_NAME=trip_planner
DB_USER=postgres
DB_PASSWORD=your-password
DB_HOST=localhost
DB_PORT=5432
# Or use DATABASE_URL:
# DATABASE_URL=postgresql://user:password@localhost:5432/trip_planner

# Redis
REDIS_URL=redis://localhost:6379/0
REDIS_HOST=localhost
REDIS_PORT=6379

# CORS (for development)
CORS_ALLOWED_ORIGINS=http://localhost:3000,http://localhost:8080

# Email (optional for development)
EMAIL_HOST=smtp.gmail.com
EMAIL_PORT=587
EMAIL_HOST_USER=your-email@gmail.com
EMAIL_HOST_PASSWORD=your-app-password
```

---

## Development Workflow

### Daily Development

1. **Start backend:**
   ```bash
   cd backend
   source venv/bin/activate  # or venv\Scripts\activate on Windows
   python manage.py runserver
   ```

2. **Start frontend (in new terminal):**
   ```bash
   cd frontend
   flutter run
   ```

3. **Make changes and test**

4. **Run tests:**
   ```bash
   # Backend
   cd backend
   pytest

   # Frontend
   cd frontend
   flutter test
   ```

### Database Changes

1. **Create migration:**
   ```bash
   python manage.py makemigrations
   ```

2. **Apply migration:**
   ```bash
   python manage.py migrate
   ```

3. **Check migration status:**
   ```bash
   python manage.py showmigrations
   ```

---

## Production Deployment

For production deployment, see:
- [Deployment Checklist](./backend/DEPLOYMENT_CHECKLIST.md)
- [Production Settings](./backend/PRODUCTION_SETTINGS.md)

**Key differences for production:**
- Use `config.settings.production`
- Set `DEBUG=False`
- Use managed PostgreSQL
- Configure HTTPS
- Set proper `ALLOWED_HOSTS`

---

## Next Steps

1. **Explore the API:**
   - Visit http://localhost:8000/api/docs
   - Try creating a trip, inviting collaborators

2. **Read Documentation:**
   - [Architecture](./ARCHITECTURE.md)
   - [API Documentation](./backend/API_DOCUMENTATION.md)
   - [Flutter Architecture](./frontend/FLUTTER_ARCHITECTURE.md)

3. **Run Tests:**
   - Backend: `pytest --cov=.`
   - Frontend: `flutter test`

4. **Start Building:**
   - Add new features
   - Customize UI
   - Extend API endpoints

---

## Quick Commands Reference

```bash
# Backend
cd backend
python manage.py runserver          # Start server
python manage.py migrate            # Run migrations
python manage.py createsuperuser    # Create admin
python manage.py shell              # Django shell
pytest                              # Run tests

# Frontend
cd frontend
flutter run                         # Run app
flutter test                        # Run tests
flutter analyze                     # Check code
flutter build apk                   # Build Android

# Docker
docker-compose up                   # Start services
docker-compose down                 # Stop services
docker-compose logs                 # View logs
```

---

**Need help?** Check the documentation or open an issue.

