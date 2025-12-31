# How to Run This Project

## 🚀 Fastest Way: Docker (Recommended)

If you have Docker installed, this is the easiest way to get everything running:

```bash
# 1. Navigate to docker directory
cd backend/docker

# 2. Start all services (PostgreSQL, Redis, Django)
docker-compose up --build

# 3. In a NEW terminal window, navigate to the same directory and run migrations
cd backend/docker
docker-compose exec web python manage.py migrate

# 4. Create admin user (in the same terminal)
docker-compose exec web python manage.py createsuperuser
# Follow prompts to create admin account

# 5. Access the application
# API: http://localhost:8000
# Admin: http://localhost:8000/admin
# API Docs: http://localhost:8000/api/docs
```

**Important:** All `docker-compose` commands must be run from the `backend/docker` directory, or use the `-f` flag:
```bash
# From project root, specify the compose file:
docker-compose -f backend/docker/docker-compose.yml exec web python manage.py migrate
```

**That's it!** The backend is now running with:
- ✅ PostgreSQL database
- ✅ Redis for WebSocket support
- ✅ Django development server

**To stop:**
```bash
docker-compose down
```

---

## 📝 Manual Setup (Step-by-Step)

### Prerequisites

- Python 3.11+
- PostgreSQL 12+ (or SQLite for quick testing)
- Redis (optional, for WebSocket support)
- Flutter 3.16+ (for frontend)

### Backend Setup

#### 1. Install Python Dependencies

```bash
cd backend

# Create virtual environment
python -m venv venv

# Activate virtual environment
# macOS/Linux:
source venv/bin/activate
# Windows:
venv\Scripts\activate

# Install packages
pip install -r requirements/development.txt
```

#### 2. Set Up Database

**PostgreSQL (Recommended):**

```bash
# Create database
createdb trip_planner

# Or using psql:
psql -U postgres
CREATE DATABASE trip_planner;
\q
```

**SQLite (Quick Testing - Not for Production):**

Edit `backend/config/settings/development.py`:
```python
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.sqlite3',
        'NAME': BASE_DIR / 'db.sqlite3',
    }
}
```

#### 3. Configure Environment Variables

Create `backend/.env` file:

```bash
# Django
DJANGO_SECRET_KEY=your-secret-key-here
DJANGO_SETTINGS_MODULE=config.settings.development
ALLOWED_HOSTS=localhost,127.0.0.1

# Database
DB_NAME=trip_planner
DB_USER=postgres
DB_PASSWORD=your-postgres-password
DB_HOST=localhost
DB_PORT=5432

# Redis (for WebSocket - optional)
REDIS_URL=redis://localhost:6379/0
```

**Generate secret key:**
```bash
python -c "from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())"
```

#### 4. Run Migrations

```bash
python manage.py migrate
```

#### 5. Create Admin User

```bash
python manage.py createsuperuser
# Enter email, password when prompted
```

#### 6. Start Redis (Optional - for WebSocket)

**macOS:**
```bash
brew install redis
brew services start redis
```

**Linux:**
```bash
sudo apt-get install redis-server
sudo systemctl start redis
```

**Or use Docker:**
```bash
docker run -d -p 6379:6379 redis:7-alpine
```

**Skip Redis:** The REST API will work, but WebSocket chat won't function.

#### 7. Start Development Server

```bash
python manage.py runserver
```

**Access:**
- API: http://localhost:8000
- Admin: http://localhost:8000/admin
- API Docs: http://localhost:8000/api/docs

---

### Frontend Setup

#### 1. Install Flutter

Visit https://flutter.dev/docs/get-started/install and follow platform-specific instructions.

Verify installation:
```bash
flutter doctor
```

#### 2. Install Dependencies

```bash
cd frontend
flutter pub get
```

#### 3. Configure API Endpoint

Edit `frontend/core/config/api_config.dart`:

```dart
class ApiConfig {
  // For local development
  static const String baseUrl = 'http://localhost:8000';
  
  // For Android emulator, use:
  // static const String baseUrl = 'http://10.0.2.2:8000';
  
  // For iOS simulator, use:
  // static const String baseUrl = 'http://localhost:8000';
  
  static const String apiVersion = 'v1';
}
```

#### 4. Run Flutter App

```bash
# List available devices
flutter devices

# Run on connected device/emulator
flutter run

# Or specify device
flutter run -d <device-id>
```

---

## ✅ Verify It's Working

### Test Backend

1. **Health Check:**
   ```bash
   curl http://localhost:8000/health/
   ```
   Should return: `{"status": "healthy"}`

2. **Register User:**
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

4. **Try API Docs:**
   - Open http://localhost:8000/api/docs
   - Try endpoints interactively

### Test Frontend

1. Run Flutter app: `flutter run`
2. Register a new user
3. Login with credentials
4. Create a trip

---

## 🐛 Troubleshooting

### Backend Issues

**Database connection error:**
```bash
# Check PostgreSQL is running
pg_isready
# Should return: /tmp:5432 - accepting connections
```

**Port 8000 already in use:**
```bash
# Use different port
python manage.py runserver 8001
```

**Migration errors:**
```bash
# Reset and re-run migrations (WARNING: deletes data)
python manage.py flush
python manage.py migrate
```

**Redis connection error:**
```bash
# Check Redis is running
redis-cli ping
# Should return: PONG
```

### Frontend Issues

**API connection refused:**
- Verify backend is running on port 8000
- Check API URL in `api_config.dart`
- For Android emulator: use `10.0.2.2:8000`
- For iOS simulator: use `localhost:8000`

**Flutter dependencies error:**
```bash
cd frontend
flutter clean
flutter pub get
```

---

## 📚 Next Steps

1. **Explore API:** Visit http://localhost:8000/api/docs
2. **Read Docs:** Check [QUICK_START.md](./QUICK_START.md) for more details
3. **Run Tests:** `pytest` (backend) or `flutter test` (frontend)
4. **Start Building:** Add features, customize UI

---

## 🎯 Quick Reference

```bash
# Backend
cd backend
python manage.py runserver          # Start server
python manage.py migrate            # Run migrations
python manage.py createsuperuser   # Create admin
pytest                              # Run tests

# Frontend
cd frontend
flutter run                         # Run app
flutter test                        # Run tests
flutter analyze                     # Check code

# Docker
cd backend/docker
docker-compose up                   # Start all services
docker-compose down                 # Stop services
```

---

**Need more help?** See [QUICK_START.md](./QUICK_START.md) for detailed instructions.

