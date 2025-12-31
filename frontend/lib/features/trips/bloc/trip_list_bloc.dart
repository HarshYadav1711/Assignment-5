import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/trip_repository.dart';
import '../../../data/models/trip.dart';
import 'trip_list_event.dart';
import 'trip_list_state.dart';

/// Trip list BLoC
class TripListBloc extends Bloc<TripListEvent, TripListState> {
  final TripRepository _repository;

  TripListBloc(this._repository) : super(TripListInitial()) {
    on<LoadTripListEvent>(_onLoadTripList);
    on<RefreshTripListEvent>(_onRefreshTripList);
    on<CreateTripEvent>(_onCreateTrip);
    on<DeleteTripEvent>(_onDeleteTrip);
  }

  Future<void> _onLoadTripList(
    LoadTripListEvent event,
    Emitter<TripListState> emit,
  ) async {
    emit(TripListLoading());
    try {
      final trips = await _repository.getTrips(forceRefresh: event.forceRefresh);
      emit(TripListLoaded(trips));
    } catch (e) {
      emit(TripListError(e.toString()));
    }
  }

  Future<void> _onRefreshTripList(
    RefreshTripListEvent event,
    Emitter<TripListState> emit,
  ) async {
    // Keep current state if loaded
    if (state is TripListLoaded) {
      final currentTrips = (state as TripListLoaded).trips;
      emit(TripListLoaded(currentTrips)); // Show current data while refreshing
    }

    try {
      final trips = await _repository.getTrips(forceRefresh: true);
      emit(TripListLoaded(trips));
    } catch (e) {
      // On error, keep showing current data
      if (state is TripListLoaded) {
        emit(TripListError('Failed to refresh: ${e.toString()}'));
      } else {
        emit(TripListError(e.toString()));
      }
    }
  }

  Future<void> _onCreateTrip(
    CreateTripEvent event,
    Emitter<TripListState> emit,
  ) async {
    // Optimistic update
    if (state is TripListLoaded) {
      // We'll add the trip after creation
    }

    try {
      final newTrip = await _repository.createTrip(event.tripData);
      if (state is TripListLoaded) {
        final currentTrips = (state as TripListLoaded).trips;
        emit(TripListLoaded([newTrip, ...currentTrips]));
      } else {
        add(LoadTripListEvent());
      }
    } catch (e) {
      emit(TripListError('Failed to create trip: ${e.toString()}'));
    }
  }

  Future<void> _onDeleteTrip(
    DeleteTripEvent event,
    Emitter<TripListState> emit,
  ) async {
    // Optimistic update
    if (state is TripListLoaded) {
      final currentTrips = (state as TripListLoaded).trips;
      final updatedTrips =
          currentTrips.where((t) => t.id != event.tripId).toList();
      emit(TripListLoaded(updatedTrips));
    }

    try {
      await _repository.deleteTrip(event.tripId);
      // State already updated optimistically
    } catch (e) {
      // Revert on error
      emit(TripListError('Failed to delete trip: ${e.toString()}'));
      add(LoadTripListEvent());
    }
  }
}

