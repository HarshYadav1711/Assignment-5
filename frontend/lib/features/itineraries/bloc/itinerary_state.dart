import 'package:equatable/equatable.dart';
import '../../../data/models/itinerary.dart';

/// Itinerary states
abstract class ItineraryState extends Equatable {
  const ItineraryState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class ItineraryInitial extends ItineraryState {
  const ItineraryInitial();
}

/// Loading state
class ItineraryLoading extends ItineraryState {
  const ItineraryLoading();
}

/// Loaded state
class ItineraryLoaded extends ItineraryState {
  final ItineraryModel itinerary;
  final List<ItineraryItemModel> items;

  const ItineraryLoaded(this.itinerary, this.items);

  @override
  List<Object?> get props => [itinerary, items];
}

/// Reordering state (optimistic update)
class ItineraryReordering extends ItineraryState {
  final List<ItineraryItemModel> items;

  const ItineraryReordering(this.items);

  @override
  List<Object?> get props => [items];
}

/// Error state
class ItineraryError extends ItineraryState {
  final String message;

  const ItineraryError(this.message);

  @override
  List<Object?> get props => [message];
}

