# Smart Trip Planner 🗺️

A production-ready collaborative trip planning platform that helps groups plan, organize, and coordinate their travels together. Built with Django and Flutter, featuring real-time chat, offline support, and seamless collaboration.

## What It Does

Planning a trip with friends? This app makes it easy. Create trips, invite collaborators, plan day-by-day itineraries, vote on activities, and chat in real-time—all while working offline when you need to.

### Key Features

- **Trip Management**: Create, share, and collaborate on trips with role-based permissions
- **Itinerary Planning**: Build day-by-day plans with drag-and-drop reordering
- **Group Decisions**: Create polls and vote on activities, restaurants, and destinations
- **Real-Time Chat**: WebSocket-based messaging per trip with typing indicators
- **Offline Support**: Full offline functionality with automatic sync when back online
- **Smart Sync**: Conflict resolution and optimistic updates for smooth UX

## Tech Stack

### Backend
- **Django 4.2** + **Django REST Framework** - Robust API foundation
- **PostgreSQL** - Production-grade database with optimized indexes
- **Django Channels** + **Redis** - Real-time WebSocket communication
- **JWT Authentication** - Secure, stateless token-based auth
- **Docker** - Containerized deployment ready

### Frontend
- **Flutter** - Cross-platform mobile app
- **BLoC Pattern** - Predictable state management
- **Hive** - Local storage for offline-first support
- **WebSocket** - Real-time chat with REST fallback

### Infrastructure
- **GitHub Actions** - Automated CI/CD pipelines
- **Docker** - Multi-stage production builds
- **Cloud-Ready** - HTTPS, managed databases, environment-based config

## Quick Start

### Option 1: Docker (Easiest - Recommended)

**Backend with Docker Compose:**

```bash
# Navigate to docker directory
cd backend/docker

# Start all services (PostgreSQL, Redis, Django)
docker-compose up --build

# In a NEW terminal, navigate to docker directory and run migrations
cd backend/docker
docker-compose exec web python manage.py migrate

# OR from project root, use -f flag:
# docker-compose -f backend/docker/docker-compose.yml exec web python manage.py migrate

# Create admin user
docker-compose exec web python manage.py createsuperuser
```

**Access:**
- API: http://localhost:8000
- Admin: http://localhost:8000/admin
- API Docs: http://localhost:8000/api/docs

### Option 2: Local Development

**Backend:**

```bash
cd backend

# 1. Create virtual environment
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate

# 2. Install dependencies
pip install -r requirements/development.txt

# 3. Set up PostgreSQL database
createdb trip_planner
# Or: psql -U postgres -c "CREATE DATABASE trip_planner;"

# 4. Create .env file (copy from .env.example if exists, or create manually)
# Add these variables:
# DJANGO_SECRET_KEY=your-secret-key
# DB_NAME=trip_planner
# DB_USER=postgres
# DB_PASSWORD=your-password
# DB_HOST=localhost
# DB_PORT=5432
# DJANGO_SETTINGS_MODULE=config.settings.development

# 5. Run migrations
python manage.py migrate

# 6. Create superuser
python manage.py createsuperuser

# 7. Start Redis (for WebSocket support)
# macOS: brew services start redis
# Linux: sudo systemctl start redis
# Or use Docker: docker run -d -p 6379:6379 redis:7-alpine

# 8. Start server
python manage.py runserver
```

**Frontend:**

```bash
cd frontend

# Install dependencies
flutter pub get

# Configure API endpoint in core/config/api_config.dart
# Set baseUrl to: http://localhost:8000
# For Android emulator: http://10.0.2.2:8000

# Run app
flutter run
```

**For detailed setup instructions, see [QUICK_START.md](./QUICK_START.md)**

## Project Structure

```
smart-trip-planner/
├── backend/              # Django REST API
│   ├── config/          # Project settings (dev/prod/test)
│   ├── users/           # Authentication & profiles
│   ├── trips/           # Trip management
│   ├── itineraries/     # Day-by-day planning
│   ├── polls/           # Voting system
│   └── chat/            # Real-time messaging
│
├── frontend/            # Flutter mobile app
│   ├── core/           # Shared utilities
│   ├── data/           # Data layer (repos, models)
│   ├── features/       # Feature modules (BLoC)
│   └── shared/         # Shared widgets
│
└── .github/workflows/   # CI/CD pipelines
```

