# Smart Trip Planner - Django REST API

Production-ready Django REST API scaffold for a Smart Trip Planner application.

## 🏗️ Architecture Overview

This project follows a **modular, feature-based architecture** with clear separation of concerns:

- **Custom User Model**: Email-based authentication with UUID primary keys
- **JWT Authentication**: Token-based auth using `djangorestframework-simplejwt`
- **Environment-Based Settings**: Separate configs for dev/prod/test
- **Modular Apps**: Feature-based Django apps (users, trips, itineraries, polls, chat)
- **Dockerized**: Ready for containerized deployment
- **PostgreSQL**: Production-grade database support

## 📁 Project Structure

```
backend/
├── config/                 # Django project configuration
│   ├── settings/           # Environment-based settings
│   │   ├── base.py        # Shared settings
│   │   ├── development.py # Dev environment
│   │   ├── production.py  # Production environment
│   │   └── testing.py     # Test environment
│   ├── urls.py            # Root URL configuration
│   ├── wsgi.py            # WSGI application
│   └── asgi.py            # ASGI application (for WebSockets)
│
├── apps/
│   ├── users/             # Authentication & user profiles
│   ├── trips/             # Trip management
│   ├── itineraries/       # Day-by-day itinerary planning
│   ├── polls/             # Voting and decision-making
│   └── chat/              # Real-time messaging
│
├── common/                # Shared utilities
│   └── exceptions.py      # Custom exception handlers
│
├── middleware/            # Custom middleware (placeholders)
│   ├── jwt_auth.py       # JWT middleware (optional)
│   └── request_logging.py # Request logging (optional)
│
├── requirements/          # Python dependencies
│   ├── base.txt          # Core dependencies
│   ├── development.txt   # Dev dependencies
│   └── production.txt    # Production dependencies
│
└── docker/               # Docker configuration
    ├── Dockerfile        # Multi-stage production build
    └── docker-compose.yml # Local development setup
```

## 🚀 Quick Start

### Prerequisites

- Python 3.11+
- PostgreSQL 12+
- Docker & Docker Compose (optional)

### Local Development Setup

1. **Clone and navigate to backend:**
   ```bash
   cd backend
   ```

2. **Create virtual environment:**
   ```bash
   python -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   ```

3. **Install dependencies:**
   ```bash
   pip install -r requirements/development.txt
   ```

4. **Set up environment variables:**
   ```bash
   cp .env.example .env
   # Edit .env with your settings
   ```

5. **Set up PostgreSQL database:**
   ```bash
   # Create database
   createdb trip_planner
   ```

6. **Run migrations:**
   ```bash
   python manage.py migrate
   ```

7. **Create superuser:**
   ```bash
   python manage.py createsuperuser
   ```

8. **Run development server:**
   ```bash
   python manage.py runserver
   ```

### Docker Setup

1. **Build and start containers:**
   ```bash
   cd docker
   docker-compose up --build
   ```

2. **Run migrations:**
   ```bash
   docker-compose exec web python manage.py migrate
   ```

3. **Create superuser:**
   ```bash
   docker-compose exec web python manage.py createsuperuser
   ```

## 🔐 Authentication

### JWT Token Flow

1. **Register:**
   ```bash
   POST /api/v1/auth/register/
   {
     "email": "user@example.com",
     "password": "securepassword",
     "password_confirm": "securepassword",
     "first_name": "John",
     "last_name": "Doe"
   }
   ```

2. **Login:**
   ```bash
   POST /api/v1/auth/login/
   {
     "email": "user@example.com",
     "password": "securepassword"
   }
   ```

3. **Use token in requests:**
   ```bash
   Authorization: Bearer <access_token>
   ```

4. **Refresh token:**
   ```bash
   POST /api/v1/auth/refresh/
   {
     "refresh": "<refresh_token>"
   }
   ```

## 📡 API Endpoints

### Authentication
- `POST /api/v1/auth/register/` - User registration
- `POST /api/v1/auth/login/` - Login (get JWT tokens)
- `POST /api/v1/auth/refresh/` - Refresh access token
- `POST /api/v1/auth/logout/` - Logout (blacklist token)

### Users
- `GET /api/v1/users/me/` - Get current user profile
- `PUT /api/v1/users/me/` - Update current user profile

