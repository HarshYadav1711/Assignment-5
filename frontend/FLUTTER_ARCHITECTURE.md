# Flutter App Architecture - BLoC Pattern

## Overview

This document describes the Flutter application architecture for the Smart Trip Planner, using the BLoC (Business Logic Component) pattern for state management.

### Architecture Principles

1. **Separation of Concerns**: Clear boundaries between UI, business logic, and data
2. **Feature-First Structure**: Organize code by features, not by type
3. **Scalable State Management**: BLoC pattern for predictable state updates
4. **Testability**: BLoCs are easily testable in isolation
5. **Reusability**: Shared components and utilities across features

---

## Architecture Layers

### 1. Presentation Layer (UI)
- **Widgets**: Reusable UI components
- **Pages**: Feature-specific screens
- **BLoC Consumers**: Connect UI to state

### 2. Business Logic Layer (BLoC)
- **Events**: User actions and system events
- **States**: UI state representations
- **BLoCs**: State management logic

### 3. Data Layer
- **Repositories**: Data access abstraction
- **Data Sources**: Remote (API) and Local (database)
- **Models**: Data transfer objects

### 4. Core Layer
- **Network**: API client, interceptors
- **Storage**: Local database, preferences
- **Utils**: Helpers, constants, extensions

---

## Folder Structure

```
lib/
├── core/                          # Core functionality (shared across features)
│   ├── config/                    # App configuration
│   │   ├── app_config.dart       # App-wide configuration
│   │   └── api_config.dart        # API endpoints, base URL
│   │
│   ├── network/                   # Network layer
│   │   ├── api_client.dart       # HTTP client (Dio)
│   │   ├── interceptors.dart    # Request/response interceptors
│   │   ├── websocket_client.dart # WebSocket client
│   │   └── network_exception.dart # Network error handling
│   │
│   ├── storage/                  # Local storage
│   │   ├── local_db.dart         # SQLite/Hive database
│   │   ├── sync_queue.dart       # Offline sync queue
│   │   └── preferences.dart     # SharedPreferences wrapper
│   │
│   ├── utils/                     # Utilities
│   │   ├── constants.dart        # App constants
│   │   ├── extensions.dart       # Dart extensions
│   │   ├── validators.dart       # Input validators
│   │   └── helpers.dart          # Helper functions
│   │
│   └── theme/                     # App theming
│       ├── app_theme.dart        # Theme configuration
│       ├── colors.dart           # Color palette
│       └── text_styles.dart      # Text styles
│
├── data/                          # Data layer (shared)
│   ├── models/                   # Data models (DTOs)
│   │   ├── user.dart
│   │   ├── trip.dart
│   │   ├── itinerary.dart
│   │   ├── poll.dart
│   │   └── message.dart
│   │
│   ├── repositories/             # Repository interfaces
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
├── domain/                        # Business logic (shared)
│   ├── entities/                 # Domain entities
│   │   ├── user_entity.dart
│   │   ├── trip_entity.dart
│   │   └── ...
│   │
│   └── usecases/                 # Use cases (optional - for complex logic)
│       ├── auth/
│       │   ├── login_usecase.dart
│       │   └── register_usecase.dart
│       └── sync/
│           └── sync_data_usecase.dart
│
├── features/                      # Feature modules (feature-first)
│   │
│   ├── auth/                     # Authentication feature
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
│           ├── typing_indicator.dart
│           └── message_list.dart
│
├── shared/                        # Shared components
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
└── main.dart                      # App entry point
```

---

## Data Flow

### Request Flow (User Action → API)

```
1. User Action (UI)
   ↓
2. Event dispatched to BLoC
   ↓
3. BLoC processes event
   ↓
4. BLoC calls Repository
   ↓
5. Repository calls Data Source (Remote/Local)
   ↓
6. Data Source makes API call or reads from DB
   ↓
7. Response flows back up
   ↓
8. Repository maps to Entity/Model
   ↓
9. BLoC emits new State
   ↓
10. UI rebuilds based on new State
```

### Example: Loading Trip List

```
1. User opens Trip List Page
   ↓
2. TripListPage dispatches LoadTripListEvent
   ↓
3. TripListBloc receives event
   ↓
4. TripListBloc emits LoadingState
   ↓
5. UI shows loading indicator
   ↓
6. TripListBloc calls TripRepository.getTrips()
   ↓
7. TripRepository checks local DB first (offline-first)
   ↓
8. TripRepository calls TripRemoteDataSource.getTrips()
   ↓
9. API returns JSON
   ↓
10. RemoteDataSource maps JSON to TripModel
   ↓
11. Repository saves to local DB
   ↓
12. Repository returns List<Trip>
   ↓
13. TripListBloc emits LoadedState(trips)
   ↓
14. UI displays trip list
```

---

## BLoC Lifecycle

### BLoC Component Structure

Each BLoC consists of three parts:

