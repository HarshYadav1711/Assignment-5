import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/trip_repository.dart';
import '../../../data/models/trip.dart';
import '../../../core/network/network_exception.dart';
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
      final message = e is NetworkException 
          ? e.message 
          : e.toString().replaceAll('NetworkException: ', '');
      emit(TripListError(message));
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
      final message = e is NetworkException 
          ? e.message 
          : e.toString().replaceAll('NetworkException: ', '');
      // On error, keep showing current data
      if (state is TripListLoaded) {
        emit(TripListError('Failed to refresh: $message'));
      } else {
        emit(TripListError(message));
      }
    }
  }

  Future<void> _onCreateTrip(
    CreateTripEvent event,
    Emitter<TripListState> emit,
  ) async {
    // Show loading state if we have trips, otherwise keep current state
    final currentTrips = state is TripListLoaded ? (state as TripListLoaded).trips : <TripModel>[];
    
    try {
      final newTrip = await _repository.createTrip(event.tripData);
      // Success - add new trip to the list
      emit(TripListLoaded([newTrip, ...currentTrips]));
    } catch (e) {
      final message = e is NetworkException 
          ? e.message 
          : e.toString().replaceAll('NetworkException: ', '');
      emit(TripListError('Failed to create trip: $message'));
      // Restore previous state on error
      if (currentTrips.isNotEmpty) {
        emit(TripListLoaded(currentTrips));
      }
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

