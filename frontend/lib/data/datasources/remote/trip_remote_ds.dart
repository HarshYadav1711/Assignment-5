import '../../../core/network/api_client.dart';
import '../../../core/network/network_exception.dart';
import '../../models/trip.dart';

/// Remote data source for trips
class TripRemoteDataSource {
  final ApiClient _apiClient;

  TripRemoteDataSource(this._apiClient);

  /// Get all trips
  Future<List<TripModel>> getTrips({int? page, int? pageSize}) async {
    try {
      final response = await _apiClient.get(
        '/trips/',
        queryParameters: {
          if (page != null) 'page': page,
          if (pageSize != null) 'page_size': pageSize,
        },
      );
      final results = response.data['results'] as List<dynamic>? ??
          response.data as List<dynamic>;
      return results
          .map((json) => TripModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (e is NetworkException) {
        rethrow;
      }
      // Extract the actual error message
      String errorMessage = 'Failed to load trips';
      if (e.toString().contains('ConnectionException') || 
          e.toString().contains('No internet') ||
          e.toString().contains('Connection timeout')) {
        errorMessage = 'Unable to connect to server. Please check if the backend is running.';
      } else if (e.toString().contains('401') || e.toString().contains('Unauthorized')) {
        errorMessage = 'Authentication required. Please log in again.';
      } else {
        errorMessage = 'Failed to load trips: ${e.toString().replaceAll('NetworkException: ', '')}';
      }
      throw NetworkException(errorMessage);
    }
  }

  /// Get trip by ID
  Future<TripModel> getTripById(String tripId) async {
    try {
      final response = await _apiClient.get('/trips/$tripId/');
      return TripModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw NetworkException('Failed to load trip: ${e.toString()}');
    }
  }

  /// Create trip
  Future<TripModel> createTrip(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.post('/trips/', data: data);
      final responseData = response.data;
      if (responseData is! Map<String, dynamic>) {
        throw NetworkException('Invalid response format from server');
      }
      try {
        return TripModel.fromJson(responseData);
      } catch (e) {
        // Log the actual response for debugging
        throw NetworkException('Failed to parse trip response: ${e.toString()}. Response: ${responseData.toString()}');
      }
    } catch (e) {
      if (e is NetworkException) {
        rethrow;
      }
      throw NetworkException('Failed to create trip: ${e.toString()}');
    }
  }

  /// Update trip
  Future<TripModel> updateTrip(String tripId, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.patch('/trips/$tripId/', data: data);
      return TripModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw NetworkException('Failed to update trip: ${e.toString()}');
    }
  }

  /// Delete trip
  Future<void> deleteTrip(String tripId) async {
    try {
      await _apiClient.delete('/trips/$tripId/');
    } catch (e) {
      throw NetworkException('Failed to delete trip: ${e.toString()}');
    }
  }

  /// Get collaborators
  Future<List<CollaboratorModel>> getCollaborators(String tripId) async {
    try {
      final response = await _apiClient.get('/trips/$tripId/members/');
      final results = response.data['results'] as List<dynamic>? ??
          response.data as List<dynamic>;
      return results
          .map((json) =>
              CollaboratorModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw NetworkException('Failed to load collaborators: ${e.toString()}');
    }
  }

  /// Invite collaborator
  Future<CollaboratorModel> inviteCollaborator(
    String tripId,
    String email,
    String role,
  ) async {
    try {
      final response = await _apiClient.post(
        '/trips/$tripId/members/',
        data: {
          'email': email,
          'role': role,
        },
      );
      return CollaboratorModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw NetworkException('Failed to invite collaborator: ${e.toString()}');
    }
  }
}