## API Overview

### Authentication
```bash
POST /api/v1/auth/register/    # Register new user
POST /api/v1/auth/login/        # Get JWT tokens
POST /api/v1/auth/refresh/      # Refresh access token
```

### Trips
```bash
GET    /api/v1/trips/           # List user's trips
POST   /api/v1/trips/            # Create trip
GET    /api/v1/trips/{id}/       # Get trip details
PUT    /api/v1/trips/{id}/       # Update trip
DELETE /api/v1/trips/{id}/      # Delete trip
```

### Real-Time Chat
```bash
WebSocket: ws://api.example.com/ws/chat/{trip_id}/
```

See [API Documentation](./backend/API_DOCUMENTATION.md) for complete reference.

## Architecture Highlights

### Backend
- **Modular Design**: Feature-based Django apps with clear boundaries
- **Optimized Database**: Composite indexes for read-heavy workloads
- **Real-Time**: Django Channels with Redis for WebSocket scaling
- **Security**: JWT auth, rate limiting, CORS, HTTPS enforcement
- **Production-Ready**: Docker, environment configs, health checks

### Frontend
- **BLoC Pattern**: Predictable state management with clear data flow
- **Offline-First**: Local storage with sync queue and conflict resolution
- **Clean Architecture**: Separation of UI, business logic, and data layers
- **Modern UI**: Skeleton loaders, subtle animations, accessible design

## Documentation

- **[Quick Start Guide](./QUICK_START.md)** - Get running in minutes ⚡
- **[Architecture](./ARCHITECTURE.md)** - Complete system design
- **[API Docs](./backend/API_DOCUMENTATION.md)** - Endpoint reference
- **[Deployment Guide](./backend/DEPLOYMENT_CHECKLIST.md)** - Cloud deployment
- **[Flutter Architecture](./frontend/FLUTTER_ARCHITECTURE.md)** - Frontend design
- **[Testing Strategy](./frontend/TESTING_STRATEGY.md)** - Test approach

## Development

### Running Tests

**Backend:**
```bash
cd backend
pytest --cov=.
```

**Frontend:**
```bash
cd frontend
flutter test
```

### Code Quality

**Backend:**
```bash
black .           # Format code
isort .           # Sort imports
flake8 .          # Lint
mypy .            # Type check
```

**Frontend:**
```bash
flutter analyze   # Analyze code
dart format .     # Format code
```

## Deployment

The project is ready for cloud deployment with:
- ✅ Docker containerization
- ✅ Environment-based configuration
- ✅ HTTPS support
- ✅ Managed PostgreSQL integration
- ✅ CI/CD pipelines

See [Deployment Checklist](./backend/DEPLOYMENT_CHECKLIST.md) for detailed steps.

## Key Design Decisions

1. **UUID Primary Keys**: Security and distributed system compatibility
2. **Email-Based Auth**: Simpler UX, no username conflicts
3. **One Chat Room Per Trip**: Natural access control via trip membership
4. **Offline-First**: Better UX, works without connectivity
5. **BLoC Pattern**: Predictable state, easy testing

## Security

- JWT authentication with refresh tokens
- Rate limiting on authentication endpoints
- CORS strictly configured
- HTTPS enforced in production
- Input validation at multiple levels
- SQL injection protection (Django ORM)

## Performance

- Database indexes optimized for common queries
- Connection pooling for PostgreSQL
- Redis caching for sessions and rate limiting
- Optimistic UI updates for instant feedback
- Efficient WebSocket message broadcasting

## Contributing

1. Follow PEP 8 (backend) and Dart style guide (frontend)
2. Write tests for new features
3. Update documentation
4. Use meaningful commit messages

## License

[Your License Here]

---

**Built with ❤️ using Django, Flutter, and modern best practices**

For questions or issues, check the documentation or open an issue.
