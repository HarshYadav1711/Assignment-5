# Flutter Project Folder Structure

## Complete Directory Tree

```
lib/
│
├── core/                           # Core functionality (shared)
│   ├── config/
│   │   ├── app_config.dart        # App-wide configuration
│   │   └── api_config.dart        # API endpoints, base URL
│   │
│   ├── network/
│   │   ├── api_client.dart        # HTTP client (Dio)
│   │   ├── interceptors.dart      # Request/response interceptors
│   │   ├── websocket_client.dart  # WebSocket client
│   │   └── network_exception.dart  # Network error handling
│   │
│   ├── storage/
│   │   ├── local_db.dart          # SQLite/Hive database
│   │   ├── sync_queue.dart        # Offline sync queue
│   │   └── preferences.dart       # SharedPreferences wrapper
│   │
│   ├── utils/
│   │   ├── constants.dart         # App constants
│   │   ├── extensions.dart       # Dart extensions
│   │   ├── validators.dart        # Input validators
│   │   └── helpers.dart           # Helper functions
│   │
│   └── theme/
│       ├── app_theme.dart         # Theme configuration
│       ├── colors.dart           # Color palette
│       └── text_styles.dart      # Text styles
│
├── data/                           # Data layer
│   ├── models/                    # Data Transfer Objects (DTOs)
│   │   ├── user.dart
│   │   ├── trip.dart
│   │   ├── collaborator.dart
│   │   ├── itinerary.dart
│   │   ├── itinerary_item.dart
│   │   ├── poll.dart
│   │   ├── poll_option.dart
│   │   └── message.dart
│   │
│   ├── repositories/              # Repository implementations
│   │   ├── auth_repository.dart
│   │   ├── trip_repository.dart
│   │   ├── itinerary_repository.dart
│   │   ├── poll_repository.dart
│   │   └── chat_repository.dart
│   │
│   └── datasources/              # Data sources
│       ├── remote/               # API data sources
│       │   ├── auth_remote_ds.dart
│       │   ├── trip_remote_ds.dart
│       │   ├── itinerary_remote_ds.dart
│       │   ├── poll_remote_ds.dart
│       │   └── chat_remote_ds.dart
│       │
│       └── local/                # Local data sources
│           ├── trip_local_ds.dart
│           ├── itinerary_local_ds.dart
│           ├── poll_local_ds.dart
│           └── chat_local_ds.dart
│
├── domain/                         # Business logic (optional)
│   ├── entities/                  # Domain entities
│   │   ├── user_entity.dart
│   │   ├── trip_entity.dart
│   │   └── ...
│   │
│   └── usecases/                  # Use cases
│       ├── auth/
│       │   ├── login_usecase.dart
│       │   └── register_usecase.dart
│       └── sync/
│           └── sync_data_usecase.dart
│
├── features/                      # Feature modules (feature-first)
│   │
│   ├── auth/                      # Authentication feature
│   │   ├── bloc/
│   │   │   ├── auth_bloc.dart
│   │   │   ├── auth_event.dart
│   │   │   └── auth_state.dart
│   │   │
│   │   ├── pages/
│   │   │   ├── login_page.dart
│   │   │   └── register_page.dart
│   │   │
│   │   └── widgets/
│   │       ├── login_form.dart
│   │       └── register_form.dart
│   │
│   ├── trips/                     # Trip management feature
│   │   ├── bloc/
│   │   │   ├── trip_list_bloc.dart
│   │   │   ├── trip_list_event.dart
│   │   │   ├── trip_list_state.dart
│   │   │   ├── trip_detail_bloc.dart
│   │   │   ├── trip_detail_event.dart
│   │   │   └── trip_detail_state.dart
│   │   │
│   │   ├── pages/
│   │   │   ├── trip_list_page.dart
│   │   │   ├── trip_detail_page.dart
│   │   │   └── create_trip_page.dart
│   │   │
│   │   └── widgets/
│   │       ├── trip_card.dart
│   │       ├── trip_member_list.dart
│   │       └── invite_collaborator_dialog.dart
│   │
│   ├── itineraries/               # Itinerary feature
│   │   ├── bloc/
│   │   │   ├── itinerary_bloc.dart
│   │   │   ├── itinerary_event.dart
│   │   │   └── itinerary_state.dart
│   │   │
│   │   ├── pages/
│   │   │   ├── itinerary_page.dart
│   │   │   └── itinerary_item_edit_page.dart
│   │   │
│   │   └── widgets/
│   │       ├── itinerary_day_card.dart
│   │       ├── itinerary_item_tile.dart
│   │       └── reorderable_item_list.dart
│   │
│   ├── polls/                     # Polls feature
│   │   ├── bloc/
│   │   │   ├── poll_bloc.dart
│   │   │   ├── poll_event.dart
│   │   │   └── poll_state.dart
│   │   │
│   │   ├── pages/
│   │   │   ├── poll_list_page.dart
│   │   │   └── poll_detail_page.dart
│   │   │
│   │   └── widgets/
│   │       ├── poll_card.dart
│   │       ├── poll_option_tile.dart
│   │       └── vote_result_chart.dart
│   │
│   └── chat/                      # Chat feature
│       ├── bloc/
│       │   ├── chat_bloc.dart
│       │   ├── chat_event.dart
│       │   └── chat_state.dart
│       │
│       ├── pages/
│       │   └── chat_page.dart
│       │
│       └── widgets/
│           ├── message_bubble.dart
│           ├── message_input.dart
│           ├── message_list.dart
│           └── typing_indicator.dart
│
├── shared/                         # Shared components
│   ├── widgets/                   # Reusable widgets
│   │   ├── loading_indicator.dart
│   │   ├── error_widget.dart
│   │   ├── empty_state.dart
│   │   └── custom_button.dart
│   │
│   └── routing/                   # Navigation
│       ├── app_router.dart       # Route configuration
│       └── route_names.dart      # Route name constants
│
└── main.dart                       # App entry point
```

