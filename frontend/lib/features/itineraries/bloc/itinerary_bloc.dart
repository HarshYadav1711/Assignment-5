import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/itinerary_repository.dart';
import '../../../data/models/itinerary.dart';
import 'itinerary_event.dart';
import 'itinerary_state.dart';

/// Itinerary BLoC
class ItineraryBloc extends Bloc<ItineraryEvent, ItineraryState> {
  final ItineraryRepository _repository;

  ItineraryBloc(this._repository) : super(ItineraryInitial()) {
    on<LoadItineraryEvent>(_onLoadItinerary);
    on<ReorderItemsEvent>(_onReorderItems);
    on<AddItemEvent>(_onAddItem);
    on<UpdateItemEvent>(_onUpdateItem);
    on<DeleteItemEvent>(_onDeleteItem);
  }

  Future<void> _onLoadItinerary(
    LoadItineraryEvent event,
    Emitter<ItineraryState> emit,
  ) async {
    emit(ItineraryLoading());
    try {
      final itinerary = await _repository.getItinerary(event.tripId, event.date);
      if (itinerary != null) {
        emit(ItineraryLoaded(itinerary, itinerary.items));
      } else {
        emit(ItineraryError('Itinerary not found'));
      }
    } catch (e) {
      emit(ItineraryError(e.toString()));
    }
  }

  Future<void> _onReorderItems(
    ReorderItemsEvent event,
    Emitter<ItineraryState> emit,
  ) async {
    // Optimistic update
    if (state is ItineraryLoaded) {
      final currentState = state as ItineraryLoaded;
      final reorderedItems = event.itemIds
          .map((id) => currentState.items.firstWhere((item) => item.id == id))
          .toList();
      emit(ItineraryReordering(reorderedItems));
    }

    try {
      await _repository.reorderItems(event.itineraryId, event.itemIds);
      // Reload to get updated order values
      if (state is ItineraryReordering) {
        final currentState = state as ItineraryReordering;
        // Create a temporary itinerary to reload
        // In real implementation, we'd reload from repository
        emit(ItineraryLoaded(
          ItineraryModel(
            id: event.itineraryId,
            tripId: '',
            date: DateTime.now(),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            items: currentState.items,
          ),
          currentState.items,
        ));
      }
    } catch (e) {
      emit(ItineraryError('Failed to reorder: ${e.toString()}'));
      // Revert
      add(LoadItineraryEvent('', DateTime.now()));
    }
  }

  Future<void> _onAddItem(
    AddItemEvent event,
    Emitter<ItineraryState> emit,
  ) async {
    try {
      final item = await _repository.createItem(event.itineraryId, event.itemData);
      if (state is ItineraryLoaded) {
        final currentState = state as ItineraryLoaded;
        emit(ItineraryLoaded(
          currentState.itinerary,
          [...currentState.items, item],
        ));
      }
    } catch (e) {
      emit(ItineraryError('Failed to add item: ${e.toString()}'));
    }
  }

  Future<void> _onUpdateItem(
    UpdateItemEvent event,
    Emitter<ItineraryState> emit,
  ) async {
    try {
      await _repository.updateItem(event.itemId, event.itemData);
      // Reload itinerary
      if (state is ItineraryLoaded) {
        final currentState = state as ItineraryLoaded;
        add(LoadItineraryEvent(currentState.itinerary.tripId, currentState.itinerary.date));
      }
    } catch (e) {
      emit(ItineraryError('Failed to update item: ${e.toString()}'));
    }
  }

  Future<void> _onDeleteItem(
    DeleteItemEvent event,
    Emitter<ItineraryState> emit,
  ) async {
    // Optimistic update
    String? itineraryId;
    ItineraryItemModel? itemToDelete;
    if (state is ItineraryLoaded) {
      final currentState = state as ItineraryLoaded;
      itineraryId = currentState.itinerary.id;
      itemToDelete = currentState.items.firstWhere((item) => item.id == event.itemId);
      final updatedItems = currentState.items.where((item) => item.id != event.itemId).toList();
      emit(ItineraryLoaded(currentState.itinerary, updatedItems));
    }

    try {
      if (itineraryId != null && itemToDelete != null) {
        await _repository.deleteItem(event.itemId, itemToDelete.itineraryId);
      }
    } catch (e) {
      emit(ItineraryError('Failed to delete item: ${e.toString()}'));
      // Revert
      if (state is ItineraryLoaded) {
        final currentState = state as ItineraryLoaded;
        add(LoadItineraryEvent(currentState.itinerary.tripId, currentState.itinerary.date));
      }
    }
  }
}

