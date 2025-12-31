import '../../../core/network/api_client.dart';
import '../../../core/network/network_exception.dart';
import '../../models/poll.dart';

/// Remote data source for polls
class PollRemoteDataSource {
  final ApiClient _apiClient;

  PollRemoteDataSource(this._apiClient);

  /// Get polls for trip
  Future<List<PollModel>> getPolls(String tripId) async {
    try {
      final response = await _apiClient.get(
        '/polls/',
        queryParameters: {'trip': tripId},
      );
      final results = response.data['results'] as List<dynamic>? ??
          response.data as List<dynamic>;
      return results
          .map((json) => PollModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw NetworkException('Failed to load polls: ${e.toString()}');
    }
  }

  /// Create poll
  Future<PollModel> createPoll(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.post('/polls/', data: data);
      return PollModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw NetworkException('Failed to create poll: ${e.toString()}');
    }
  }

  /// Vote on poll
  Future<PollModel> vote(String pollId, String optionId) async {
    try {
      final response = await _apiClient.post(
        '/polls/$pollId/vote/',
        data: {'option': optionId},
      );
      return PollModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw NetworkException('Failed to vote: ${e.toString()}');
    }
  }
}