### Trips
- `GET /api/v1/trips/` - List trips (user is member of)
- `POST /api/v1/trips/` - Create trip
- `GET /api/v1/trips/{id}/` - Get trip details
- `PUT /api/v1/trips/{id}/` - Update trip
- `DELETE /api/v1/trips/{id}/` - Delete trip
- `GET /api/v1/trips/{id}/members/` - List trip members
- `POST /api/v1/trips/{id}/members/` - Add member
- `DELETE /api/v1/trips/{id}/members/` - Remove member

### Itineraries
- `GET /api/v1/itineraries/?trip_id={id}` - List itineraries
- `POST /api/v1/itineraries/` - Create itinerary
- `GET /api/v1/itineraries/{id}/` - Get itinerary
- `PUT /api/v1/itineraries/{id}/` - Update itinerary
- `DELETE /api/v1/itineraries/{id}/` - Delete itinerary

### Polls
- `GET /api/v1/polls/?trip_id={id}` - List polls
- `POST /api/v1/polls/` - Create poll
- `POST /api/v1/polls/{id}/vote/` - Vote for option
- `DELETE /api/v1/polls/{id}/vote/` - Remove vote

### Chat
- `GET /api/v1/chat/rooms/{id}/messages/` - Get message history
- `POST /api/v1/chat/messages/` - Create message (fallback)

## 🗄️ Database Models

### Users App
- **User**: Custom user model (email-based, UUID primary key)
- **Profile**: Extended user information (one-to-one with User)

### Trips App
- **Trip**: Main trip entity
- **TripMember**: Many-to-many relationship (user ↔ trip with roles)

### Itineraries App
- **Itinerary**: Day-by-day plan (belongs to trip)
- **ItineraryItem**: Individual activity/item within itinerary

### Polls App
- **Poll**: Poll question (belongs to trip)
- **PollOption**: Options within poll
- **PollVote**: User votes

### Chat App
- **ChatRoom**: One room per trip
- **Message**: Chat messages

## 🔧 Key Design Decisions

### 1. Custom User Model
**Why**: Email-based authentication, UUID primary keys for security and distributed systems.

**Implementation**: `users.models.User` extends `AbstractBaseUser` with email as `USERNAME_FIELD`.

### 2. Environment-Based Settings
**Why**: Different configurations for dev/prod/test without code changes.

**Structure**: `base.py` (shared) → `development.py` / `production.py` / `testing.py` (environment-specific).

### 3. JWT Authentication
**Why**: Stateless, scalable, mobile-friendly authentication.

**Library**: `djangorestframework-simplejwt` with access/refresh token pattern.

### 4. Modular App Structure
**Why**: Clear feature boundaries, easier maintenance, potential microservice extraction.

**Apps**: Each feature (users, trips, etc.) is a self-contained Django app.

### 5. UUID Primary Keys
**Why**: Security (no enumeration), distributed system compatibility, offline ID generation.

**Trade-off**: Slightly larger than integers, but benefits outweigh costs.

### 6. One Chat Room Per Trip
**Why**: Simplifies access control (inherits from trip membership), natural UX.

**Alternative Considered**: Multiple rooms per trip - rejected for complexity.

## 🧪 Testing

```bash
# Run tests
pytest

# With coverage
pytest --cov=.

# Specific app
pytest apps/trips/
```

## 📝 Code Quality

```bash
# Format code
black .

# Sort imports
isort .

# Lint
flake8 .

# Type check
mypy .
```

## 🐳 Docker

### Development
```bash
cd docker
docker-compose up
```

### Production Build
```bash
docker build -f docker/Dockerfile -t trip-planner-api .
docker run -p 8000:8000 trip-planner-api
```

## 🔒 Security Considerations

1. **Never commit `.env` files** - Use `.env.example` as template
2. **Use strong `DJANGO_SECRET_KEY`** in production
3. **Enable HTTPS** in production (`SECURE_SSL_REDIRECT=True`)
4. **Set `ALLOWED_HOSTS`** properly in production
5. **Use environment variables** for all secrets
6. **Regular dependency updates** - Check for security vulnerabilities

## 📚 Next Steps

1. **Run migrations** to create database tables
2. **Create superuser** for admin access
3. **Test API endpoints** using Postman/curl
4. **Implement WebSocket consumers** for real-time chat (Django Channels)
5. **Add offline sync endpoints** if needed
6. **Set up CI/CD** pipeline
7. **Configure production deployment**

## 🤝 Contributing

1. Follow PEP 8 style guide
2. Write tests for new features
3. Update documentation
4. Use meaningful commit messages

## 📄 License

[Your License Here]

---

**Built with Django 4.2 and Django REST Framework 3.14**