## Layer Responsibilities

### Core Layer
**Purpose**: Shared infrastructure and utilities

- **config/**: App and API configuration
- **network/**: HTTP client, WebSocket, interceptors
- **storage/**: Local database, sync queue, preferences
- **utils/**: Helpers, constants, extensions
- **theme/**: App theming and styling

### Data Layer
**Purpose**: Data access and transformation

- **models/**: DTOs (Data Transfer Objects) matching API responses
- **repositories/**: Data access abstraction (combines remote + local)
- **datasources/**: 
  - **remote/**: API calls
  - **local/**: Database operations

### Domain Layer (Optional)
**Purpose**: Business logic independent of data sources

- **entities/**: Pure business objects
- **usecases/**: Complex business operations

### Features Layer
**Purpose**: Feature-specific code organized by feature

Each feature contains:
- **bloc/**: State management (events, states, BLoC)
- **pages/**: Full-screen UI
- **widgets/**: Feature-specific reusable widgets

### Shared Layer
**Purpose**: Components used across multiple features

- **widgets/**: Reusable UI components
- **routing/**: Navigation configuration

---

## File Naming Conventions

- **BLoCs**: `{feature}_bloc.dart` (e.g., `trip_list_bloc.dart`)
- **Events**: `{feature}_event.dart` (e.g., `trip_list_event.dart`)
- **States**: `{feature}_state.dart` (e.g., `trip_list_state.dart`)
- **Pages**: `{feature}_page.dart` (e.g., `trip_list_page.dart`)
- **Widgets**: `{descriptive_name}.dart` (e.g., `trip_card.dart`)
- **Models**: Singular noun (e.g., `trip.dart`, `user.dart`)
- **Repositories**: `{feature}_repository.dart` (e.g., `trip_repository.dart`)

---

## Feature Module Structure

Each feature follows this structure:

```
feature_name/
├── bloc/              # State management
│   ├── {feature}_bloc.dart
│   ├── {feature}_event.dart
│   └── {feature}_state.dart
│
├── pages/             # Full-screen UI
│   └── {feature}_page.dart
│
└── widgets/           # Feature-specific widgets
    └── {widget_name}.dart
```

**Benefits:**
- Easy to locate feature code
- Clear boundaries between features
- Easy to extract to separate package if needed
- Better code organization

---

## Data Flow Example

### Loading Trip List

```
1. TripListPage (UI)
   ↓
2. BlocProvider.of<TripListBloc>(context).add(LoadTripListEvent())
   ↓
3. TripListBloc receives event
   ↓
4. TripListBloc.emit(TripListLoading())
   ↓
5. TripListPage shows loading indicator
   ↓
6. TripListBloc calls TripRepository.getTrips()
   ↓
7. TripRepository calls TripLocalDataSource.getTrips() (offline-first)
   ↓
8. TripRepository calls TripRemoteDataSource.getTrips() (sync)
   ↓
9. API returns JSON
   ↓
10. RemoteDataSource maps JSON to TripModel
   ↓
11. Repository saves to local DB
   ↓
12. Repository returns List<Trip>
   ↓
13. TripListBloc.emit(TripListLoaded(trips))
   ↓
14. TripListPage displays trip list
```

---

## BLoC Structure Example

### TripListBloc

```dart
// events/trip_list_event.dart
abstract class TripListEvent {}
class LoadTripListEvent extends TripListEvent {}
class RefreshTripListEvent extends TripListEvent {}

// states/trip_list_state.dart
abstract class TripListState {}
class TripListInitial extends TripListState {}
class TripListLoading extends TripListState {}
class TripListLoaded extends TripListState {
  final List<Trip> trips;
  TripListLoaded(this.trips);
}

// bloc/trip_list_bloc.dart
class TripListBloc extends Bloc<TripListEvent, TripListState> {
  final TripRepository repository;
  
  TripListBloc(this.repository) : super(TripListInitial()) {
    on<LoadTripListEvent>(_onLoadTripList);
  }
  
  Future<void> _onLoadTripList(...) async {
    emit(TripListLoading());
    final trips = await repository.getTrips();
    emit(TripListLoaded(trips));
  }
}
```

---

## Summary

### Key Principles

1. **Feature-First**: Code organized by feature, not by type
2. **Layer Separation**: Clear boundaries between UI, BLoC, and data
3. **Reusability**: Shared components in `core/` and `shared/`
4. **Testability**: BLoCs easily testable in isolation
5. **Scalability**: Easy to add new features

### Benefits

- ✅ **Maintainable**: Easy to find and modify code
- ✅ **Scalable**: Add features without affecting others
- ✅ **Testable**: Clear separation enables unit testing
- ✅ **Reusable**: Shared components reduce duplication
- ✅ **Organized**: Consistent structure across features

This structure provides a solid foundation for a production Flutter application.

