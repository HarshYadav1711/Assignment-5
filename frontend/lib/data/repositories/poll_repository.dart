import '../datasources/remote/poll_remote_ds.dart';
import '../datasources/local/poll_local_ds.dart';
import '../models/poll.dart';
import '../../core/network/network_exception.dart';

/// Repository for polls (offline-first)
class PollRepository {
  final PollRemoteDataSource _remoteDataSource;
  final PollLocalDataSource _localDataSource;

  PollRepository({
    required PollRemoteDataSource remoteDataSource,
    required PollLocalDataSource localDataSource,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource;

  /// Get polls for trip
  Future<List<PollModel>> getPolls(String tripId, {bool forceRefresh = false}) async {
    // Load from local first
    final localPolls = await _localDataSource.getPolls(tripId);

    if (!forceRefresh && localPolls.isNotEmpty) {
      _syncPolls(tripId).catchError((_) {});
      return localPolls;
    }

    // Try to sync with server
    try {
      final remotePolls = await _remoteDataSource.getPolls(tripId);
      await _localDataSource.savePolls(remotePolls);
      return remotePolls;
    } catch (e) {
      if (e is ConnectionException && localPolls.isNotEmpty) {
        return localPolls;
      }
      rethrow;
    }
  }

  /// Create poll
  Future<PollModel> createPoll(Map<String, dynamic> data) async {
    try {
      final poll = await _remoteDataSource.createPoll(data);
      await _localDataSource.savePoll(poll);
      return poll;
    } catch (e) {
      rethrow;
    }
  }

  /// Vote on poll
  Future<PollModel> vote(String pollId, String optionId) async {
    try {
      final poll = await _remoteDataSource.vote(pollId, optionId);
      await _localDataSource.savePoll(poll);
      return poll;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _syncPolls(String tripId) async {
    try {
      final polls = await _remoteDataSource.getPolls(tripId);
      await _localDataSource.savePolls(polls);
    } catch (_) {
      // Silently fail
    }
  }
}

