import 'package:equatable/equatable.dart';
import '../../../data/models/trip.dart';

/// Trip list states
abstract class TripListState extends Equatable {
  const TripListState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class TripListInitial extends TripListState {
  const TripListInitial();
}

/// Loading state
class TripListLoading extends TripListState {
  const TripListLoading();
}

/// Loaded state
class TripListLoaded extends TripListState {
  final List<TripModel> trips;

  const TripListLoaded(this.trips);

  @override
  List<Object?> get props => [trips];
}

/// Error state
class TripListError extends TripListState {
  final String message;
  final bool retryable;

  const TripListError(this.message, {this.retryable = true});

  @override
  List<Object?> get props => [message, retryable];
}