1. **Event**: Represents user actions or system events
2. **State**: Represents UI state at a point in time
3. **BLoC**: Processes events and emits states

### Example: TripListBloc Lifecycle

```dart
// 1. Event Definition
abstract class TripListEvent {}
class LoadTripListEvent extends TripListEvent {}
class RefreshTripListEvent extends TripListEvent {}
class DeleteTripEvent extends TripListEvent {
  final String tripId;
  DeleteTripEvent(this.tripId);
}

// 2. State Definition
abstract class TripListState {}
class TripListInitial extends TripListState {}
class TripListLoading extends TripListState {}
class TripListLoaded extends TripListState {
  final List<Trip> trips;
  TripListLoaded(this.trips);
}
class TripListError extends TripListState {
  final String message;
  TripListError(this.message);
}

// 3. BLoC Implementation
class TripListBloc extends Bloc<TripListEvent, TripListState> {
  final TripRepository repository;
  
  TripListBloc(this.repository) : super(TripListInitial()) {
    // Register event handlers
    on<LoadTripListEvent>(_onLoadTripList);
    on<RefreshTripListEvent>(_onRefreshTripList);
    on<DeleteTripEvent>(_onDeleteTrip);
  }
  
  Future<void> _onLoadTripList(
    LoadTripListEvent event,
    Emitter<TripListState> emit,
  ) async {
    emit(TripListLoading());  // 1. Emit loading state
    
    try {
      final trips = await repository.getTrips();  // 2. Fetch data
      emit(TripListLoaded(trips));  // 3. Emit loaded state
    } catch (e) {
      emit(TripListError(e.toString()));  // 4. Emit error state
    }
  }
  
  // ... other handlers
}
```

### BLoC Lifecycle Stages

1. **Initialization**
   - BLoC created with initial state
   - Event handlers registered
   - Dependencies injected

2. **Event Processing**
   - Event dispatched to BLoC
   - BLoC processes event
   - May emit multiple states (loading → loaded)

3. **State Emission**
   - BLoC emits new state
   - UI listens and rebuilds
   - State persists until next event

4. **Cleanup**
   - BLoC closed when no longer needed
   - Resources freed
   - Streams closed

---

## Feature Implementation Details

### 1. Auth Feature

**BLoC:** `AuthBloc`
- **Events**: LoginEvent, RegisterEvent, LogoutEvent, CheckAuthEvent
- **States**: AuthInitial, AuthLoading, Authenticated, Unauthenticated, AuthError
- **Repository**: AuthRepository (handles token storage)

**Flow:**
```
LoginEvent → AuthBloc → AuthRepository → API
  ↓
Token received → Save to storage → Emit Authenticated
  ↓
UI navigates to home
```

### 2. Trip List & Details

**BLoCs:**
- `TripListBloc`: Manages trip list
- `TripDetailBloc`: Manages single trip details

**TripListBloc:**
- Loads user's trips
- Handles pull-to-refresh
- Optimistic updates for create/delete

**TripDetailBloc:**
- Loads trip details
- Manages collaborators
- Handles invitations

### 3. Itinerary with Drag-and-Drop

**BLoC:** `ItineraryBloc`
- **Events**: LoadItineraryEvent, ReorderItemsEvent, AddItemEvent, UpdateItemEvent
- **States**: ItineraryLoading, ItineraryLoaded, ItineraryError

**Drag-and-Drop Flow:**
```
1. User drags item → ReorderItemsEvent(itemIds)
2. BLoC emits LoadingState
3. BLoC updates local state immediately (optimistic)
4. BLoC calls API to persist reorder
5. On success: Emit LoadedState
6. On failure: Revert to previous state, emit ErrorState
```

**Implementation:**
- Use `ReorderableListView` widget
- Optimistic UI updates
- Sync with backend on drop

### 4. Polls

**BLoC:** `PollBloc`
- **Events**: LoadPollsEvent, VoteEvent, CreatePollEvent
- **States**: PollLoading, PollsLoaded, VoteSuccess, VoteError

**Voting Flow:**
```
1. User taps vote → VoteEvent(optionId)
2. BLoC emits LoadingState
3. BLoC updates UI optimistically (shows vote)
4. BLoC calls API
5. On success: Emit VoteSuccess
6. On failure: Revert UI, emit VoteError
```

### 5. Chat UI

**BLoC:** `ChatBloc`
- **Events**: ConnectEvent, SendMessageEvent, LoadHistoryEvent, TypingEvent
- **States**: ChatConnecting, ChatConnected, ChatDisconnected, MessagesLoaded

**WebSocket Flow:**
```
1. User opens chat → ConnectEvent
2. BLoC connects to WebSocket
3. BLoC receives messages → Emit MessagesLoaded
4. User sends message → SendMessageEvent
5. BLoC sends via WebSocket
6. BLoC receives broadcast → Emit MessageReceived
7. UI updates message list
```

**Fallback:**
- If WebSocket fails → Use REST API
- Poll for new messages
- Show connection status

