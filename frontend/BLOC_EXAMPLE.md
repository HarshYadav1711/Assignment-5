# Complete BLoC Example: TripListBloc

This document provides a complete, production-ready example of a BLoC implementation for the Trip List feature.

---

## File Structure

```
features/trips/
├── bloc/
│   ├── trip_list_bloc.dart
│   ├── trip_list_event.dart
│   └── trip_list_state.dart
```

---

## 1. Events (trip_list_event.dart)

```dart
part of 'trip_list_bloc.dart';

/// Base class for all trip list events
abstract class TripListEvent extends Equatable {
  const TripListEvent();
  
  @override
  List<Object?> get props => [];
}

/// Event to load the trip list
class LoadTripListEvent extends TripListEvent {
  const LoadTripListEvent();
}

/// Event to refresh the trip list (pull-to-refresh)
class RefreshTripListEvent extends TripListEvent {
  const RefreshTripListEvent();
}

/// Event to create a new trip
class CreateTripEvent extends TripListEvent {
  final String title;
  final String? description;
  final DateTime? startDate;
  final DateTime? endDate;
  
  const CreateTripEvent({
    required this.title,
    this.description,
    this.startDate,
    this.endDate,
  });
  
  @override
  List<Object?> get props => [title, description, startDate, endDate];
}

/// Event to delete a trip
class DeleteTripEvent extends TripListEvent {
  final String tripId;
  
  const DeleteTripEvent(this.tripId);
  
  @override
  List<Object?> get props => [tripId];
}

/// Event to filter trips by status
class FilterTripsEvent extends TripListEvent {
  final String? status;  // 'draft', 'planned', 'active', etc.
  
  const FilterTripsEvent(this.status);
  
  @override
  List<Object?> get props => [status];
}
```

---

## 2. States (trip_list_state.dart)

```dart
part of 'trip_list_bloc.dart';

/// Base class for all trip list states
abstract class TripListState extends Equatable {
  const TripListState();
  
  @override
  List<Object?> get props => [];
}

/// Initial state (before any data is loaded)
class TripListInitial extends TripListState {
  const TripListInitial();
}

/// Loading state (data is being fetched)
class TripListLoading extends TripListState {
  const TripListLoading();
}

/// Loaded state (trips successfully loaded)
class TripListLoaded extends TripListState {
  final List<Trip> trips;
  final String? filterStatus;  // Current filter
  
  const TripListLoaded(this.trips, {this.filterStatus});
  
  @override
  List<Object?> get props => [trips, filterStatus];
  
  /// Helper method to get filtered trips
  List<Trip> get filteredTrips {
    if (filterStatus == null) return trips;
    return trips.where((trip) => trip.status == filterStatus).toList();
  }
}

/// Error state (something went wrong)
class TripListError extends TripListState {
  final String message;
  final String? code;  // Error code for specific handling
  final bool retryable;  // Can user retry?
  
  const TripListError(
    this.message, {
    this.code,
    this.retryable = true,
  });
  
  @override
  List<Object?> get props => [message, code, retryable];
}
```

---

## 3. BLoC Implementation (trip_list_bloc.dart)

