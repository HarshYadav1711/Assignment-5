# BLoC Lifecycle and Data Flow

## BLoC Lifecycle Overview

A BLoC (Business Logic Component) manages state through a predictable lifecycle:

```
Initialization → Event Processing → State Emission → Cleanup
```

---

## Detailed Lifecycle Stages

### 1. Initialization

**When:** BLoC is created

**What Happens:**
```dart
class TripListBloc extends Bloc<TripListEvent, TripListState> {
  final TripRepository repository;
  
  TripListBloc(this.repository) : super(TripListInitial()) {
    // 1. Set initial state
    // 2. Register event handlers
    on<LoadTripListEvent>(_onLoadTripList);
    on<RefreshTripListEvent>(_onRefreshTripList);
    on<DeleteTripEvent>(_onDeleteTrip);
    
    // 3. Optional: Add initial event
    add(LoadTripListEvent());
  }
}
```

**Key Points:**
- Dependencies injected via constructor
- Initial state set with `super()`
- Event handlers registered with `on<>()`
- Can trigger initial load automatically

---

### 2. Event Processing

**When:** Event is dispatched to BLoC

**Flow:**
```
Event Dispatched → Handler Called → Async Operation → State Emitted
```

**Example:**
```dart
// User action triggers event
BlocProvider.of<TripListBloc>(context).add(LoadTripListEvent());

// BLoC processes event
Future<void> _onLoadTripList(
  LoadTripListEvent event,
  Emitter<TripListState> emit,
) async {
  // 1. Emit loading state
  emit(TripListLoading());
  
  // 2. Perform async operation
  try {
    final trips = await repository.getTrips();
    
    // 3. Emit success state
    emit(TripListLoaded(trips));
  } catch (e) {
    // 4. Emit error state
    emit(TripListError(e.toString()));
  }
}
```

**Multiple State Emissions:**
- BLoC can emit multiple states during event processing
- Common pattern: Loading → Loaded/Error
- Each state emission triggers UI rebuild

---

### 3. State Emission

**When:** BLoC emits new state

**What Happens:**
```dart
// BLoC emits state
emit(TripListLoaded(trips));

// UI listens and rebuilds
BlocBuilder<TripListBloc, TripListState>(
  builder: (context, state) {
    if (state is TripListLoaded) {
      return TripList(trips: state.trips);
    }
    // ... other states
  },
)
```

**State Persistence:**
- State persists until next emission
- UI can access current state anytime
- State is immutable (new state replaces old)

---

### 4. Cleanup

**When:** BLoC is no longer needed

**What Happens:**
```dart
// BLoC automatically closes when:
// 1. Widget is disposed (if using BlocProvider)
// 2. Explicitly closed: bloc.close()

@override
void dispose() {
  tripListBloc.close();  // Closes stream, frees resources
  super.dispose();
}
```

**Cleanup Actions:**
- Stream subscriptions closed
- Resources freed
- Event handlers unregistered

---

## Complete Example: TripListBloc Lifecycle

### 1. Initialization

```dart
// main.dart or page
final tripListBloc = TripListBloc(tripRepository);

// BLoC created with:
// - Initial state: TripListInitial()
// - Event handlers registered
// - Dependencies injected
```

### 2. First Load

```dart
// User opens trip list page
// Page dispatches event
tripListBloc.add(LoadTripListEvent());

// BLoC processes:
// 1. emit(TripListLoading())
// 2. await repository.getTrips()
// 3. emit(TripListLoaded(trips))
```

### 3. User Interactions

```dart
// User pulls to refresh
tripListBloc.add(RefreshTripListEvent());

// User deletes trip
tripListBloc.add(DeleteTripEvent(tripId));

// Each event triggers:
// Event → Handler → State Emission → UI Update
```

### 4. Cleanup

```dart
// When page is disposed
@override
void dispose() {
  tripListBloc.close();
  super.dispose();
}
```

---

## Data Flow Diagram

### Request Flow (User → API)

```
┌─────────┐
│   UI    │ User taps "Load Trips"
└────┬────┘
     │ dispatch event
     ↓
┌─────────┐
│  BLoC   │ Receives LoadTripListEvent
└────┬────┘
     │ emit(TripListLoading())
     ↓
┌─────────┐
│   UI    │ Shows loading indicator
└────┬────┘
     │
     │ BLoC calls repository
     ↓
┌─────────────┐
│ Repository  │ getTrips()
└────┬────────┘
     │
     │ Calls data source
     ↓
┌──────────────┐
│ Remote DS    │ API call
└────┬─────────┘
     │
     │ JSON response
     ↓
┌──────────────┐
│ Remote DS    │ Maps to Model
└────┬─────────┘
     │
     │ List<Trip>
     ↓
┌─────────────┐
│ Repository  │ Returns List<Trip>
└────┬────────┘
     │
     │ List<Trip>
     ↓
┌─────────┐
│  BLoC   │ emit(TripListLoaded(trips))
└────┬────┘
     │
     │ State emitted
     ↓
┌─────────┐
│   UI    │ Displays trip list
└─────────┘
```

### Response Flow (API → UI)

```
API Response
    ↓
RemoteDataSource (maps JSON to Model)
    ↓
Repository (saves to local DB, returns Entity)
    ↓
BLoC (processes data, emits State)
    ↓
UI (listens to state, rebuilds)
```

---

## State Transitions

### TripListBloc State Machine

```
Initial
  ↓
[LoadTripListEvent]
  ↓
Loading
  ↓
┌─────────┬─────────┐
│ Success │ Error   │
  ↓         ↓
Loaded    Error
  ↓
[RefreshTripListEvent]
  ↓
Loading (again)
```

### Example State Transitions