---

## State Management Patterns

### 1. Optimistic Updates

**Pattern:** Update UI immediately, sync with backend

**Example:**
```dart
Future<void> _onDeleteTrip(
  DeleteTripEvent event,
  Emitter<TripListState> emit,
) async {
  // 1. Optimistic update
  if (state is TripListLoaded) {
    final updatedTrips = (state as TripListLoaded)
        .trips
        .where((t) => t.id != event.tripId)
        .toList();
    emit(TripListLoaded(updatedTrips));  // UI updates immediately
  }
  
  // 2. Sync with backend
  try {
    await repository.deleteTrip(event.tripId);
    // Success - state already updated
  } catch (e) {
    // Failure - revert to previous state
    emit(TripListError('Failed to delete trip'));
    // Reload from server
    add(LoadTripListEvent());
  }
}
```

### 2. Offline-First

**Pattern:** Load from local DB first, sync with server

**Example:**
```dart
Future<List<Trip>> getTrips() async {
  // 1. Load from local DB (fast)
  final localTrips = await localDataSource.getTrips();
  
  // 2. Try to sync with server
  try {
    final remoteTrips = await remoteDataSource.getTrips();
    // 3. Update local DB
    await localDataSource.saveTrips(remoteTrips);
    return remoteTrips;
  } catch (e) {
    // 4. If offline, return local data
    return localTrips;
  }
}
```

### 3. Error Handling

**Pattern:** Consistent error states across BLoCs

**Example:**
```dart
class TripListError extends TripListState {
  final String message;
  final String? code;  // Error code for specific handling
  final bool retryable;  // Can user retry?
  
  TripListError(this.message, {this.code, this.retryable = true});
}
```

---

## Testing Strategy

### BLoC Testing

**Unit Tests:**
```dart
test('emits [Loading, Loaded] when LoadTripListEvent is added', () {
  // Arrange
  final mockRepository = MockTripRepository();
  final bloc = TripListBloc(mockRepository);
  
  when(mockRepository.getTrips())
      .thenAnswer((_) async => [trip1, trip2]);
  
  // Act & Assert
  expect(
    bloc.stream,
    emitsInOrder([
      TripListLoading(),
      TripListLoaded([trip1, trip2]),
    ]),
  );
  
  bloc.add(LoadTripListEvent());
});
```

### Widget Testing

**Test UI with BLoC:**
```dart
testWidgets('displays trip list when loaded', (tester) async {
  // Arrange
  final bloc = MockTripListBloc();
  when(bloc.state).thenReturn(TripListLoaded([trip1, trip2]));
  
  // Act
  await tester.pumpWidget(
    BlocProvider.value(
      value: bloc,
      child: TripListPage(),
    ),
  );
  
  // Assert
  expect(find.text('Trip 1'), findsOneWidget);
  expect(find.text('Trip 2'), findsOneWidget);
});
```

---

## Dependency Injection

### BLoC Provider Setup

```dart
// main.dart
void main() {
  // Initialize dependencies
  final apiClient = ApiClient();
  final localDb = LocalDatabase();
  
  // Create repositories
  final authRepo = AuthRepository(
    remoteDataSource: AuthRemoteDataSource(apiClient),
    localDataSource: AuthLocalDataSource(localDb),
  );
  
  final tripRepo = TripRepository(
    remoteDataSource: TripRemoteDataSource(apiClient),
    localDataSource: TripLocalDataSource(localDb),
  );
  
  // Provide BLoCs
  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => AuthBloc(authRepo)),
        BlocProvider(create: (_) => TripListBloc(tripRepo)),
      ],
      child: MyApp(),
    ),
  );
}
```

---

## Navigation

### Route-Based Navigation

```dart
// app_router.dart
class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case RouteNames.login:
        return MaterialPageRoute(builder: (_) => LoginPage());
      case RouteNames.tripList:
        return MaterialPageRoute(builder: (_) => TripListPage());
      case RouteNames.tripDetail:
        final tripId = settings.arguments as String;
        return MaterialPageRoute(
          builder: (_) => TripDetailPage(tripId: tripId),
        );
      // ... other routes
    }
  }
}
```

---

## Summary

### Key Architecture Decisions

1. **Feature-First Structure**: Code organized by feature for better maintainability
2. **BLoC Pattern**: Predictable state management with clear separation
3. **Repository Pattern**: Abstracts data sources for offline-first support
4. **Optimistic Updates**: Better UX with immediate feedback
5. **Testability**: BLoCs are easily testable in isolation

### Benefits

- ✅ **Scalable**: Easy to add new features
- ✅ **Testable**: BLoCs can be tested without UI
- ✅ **Maintainable**: Clear structure and separation of concerns
- ✅ **Reusable**: Shared components and utilities
- ✅ **Offline-First**: Works without network connection

This architecture provides a solid foundation for a production Flutter application with clear separation of concerns and scalable state management.

