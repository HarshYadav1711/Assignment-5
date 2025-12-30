# Smart Trip Planner - Folder Structure

## Complete Project Structure

```
smart-trip-planner/
│
├── backend/                          # Django Backend
│   ├── config/                       # Project configuration
│   │   ├── __init__.py
│   │   ├── settings/
│   │   │   ├── __init__.py
│   │   │   ├── base.py              # Base settings (shared)
│   │   │   ├── development.py       # Dev environment
│   │   │   ├── production.py        # Production environment
│   │   │   └── testing.py           # Test environment
│   │   ├── urls.py                  # Root URL configuration
│   │   ├── wsgi.py                  # WSGI entry point
│   │   └── asgi.py                  # ASGI entry point (WebSockets)
│   │
│   ├── apps/                         # Django applications
│   │   ├── __init__.py
│   │   │
│   │   ├── accounts/                # User authentication & profiles
│   │   │   ├── __init__.py
│   │   │   ├── models.py            # User, Profile models
│   │   │   ├── serializers.py       # User serializers
│   │   │   ├── views.py             # Auth views
│   │   │   ├── permissions.py       # Custom permissions
│   │   │   ├── urls.py              # Account endpoints
│   │   │   ├── admin.py             # Django admin config
│   │   │   ├── migrations/          # Database migrations
│   │   │   │   └── __init__.py
│   │   │   └── tests/               # Account tests
│   │   │       ├── __init__.py
│   │   │       ├── test_models.py
│   │   │       ├── test_views.py
│   │   │       └── test_permissions.py
│   │   │
│   │   ├── trips/                   # Core trip management
│   │   │   ├── __init__.py
│   │   │   ├── models.py            # Trip, Destination, Activity
│   │   │   ├── serializers.py       # Trip serializers
│   │   │   ├── views.py             # Trip CRUD views
│   │   │   ├── permissions.py       # Trip access permissions
│   │   │   ├── urls.py              # Trip endpoints
│   │   │   ├── admin.py
│   │   │   ├── migrations/
│   │   │   │   └── __init__.py
│   │   │   └── tests/
│   │   │       ├── __init__.py
│   │   │       ├── test_models.py
│   │   │       ├── test_views.py
│   │   │       └── test_permissions.py
│   │   │
│   │   ├── chat/                    # Real-time chat
│   │   │   ├── __init__.py
│   │   │   ├── models.py            # Message, ChatRoom
│   │   │   ├── serializers.py       # Message serializers
│   │   │   ├── consumers.py         # WebSocket consumers
│   │   │   ├── routing.py           # WebSocket routing
│   │   │   ├── urls.py              # Chat REST endpoints
│   │   │   ├── admin.py
│   │   │   ├── migrations/
│   │   │   │   └── __init__.py
│   │   │   └── tests/
│   │   │       ├── __init__.py
│   │   │       ├── test_consumers.py
│   │   │       └── test_models.py
│   │   │
│   │   ├── sync/                    # Offline sync
│   │   │   ├── __init__.py
│   │   │   ├── models.py            # SyncLog, ConflictResolution
│   │   │   ├── serializers.py       # Sync serializers
│   │   │   ├── views.py             # Sync endpoints
│   │   │   ├── sync_handler.py      # Sync logic
│   │   │   ├── conflict_resolver.py # Conflict resolution
│   │   │   ├── urls.py
│   │   │   ├── admin.py
│   │   │   ├── migrations/
│   │   │   │   └── __init__.py
│   │   │   └── tests/
│   │   │       ├── __init__.py
│   │   │       └── test_sync.py
│   │   │
│   │   └── notifications/           # Push notifications
│   │       ├── __init__.py
│   │       ├── models.py            # Notification
│   │       ├── serializers.py
│   │       ├── views.py
│   │       ├── signals.py           # Django signals
│   │       ├── urls.py
│   │       ├── admin.py
│   │       ├── migrations/
│   │       │   └── __init__.py
│   │       └── tests/
│   │           ├── __init__.py
│   │           └── test_notifications.py
│   │
│   ├── common/                      # Shared utilities
│   │   ├── __init__.py
│   │   ├── exceptions.py            # Custom exceptions
│   │   ├── pagination.py            # Custom pagination
│   │   ├── permissions.py           # Base permissions
│   │   ├── mixins.py                # Reusable mixins
│   │   ├── utils.py                 # Utility functions
│   │   └── validators.py            # Custom validators
│   │
│   ├── middleware/                  # Custom middleware
│   │   ├── __init__.py
│   │   ├── jwt_auth.py              # JWT authentication
│   │   └── request_logging.py      # Request logging
│   │
│   ├── requirements/                # Python dependencies
│   │   ├── base.txt                 # Core dependencies
│   │   ├── development.txt          # Dev dependencies
│   │   └── production.txt           # Production dependencies
│   │
│   ├── docker/                      # Docker configuration
│   │   ├── Dockerfile               # Backend Dockerfile
│   │   ├── Dockerfile.dev           # Development Dockerfile
│   │   ├── docker-compose.yml       # Local development
│   │   ├── docker-compose.prod.yml  # Production setup
│   │   └── .dockerignore
│   │
│   ├── tests/                       # Integration tests
│   │   ├── __init__.py
│   │   ├── conftest.py              # Pytest configuration
│   │   ├── test_accounts.py
│   │   ├── test_trips.py
│   │   ├── test_chat.py
│   │   └── test_sync.py
│   │
│   ├── scripts/                     # Utility scripts
│   │   ├── setup_db.sh              # Database setup
│   │   ├── run_migrations.sh        # Migration runner
│   │   └── seed_data.py             # Seed test data
│   │
│   ├── manage.py                    # Django management script
│   ├── .env.example                 # Environment variables template
│   ├── .gitignore
│   ├── README.md
│   └── pyproject.toml               # Python project config
│
├── frontend/                         # Flutter Frontend
│   ├── android/                     # Android-specific files
│   ├── ios/                         # iOS-specific files
│   ├── lib/
│   │   ├── main.dart                # App entry point
│   │   │
│   │   ├── core/                    # Core functionality
│   │   │   ├── config/              # App configuration
│   │   │   │   ├── app_config.dart
│   │   │   │   └── api_config.dart
│   │   │   ├── network/             # Network layer
│   │   │   │   ├── api_client.dart
│   │   │   │   ├── websocket_client.dart
│   │   │   │   └── interceptors.dart
│   │   │   ├── storage/             # Local storage
│   │   │   │   ├── local_db.dart    # SQLite/Hive
│   │   │   │   ├── sync_queue.dart  # Sync queue
│   │   │   │   └── preferences.dart # SharedPreferences
│   │   │   └── utils/               # Utilities
│   │   │       ├── constants.dart
│   │   │       └── helpers.dart
│   │   │
│   │   ├── data/                    # Data layer
│   │   │   ├── models/              # Data models
│   │   │   │   ├── user.dart
│   │   │   │   ├── trip.dart
│   │   │   │   ├── destination.dart
│   │   │   │   ├── activity.dart
│   │   │   │   ├── message.dart
│   │   │   │   └── notification.dart
│   │   │   ├── repositories/        # Repository pattern
│   │   │   │   ├── user_repository.dart
│   │   │   │   ├── trip_repository.dart
│   │   │   │   ├── destination_repository.dart
│   │   │   │   ├── activity_repository.dart
│   │   │   │   ├── chat_repository.dart
│   │   │   │   └── sync_repository.dart
│   │   │   └── datasources/         # Data sources
│   │   │       ├── remote/          # API data sources
│   │   │       │   ├── trip_remote_ds.dart
│   │   │       │   └── chat_remote_ds.dart
│   │   │       └── local/           # Local data sources
│   │   │           ├── trip_local_ds.dart
│   │   │           └── chat_local_ds.dart
│   │   │
│   │   ├── domain/                  # Business logic
│   │   │   ├── entities/            # Domain entities
│   │   │   │   ├── user_entity.dart
│   │   │   │   ├── trip_entity.dart
│   │   │   │   └── ...
│   │   │   └── usecases/            # Use cases
│   │   │       ├── auth/
│   │   │       │   ├── login_usecase.dart
│   │   │       │   └── register_usecase.dart
│   │   │       ├── trips/
│   │   │       │   ├── create_trip_usecase.dart
│   │   │       │   └── get_trips_usecase.dart
│   │   │       └── sync/
│   │   │           └── sync_data_usecase.dart
│   │   │
│   │   ├── presentation/            # UI layer (BLoC)
│   │   │   ├── bloc/                # BLoC components
│   │   │   │   ├── auth/
│   │   │   │   │   ├── auth_bloc.dart
│   │   │   │   │   ├── auth_event.dart
│   │   │   │   │   └── auth_state.dart
│   │   │   │   ├── trips/
│   │   │   │   │   ├── trip_bloc.dart
│   │   │   │   │   ├── trip_event.dart
│   │   │   │   │   └── trip_state.dart
│   │   │   │   ├── chat/
│   │   │   │   │   ├── chat_bloc.dart
│   │   │   │   │   ├── chat_event.dart
│   │   │   │   │   └── chat_state.dart
│   │   │   │   └── sync/
│   │   │   │       ├── sync_bloc.dart
│   │   │   │       ├── sync_event.dart
│   │   │   │       └── sync_state.dart
│   │   │   └── pages/               # UI pages
│   │   │       ├── auth/
│   │   │       │   ├── login_page.dart
│   │   │       │   └── register_page.dart
│   │   │       ├── trips/
│   │   │       │   ├── trip_list_page.dart
│   │   │       │   ├── trip_detail_page.dart
│   │   │       │   └── create_trip_page.dart
│   │   │       ├── chat/
│   │   │       │   └── chat_page.dart
│   │   │       └── sync/
│   │   │           └── sync_status_page.dart
│   │   │
│   │   └── widgets/                 # Reusable widgets
│   │       ├── common/
│   │       │   ├── loading_widget.dart
│   │       │   └── error_widget.dart
│   │       └── trips/
│   │           └── trip_card.dart
│   │
│   ├── test/                        # Flutter tests
│   │   ├── unit/
│   │   ├── widget/
│   │   └── integration/
│   │
│   ├── pubspec.yaml                 # Flutter dependencies
│   ├── .gitignore
│   └── README.md
│
├── .github/                         # GitHub configuration
│   └── workflows/                   # GitHub Actions
│       ├── pr.yml                   # PR workflow
│       ├── main.yml                 # Main branch workflow
│       └── release.yml              # Release workflow
│
├── docs/                            # Documentation
│   ├── api/                         # API documentation
│   │   └── api_spec.md
│   ├── deployment/                  # Deployment guides
│   │   └── deployment_guide.md
│   └── development/                 # Development guides
│       └── setup_guide.md
│
├── ARCHITECTURE.md                  # This architecture document
├── FOLDER_STRUCTURE.md              # This file
├── README.md                        # Project README
└── .gitignore                       # Root gitignore
```

