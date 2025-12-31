import '../datasources/remote/itinerary_remote_ds.dart';
import '../datasources/local/itinerary_local_ds.dart';
import '../models/itinerary.dart';
import '../../core/network/network_exception.dart';

/// Repository for itineraries (offline-first)
class ItineraryRepository {
  final ItineraryRemoteDataSource _remoteDataSource;
  final ItineraryLocalDataSource _localDataSource;

  ItineraryRepository({
    required ItineraryRemoteDataSource remoteDataSource,
    required ItineraryLocalDataSource localDataSource,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource;

  /// Get itinerary for trip and date
  Future<ItineraryModel?> getItinerary(
    String tripId,
    DateTime date, {
    bool forceRefresh = false,
  }) async {
    // Try local first
    final localItineraries = await _localDataSource.getItineraries(tripId);
    final localItinerary = localItineraries
        .where((i) => i.date.year == date.year &&
            i.date.month == date.month &&
            i.date.day == date.day)
        .firstOrNull;

    if (!forceRefresh && localItinerary != null) {
      _syncItinerary(tripId, date).catchError((_) {});
      return localItinerary;
    }

    // Load from remote
    try {
      final itinerary = await _remoteDataSource.getItinerary(tripId, date);
      if (itinerary != null) {
        await _localDataSource.saveItinerary(itinerary);
      }
      return itinerary;
    } catch (e) {
      if (e is ConnectionException && localItinerary != null) {
        return localItinerary;
      }
      rethrow;
    }
  }

  /// Reorder items
  Future<void> reorderItems(String itineraryId, List<String> itemIds) async {
    try {
      await _remoteDataSource.reorderItems(itineraryId, itemIds);
      // Reload to get updated order values
      final itinerary = await _remoteDataSource.getItinerary(
        '', // Will need tripId and date
        DateTime.now(),
      );
      if (itinerary != null) {
        await _localDataSource.saveItinerary(itinerary);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Create item
  Future<ItineraryItemModel> createItem(
    String itineraryId,
    Map<String, dynamic> data,
  ) async {
    try {
      final item = await _remoteDataSource.createItem(itineraryId, data);
      // Update local storage
      final itinerary = await _localDataSource.getItinerary(itineraryId);
      if (itinerary != null) {
        final updatedItems = [...itinerary.items, item];
        await _localDataSource.saveItinerary(
          ItineraryModel(
            id: itinerary.id,
            tripId: itinerary.tripId,
            date: itinerary.date,
            title: itinerary.title,
            notes: itinerary.notes,
            createdAt: itinerary.createdAt,
            updatedAt: itinerary.updatedAt,
            items: updatedItems,
          ),
        );
      }
      return item;
    } catch (e) {
      rethrow;
    }
  }

  /// Update item
  Future<ItineraryItemModel> updateItem(
    String itemId,
    Map<String, dynamic> data,
  ) async {
    try {
      final item = await _remoteDataSource.updateItem(itemId, data);
      // Update local storage - find itinerary containing this item
      final itineraries = await _localDataSource.getItineraries(item.itineraryId);
      for (var itinerary in itineraries) {
        if (itinerary.items.any((i) => i.id == itemId)) {
          final updatedItems = itinerary.items.map((i) {
            return i.id == itemId ? item : i;
          }).toList();
          await _localDataSource.saveItinerary(
            ItineraryModel(
              id: itinerary.id,
              tripId: itinerary.tripId,
              date: itinerary.date,
              title: itinerary.title,
              notes: itinerary.notes,
              createdAt: itinerary.createdAt,
              updatedAt: itinerary.updatedAt,
              items: updatedItems,
            ),
          );
          break;
        }
      }
      return item;
    } catch (e) {
      rethrow;
    }
  }

  /// Delete item
  Future<void> deleteItem(String itemId, String itineraryId) async {
    try {
      await _remoteDataSource.deleteItem(itemId);
      // Update local storage
      final itineraries = await _localDataSource.getItineraries(itineraryId);
      for (var itinerary in itineraries) {
        if (itinerary.items.any((i) => i.id == itemId)) {
          final updatedItems = itinerary.items.where((i) => i.id != itemId).toList();
          await _localDataSource.saveItinerary(
            ItineraryModel(
              id: itinerary.id,
              tripId: itinerary.tripId,
              date: itinerary.date,
              title: itinerary.title,
              notes: itinerary.notes,
              createdAt: itinerary.createdAt,
              updatedAt: itinerary.updatedAt,
              items: updatedItems,
            ),
          );
          break;
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _syncItinerary(String tripId, DateTime date) async {
    try {
      final itinerary = await _remoteDataSource.getItinerary(tripId, date);
      if (itinerary != null) {
        await _localDataSource.saveItinerary(itinerary);
      }
    } catch (_) {
      // Silently fail
    }
  }
}

