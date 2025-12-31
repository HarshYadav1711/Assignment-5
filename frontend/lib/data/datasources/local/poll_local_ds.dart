import '../../../core/storage/local_db.dart';
import '../../models/poll.dart';

/// Local data source for polls
class PollLocalDataSource {
  /// Get polls for trip
  Future<List<PollModel>> getPolls(String tripId) async {
    final box = LocalDatabase.pollsBox;
    final polls = <PollModel>[];
    for (var key in box.keys) {
      final data = box.get(key) as Map<String, dynamic>?;
      if (data != null) {
        final poll = PollModel.fromJson(data);
        if (poll.tripId == tripId) {
          polls.add(poll);
        }
      }
    }
    return polls;
  }

  /// Save poll
  Future<void> savePoll(PollModel poll) async {
    final box = LocalDatabase.pollsBox;
    await box.put(poll.id, poll.toJson());
  }

  /// Save multiple polls
  Future<void> savePolls(List<PollModel> polls) async {
    final box = LocalDatabase.pollsBox;
    final Map<String, dynamic> data = {};
    for (var poll in polls) {
      data[poll.id] = poll.toJson();
    }
    await box.putAll(data);
  }

  /// Clear all
  Future<void> clearAll() async {
    await LocalDatabase.pollsBox.clear();
  }
}