## Key Directory Explanations

### Backend Structure

**`config/`**: Centralized Django settings
- Split by environment for security and flexibility
- Base settings shared across all environments

**`apps/`**: Feature-based Django applications
- Each app is self-contained with models, views, serializers
- Follows Django's app pattern for modularity

**`common/`**: Shared utilities across apps
- Reusable code to avoid duplication
- Base classes and mixins

**`middleware/`**: Request/response processing
- JWT authentication middleware
- Request logging for debugging

### Frontend Structure

**`lib/core/`**: Foundation layer
- Configuration, networking, storage
- No business logic

**`lib/data/`**: Data access layer
- Models, repositories, data sources
- Handles API and local storage

**`lib/domain/`**: Business logic layer
- Entities and use cases
- Platform-independent logic

**`lib/presentation/`**: UI layer
- BLoC pattern for state management
- Pages and widgets

### CI/CD Structure

**`.github/workflows/`**: Automated pipelines
- Separate workflows for different triggers
- PR checks, staging deployment, production release

## File Naming Conventions

- **Python**: `snake_case.py`
- **Dart**: `snake_case.dart`
- **Models**: Singular noun (e.g., `trip.dart`, `user.dart`)
- **Views/Pages**: Descriptive with suffix (e.g., `trip_list_page.dart`)
- **BLoC**: Feature name + `_bloc.dart` (e.g., `trip_bloc.dart`)

