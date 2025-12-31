import 'package:equatable/equatable.dart';

/// Itinerary events
abstract class ItineraryEvent extends Equatable {
  const ItineraryEvent();

  @override
  List<Object?> get props => [];
}

/// Load itinerary
class LoadItineraryEvent extends ItineraryEvent {
  final String tripId;
  final DateTime date;

  const LoadItineraryEvent(this.tripId, this.date);

  @override
  List<Object?> get props => [tripId, date];
}

/// Reorder items
class ReorderItemsEvent extends ItineraryEvent {
  final String itineraryId;
  final List<String> itemIds;

  const ReorderItemsEvent(this.itineraryId, this.itemIds);

  @override
  List<Object?> get props => [itineraryId, itemIds];
}

/// Add item
class AddItemEvent extends ItineraryEvent {
  final String itineraryId;
  final Map<String, dynamic> itemData;

  const AddItemEvent(this.itineraryId, this.itemData);

  @override
  List<Object?> get props => [itineraryId, itemData];
}

/// Update item
class UpdateItemEvent extends ItineraryEvent {
  final String itemId;
  final Map<String, dynamic> itemData;

  const UpdateItemEvent(this.itemId, this.itemData);

  @override
  List<Object?> get props => [itemId, itemData];
}

/// Delete item
class DeleteItemEvent extends ItineraryEvent {
  final String itemId;

  const DeleteItemEvent(this.itemId);

  @override
  List<Object?> get props => [itemId];
}

