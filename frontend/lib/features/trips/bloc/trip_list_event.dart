import 'package:equatable/equatable.dart';

/// Trip list events
abstract class TripListEvent extends Equatable {
  const TripListEvent();

  @override
  List<Object?> get props => [];
}

/// Load trip list
class LoadTripListEvent extends TripListEvent {
  final bool forceRefresh;

  const LoadTripListEvent({this.forceRefresh = false});

  @override
  List<Object?> get props => [forceRefresh];
}

/// Refresh trip list
class RefreshTripListEvent extends TripListEvent {
  const RefreshTripListEvent();
}

/// Create trip
class CreateTripEvent extends TripListEvent {
  final Map<String, dynamic> tripData;

  const CreateTripEvent(this.tripData);

  @override
  List<Object?> get props => [tripData];
}

/// Delete trip
class DeleteTripEvent extends TripListEvent {
  final String tripId;

  const DeleteTripEvent(this.tripId);

  @override
  List<Object?> get props => [tripId];
}

