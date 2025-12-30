# Smart Trip Planner - Flutter Frontend

## Architecture Overview

Flutter application using BLoC pattern for state management, organized in a feature-first structure for scalability and maintainability.

## Architecture

- **Pattern**: BLoC (Business Logic Component)
- **Structure**: Feature-first organization
- **State Management**: flutter_bloc package
- **Networking**: Dio for HTTP, WebSocket for real-time chat
- **Local Storage**: Hive/Drift for offline-first support
- **Navigation**: GoRouter or Navigator 2.0

## Project Structure

```
lib/
├── core/           # Shared utilities, network, storage
├── data/            # Data layer (models, repositories, data sources)
├── domain/          # Business logic (entities, use cases)
├── features/        # Feature modules (auth, trips, itineraries, polls, chat)
├── shared/          # Shared widgets and routing
└── main.dart        # App entry point
```

## Features

1. **Authentication**: Login, register, JWT token management
2. **Trip Management**: List, create, update, delete trips
3. **Itinerary Planning**: Day-by-day planning with drag-and-drop reordering
4. **Polls**: Create polls, vote, view results
5. **Real-Time Chat**: WebSocket-based chat with REST fallback

## Data Flow

```
UI → Event → BLoC → Repository → Data Source → API/DB
                ↓
            State → UI
```

## BLoC Lifecycle

1. **Initialization**: BLoC created, handlers registered
2. **Event Processing**: Events processed, states emitted
3. **State Emission**: UI rebuilds based on state
4. **Cleanup**: Resources freed when BLoC closed

## Documentation

- **Architecture**: `FLUTTER_ARCHITECTURE.md` - Complete architecture overview
- **BLoC Lifecycle**: `BLOC_LIFECYCLE.md` - Detailed BLoC lifecycle and data flow
- **Feature Implementation**: `FEATURE_IMPLEMENTATION.md` - Feature-specific implementation guides

## Key Design Decisions

1. **Feature-First Structure**: Code organized by feature for better maintainability
2. **BLoC Pattern**: Predictable state management
3. **Repository Pattern**: Abstracts data sources for offline-first support
4. **Optimistic Updates**: Better UX with immediate feedback
5. **Offline-First**: Works without network connection

## Getting Started

1. Install dependencies: `flutter pub get`
2. Configure API endpoint in `core/config/api_config.dart`
3. Run app: `flutter run`

## Testing

- **BLoC Tests**: Unit tests for business logic
- **Widget Tests**: UI component tests
- **Integration Tests**: End-to-end feature tests

---

For detailed implementation guides, see the documentation files in this directory.

