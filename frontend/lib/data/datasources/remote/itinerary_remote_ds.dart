import '../../../core/network/api_client.dart';
import '../../../core/network/network_exception.dart';
import '../../models/itinerary.dart';

/// Remote data source for itineraries
class ItineraryRemoteDataSource {
  final ApiClient _apiClient;

  ItineraryRemoteDataSource(this._apiClient);

  /// Get itinerary for trip and date
  Future<ItineraryModel?> getItinerary(String tripId, DateTime date) async {
    try {
      final response = await _apiClient.get(
        '/itineraries/',
        queryParameters: {
          'trip': tripId,
          'date': date.toIso8601String().split('T')[0],
        },
      );
      final results = response.data['results'] as List<dynamic>?;
      if (results == null || results.isEmpty) return null;
      return ItineraryModel.fromJson(results[0] as Map<String, dynamic>);
    } catch (e) {
      if (e is NotFoundException) return null;
      throw NetworkException('Failed to load itinerary: ${e.toString()}');
    }
  }

  /// Get all itineraries for a trip
  Future<List<ItineraryModel>> getItineraries(String tripId) async {
    try {
      final response = await _apiClient.get(
        '/itineraries/',
        queryParameters: {'trip': tripId},
      );
      final results = response.data['results'] as List<dynamic>? ??
          response.data as List<dynamic>;
      return results
          .map((json) => ItineraryModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw NetworkException('Failed to load itineraries: ${e.toString()}');
    }
  }

  /// Create itinerary
  Future<ItineraryModel> createItinerary(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.post('/itineraries/', data: data);
      return ItineraryModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw NetworkException('Failed to create itinerary: ${e.toString()}');
    }
  }

  /// Reorder items
  Future<void> reorderItems(String itineraryId, List<String> itemIds) async {
    try {
      await _apiClient.post(
        '/itineraries/$itineraryId/items/reorder/',
        data: {'item_ids': itemIds},
      );
    } catch (e) {
      throw NetworkException('Failed to reorder items: ${e.toString()}');
    }
  }

  /// Create item
  Future<ItineraryItemModel> createItem(
    String itineraryId,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _apiClient.post(
        '/itineraries/$itineraryId/items/',
        data: data,
      );
      return ItineraryItemModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw NetworkException('Failed to create item: ${e.toString()}');
    }
  }

  /// Update item
  Future<ItineraryItemModel> updateItem(
    String itemId,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _apiClient.patch(
        '/itinerary-items/$itemId/',
        data: data,
      );
      return ItineraryItemModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw NetworkException('Failed to update item: ${e.toString()}');
    }
  }

  /// Delete item
  Future<void> deleteItem(String itemId) async {
    try {
      await _apiClient.delete('/itinerary-items/$itemId/');
    } catch (e) {
      throw NetworkException('Failed to delete item: ${e.toString()}');
    }
  }
}