```dart
// Initial state
TripListInitial()

// User loads trips
↓ LoadTripListEvent
TripListLoading()

// Success
↓ Repository returns data
TripListLoaded([trip1, trip2, trip3])

// User refreshes
↓ RefreshTripListEvent
TripListLoading()

// Success
↓ Repository returns updated data
TripListLoaded([trip1, trip2, trip3, trip4])

// User deletes trip
↓ DeleteTripEvent(tripId)
TripListLoaded([trip1, trip2, trip4])  // Optimistic update

// Error occurs
↓ API call fails
TripListError("Network error")
```

---

## Event Handling Patterns

### 1. Simple Event Handler

```dart
on<LoadTripListEvent>(_onLoadTripList);

Future<void> _onLoadTripList(
  LoadTripListEvent event,
  Emitter<TripListState> emit,
) async {
  emit(TripListLoading());
  try {
    final trips = await repository.getTrips();
    emit(TripListLoaded(trips));
  } catch (e) {
    emit(TripListError(e.toString()));
  }
}
```

### 2. Event with Parameters

```dart
on<DeleteTripEvent>(_onDeleteTrip);

Future<void> _onDeleteTrip(
  DeleteTripEvent event,
  Emitter<TripListState> emit,
) async {
  // Access event parameters
  final tripId = event.tripId;
  
  // Optimistic update
  if (state is TripListLoaded) {
    final updatedTrips = (state as TripListLoaded)
        .trips
        .where((t) => t.id != tripId)
        .toList();
    emit(TripListLoaded(updatedTrips));
  }
  
  // Sync with backend
  try {
    await repository.deleteTrip(tripId);
  } catch (e) {
    // Revert on error
    add(LoadTripListEvent());
  }
}
```

### 3. Conditional Event Handling

```dart
on<LoadTripListEvent>((event, emit) async {
  // Check current state
  if (state is TripListLoaded) {
    // Already loaded, skip
    return;
  }
  
  // Load trips
  emit(TripListLoading());
  // ... rest of logic
});
```

---

## Error Handling in BLoC

### Error State Pattern

```dart
class TripListError extends TripListState {
  final String message;
  final String? code;
  final bool retryable;
  
  TripListError(
    this.message, {
    this.code,
    this.retryable = true,
  });
}
```

### Error Handling Flow

```dart
try {
  final trips = await repository.getTrips();
  emit(TripListLoaded(trips));
} on NetworkException catch (e) {
  emit(TripListError(
    'Network error. Please check your connection.',
    code: 'NETWORK_ERROR',
    retryable: true,
  ));
} on UnauthorizedException catch (e) {
  emit(TripListError(
    'Session expired. Please login again.',
    code: 'UNAUTHORIZED',
    retryable: false,
  ));
  // Navigate to login
} catch (e) {
  emit(TripListError(
    'An unexpected error occurred.',
    code: 'UNKNOWN',
    retryable: true,
  ));
}
```

---

## BLoC Best Practices

### 1. Immutable States

```dart
// ✅ Good: Immutable state
class TripListLoaded extends TripListState {
  final List<Trip> trips;
  TripListLoaded(this.trips);
}

// ❌ Bad: Mutable state
class TripListLoaded extends TripListState {
  List<Trip> trips;  // Mutable
  TripListLoaded(this.trips);
}
```

### 2. Single Responsibility

```dart
// ✅ Good: Separate BLoCs for different concerns
TripListBloc  // Manages trip list
TripDetailBloc  // Manages single trip

// ❌ Bad: One BLoC for everything
TripBloc  // Manages list, detail, create, delete, etc.
```

### 3. Error Recovery

```dart
// ✅ Good: Provide retry mechanism
class TripListError extends TripListState {
  final VoidCallback? onRetry;
  TripListError(this.message, {this.onRetry});
}

// UI can call onRetry() to retry operation
```

### 4. State Equality

```dart
// ✅ Good: Override == and hashCode for state comparison
@override
bool operator ==(Object other) {
  if (identical(this, other)) return true;
  return other is TripListLoaded &&
      listEquals(other.trips, trips);
}

@override
int get hashCode => trips.hashCode;
```

---

## Testing BLoC Lifecycle

### Test State Transitions

```dart
test('emits correct states in order', () {
  final bloc = TripListBloc(mockRepository);
  
  expect(
    bloc.stream,
    emitsInOrder([
      TripListInitial(),
      TripListLoading(),
      TripListLoaded([trip1, trip2]),
    ]),
  );
  
  bloc.add(LoadTripListEvent());
});
```

### Test Error Handling

```dart
test('emits error state on repository failure', () {
  when(mockRepository.getTrips())
      .thenThrow(NetworkException('No connection'));
  
  final bloc = TripListBloc(mockRepository);
  
  expect(
    bloc.stream,
    emitsInOrder([
      TripListInitial(),
      TripListLoading(),
      TripListError('No connection'),
    ]),
  );
  
  bloc.add(LoadTripListEvent());
});
```

---

## Summary

### BLoC Lifecycle Stages

1. **Initialization**: BLoC created, handlers registered
2. **Event Processing**: Events processed, states emitted
3. **State Emission**: UI listens and rebuilds
4. **Cleanup**: Resources freed when BLoC closed

### Key Concepts

- **Events**: User actions or system events
- **States**: Immutable UI state representations
- **BLoC**: Processes events and emits states
- **Repository**: Abstracts data access
- **Data Sources**: Remote API and local database

### Benefits

- ✅ **Predictable**: Clear data flow
- ✅ **Testable**: Easy to test in isolation
- ✅ **Maintainable**: Clear separation of concerns
- ✅ **Scalable**: Easy to add new features

This architecture ensures a clean, maintainable, and testable Flutter application.

