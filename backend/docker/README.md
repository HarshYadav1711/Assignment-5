# Docker Setup

This directory contains the Docker Compose configuration for running the Smart Trip Planner backend.

## Quick Start

```bash
# From this directory (backend/docker)
docker-compose up --build
```

## Important: Running Commands

**All `docker-compose` commands must be run from this directory (`backend/docker`):**

```bash
# Make sure you're in the right directory
cd backend/docker

# Then run commands
docker-compose exec web python manage.py migrate
docker-compose exec web python manage.py createsuperuser
docker-compose exec web python manage.py shell
```

**OR from project root, use the `-f` flag:**

```bash
# From project root (D:\Fun\Assignment 5)
docker-compose -f backend/docker/docker-compose.yml exec web python manage.py migrate
docker-compose -f backend/docker/docker-compose.yml exec web python manage.py createsuperuser
```

## Services

- **db**: PostgreSQL 15 database
- **redis**: Redis 7 for WebSocket support
- **web**: Django application

## Default Configuration

The compose file uses sensible defaults. No `.env` file is required, but you can create one in `backend/.env` to override:

- `DB_NAME` (default: `trip_planner`)
- `DB_USER` (default: `postgres`)
- `DB_PASSWORD` (default: `postgres`)
- `DJANGO_SECRET_KEY` (default: `django-insecure-change-in-production`)

## Common Commands

```bash
# Start services
docker-compose up --build

# Start in background
docker-compose up -d

# View logs
docker-compose logs -f

# Stop services
docker-compose down

# Stop and remove volumes (WARNING: deletes database)
docker-compose down -v

# Run migrations
docker-compose exec web python manage.py migrate

# Create superuser
docker-compose exec web python manage.py createsuperuser

# Access Django shell
docker-compose exec web python manage.py shell

# Run tests
docker-compose exec web pytest
```