```dart
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:data/models/trip.dart';
import 'package:data/repositories/trip_repository.dart';

part 'trip_list_event.dart';
part 'trip_list_state.dart';

/// BLoC for managing trip list state
class TripListBloc extends Bloc<TripListEvent, TripListState> {
  final TripRepository repository;
  
  TripListBloc(this.repository) : super(TripListInitial()) {
    // Register event handlers
    on<LoadTripListEvent>(_onLoadTripList);
    on<RefreshTripListEvent>(_onRefreshTripList);
    on<CreateTripEvent>(_onCreateTrip);
    on<DeleteTripEvent>(_onDeleteTrip);
    on<FilterTripsEvent>(_onFilterTrips);
    
    // Load trips on initialization
    add(const LoadTripListEvent());
  }
  
  /// Handle loading trip list
  Future<void> _onLoadTripList(
    LoadTripListEvent event,
    Emitter<TripListState> emit,
  ) async {
    // Don't show loading if we already have data
    if (state is! TripListLoaded) {
      emit(const TripListLoading());
    }
    
    try {
      final trips = await repository.getTrips();
      emit(TripListLoaded(trips));
    } catch (e) {
      emit(TripListError(
        'Failed to load trips: ${e.toString()}',
        code: _getErrorCode(e),
        retryable: true,
      ));
    }
  }
  
  /// Handle refreshing trip list (pull-to-refresh)
  Future<void> _onRefreshTripList(
    RefreshTripListEvent event,
    Emitter<TripListState> emit,
  ) async {
    // Keep current state while refreshing
    final currentState = state;
    
    try {
      final trips = await repository.getTrips(refresh: true);
      emit(TripListLoaded(trips));
    } catch (e) {
      // Revert to previous state on error
      emit(currentState);
      // Show error message (could use snackbar in UI)
    }
  }
  
  /// Handle creating a new trip
  Future<void> _onCreateTrip(
    CreateTripEvent event,
    Emitter<TripListState> emit,
  ) async {
    // Optimistic update: add trip to list immediately
    if (state is TripListLoaded) {
      final currentTrips = (state as TripListLoaded).trips;
      final newTrip = Trip(
        id: 'temp-${DateTime.now().millisecondsSinceEpoch}',
        title: event.title,
        description: event.description,
        startDate: event.startDate,
        endDate: event.endDate,
        status: 'draft',
        createdAt: DateTime.now(),
      );
      
      emit(TripListLoaded([newTrip, ...currentTrips]));
    }
    
    try {
      final createdTrip = await repository.createTrip(
        title: event.title,
        description: event.description,
        startDate: event.startDate,
        endDate: event.endDate,
      );
      
      // Replace optimistic trip with real one
      if (state is TripListLoaded) {
        final currentTrips = (state as TripListLoaded).trips;
        final updatedTrips = currentTrips.map((trip) {
          if (trip.id.startsWith('temp-')) {
            return createdTrip;
          }
          return trip;
        }).toList();
        
        emit(TripListLoaded(updatedTrips));
      }
    } catch (e) {
      // Revert optimistic update on error
      add(const LoadTripListEvent());
      emit(TripListError(
        'Failed to create trip: ${e.toString()}',
        code: 'CREATE_ERROR',
        retryable: false,
      ));
    }
  }
  
  /// Handle deleting a trip
  Future<void> _onDeleteTrip(
    DeleteTripEvent event,
    Emitter<TripListState> emit,
  ) async {
    // Optimistic update: remove trip from list immediately
    if (state is TripListLoaded) {
      final currentTrips = (state as TripListLoaded).trips;
      final updatedTrips = currentTrips
          .where((trip) => trip.id != event.tripId)
          .toList();
      
      emit(TripListLoaded(updatedTrips));
    }
    
    try {
      await repository.deleteTrip(event.tripId);
      // Success - state already updated optimistically
    } catch (e) {
      // Revert optimistic update on error
      add(const LoadTripListEvent());
      emit(TripListError(
        'Failed to delete trip: ${e.toString()}',
        code: 'DELETE_ERROR',
        retryable: false,
      ));
    }
  }
  
  /// Handle filtering trips
  void _onFilterTrips(
    FilterTripsEvent event,
    Emitter<TripListState> emit,
  ) {
    if (state is TripListLoaded) {
      final currentState = state as TripListLoaded;
      emit(TripListLoaded(
        currentState.trips,
        filterStatus: event.status,
      ));
    }
  }
  
  /// Helper method to extract error code
  String? _getErrorCode(dynamic error) {
    if (error is NetworkException) {
      return 'NETWORK_ERROR';
    } else if (error is UnauthorizedException) {
      return 'UNAUTHORIZED';
    }
    return null;
  }
}
```

---

## 4. UI Implementation (trip_list_page.dart)

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:features/trips/bloc/trip_list_bloc.dart';
import 'package:features/trips/widgets/trip_card.dart';
import 'package:shared/widgets/loading_indicator.dart';
import 'package:shared/widgets/error_widget.dart';

class TripListPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Trips'),
        actions: [
          // Filter button
          IconButton(
            icon: Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(context),
          ),
        ],
      ),
      body: BlocConsumer<TripListBloc, TripListState>(
        listener: (context, state) {
          // Handle side effects (navigation, snackbars)
          if (state is TripListError && !state.retryable) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (context, state) {
          if (state is TripListLoading) {
            return LoadingIndicator();
          } else if (state is TripListLoaded) {
            final trips = state.filteredTrips;
            
            if (trips.isEmpty) {
              return EmptyState(
                message: 'No trips found',
                icon: Icons.flight_takeoff,
              );
            }
            
            return RefreshIndicator(
              onRefresh: () async {
                context.read<TripListBloc>().add(RefreshTripListEvent());
                // Wait for state to update
                await Future.delayed(Duration(seconds: 1));
              },
              child: ListView.builder(
                itemCount: trips.length,
                itemBuilder: (context, index) {
                  return TripCard(
                    trip: trips[index],
                    onTap: () => _navigateToDetail(context, trips[index].id),
                    onDelete: () => _deleteTrip(context, trips[index].id),
                  );
                },
              ),
            );
          } else if (state is TripListError) {
            return ErrorWidget(
              state.message,
              onRetry: state.retryable
                  ? () => context.read<TripListBloc>().add(LoadTripListEvent())
                  : null,
            );
          }
          
          return SizedBox.shrink();
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToCreate(context),
        child: Icon(Icons.add),
      ),
    );
  }
  
  void _navigateToDetail(BuildContext context, String tripId) {
    Navigator.pushNamed(context, '/trip-detail', arguments: tripId);
  }
  
  void _navigateToCreate(BuildContext context) {
    Navigator.pushNamed(context, '/create-trip');
  }
  
  void _deleteTrip(BuildContext context, String tripId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Trip'),
        content: Text('Are you sure you want to delete this trip?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<TripListBloc>().add(DeleteTripEvent(tripId));
              Navigator.pop(context);
            },
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }
  
  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Filter Trips'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text('All'),
              onTap: () {
                context.read<TripListBloc>().add(FilterTripsEvent(null));
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text('Draft'),
              onTap: () {
                context.read<TripListBloc>().add(FilterTripsEvent('draft'));
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text('Planned'),
              onTap: () {
                context.read<TripListBloc>().add(FilterTripsEvent('planned'));
                Navigator.pop(context);
              },
            ),
            // ... other filters
          ],
        ),
      ),
    );
  }
}
```

---

## 5. BLoC Provider Setup

```dart
// main.dart or app setup
BlocProvider(
  create: (context) => TripListBloc(
    TripRepository(
      remoteDataSource: TripRemoteDataSource(apiClient),
      localDataSource: TripLocalDataSource(localDb),
    ),
  ),
  child: TripListPage(),
)
```

---

## 6. Testing Example

```dart
// test/features/trips/bloc/trip_list_bloc_test.dart
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:features/trips/bloc/trip_list_bloc.dart';
import 'package:data/models/trip.dart';
import 'package:data/repositories/trip_repository.dart';
import 'package:mockito/mockito.dart';

class MockTripRepository extends Mock implements TripRepository {}

void main() {
  late MockTripRepository mockRepository;
  late TripListBloc bloc;
  
  setUp(() {
    mockRepository = MockTripRepository();
    bloc = TripListBloc(mockRepository);
  });
  
  tearDown(() {
    bloc.close();
  });
  
  group('TripListBloc', () {
    final trip1 = Trip(id: '1', title: 'Trip 1');
    final trip2 = Trip(id: '2', title: 'Trip 2');
    final trips = [trip1, trip2];
    
    test('initial state is TripListInitial', () {
      expect(bloc.state, equals(TripListInitial()));
    });
    
    blocTest<TripListBloc, TripListState>(
      'emits [Loading, Loaded] when LoadTripListEvent is added',
      build: () {
        when(mockRepository.getTrips())
            .thenAnswer((_) async => trips);
        return bloc;
      },
      act: (bloc) => bloc.add(LoadTripListEvent()),
      expect: () => [
        TripListLoading(),
        TripListLoaded(trips),
      ],
    );
    
    blocTest<TripListBloc, TripListState>(
      'emits [Loaded] with updated list when DeleteTripEvent is added',
      build: () {
        when(mockRepository.deleteTrip('1'))
            .thenAnswer((_) async => {});
        return bloc;
      },
      seed: () => TripListLoaded(trips),
      act: (bloc) => bloc.add(DeleteTripEvent('1')),
      expect: () => [
        TripListLoaded([trip2]),  // Optimistic update
      ],
      verify: (_) {
        verify(mockRepository.deleteTrip('1')).called(1);
      },
    );
  });
}
```

---

## Key Patterns Demonstrated

### 1. Optimistic Updates
- UI updates immediately
- Syncs with backend
- Reverts on error

### 2. Error Handling
- Consistent error states
- Error codes for specific handling
- Retry mechanisms

### 3. State Management
- Immutable states
- Clear state transitions
- Helper methods in states

### 4. Event Handling
- Events with parameters
- Multiple event handlers
- Conditional logic

---

## Summary

This example demonstrates:
- ✅ Complete BLoC implementation
- ✅ Event and state definitions
- ✅ Optimistic updates
- ✅ Error handling
- ✅ UI integration
- ✅ Testing approach

All features should follow this same pattern for consistency.

