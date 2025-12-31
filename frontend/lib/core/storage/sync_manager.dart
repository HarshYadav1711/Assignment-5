import '../network/network_exception.dart';
import '../../data/repositories/trip_repository.dart';

/// Sync manager for offline-first data synchronization
class SyncManager {
  final TripRepository _tripRepository;

  SyncManager(this._tripRepository);

  /// Sync all data
  Future<SyncResult> syncAll() async {
    final result = SyncResult();
    
    try {
      // Sync trips
      await _syncTrips(result);
      
      result.success = true;
    } catch (e) {
      result.success = false;
      result.errors.add(e.toString());
    }
    
    return result;
  }

  /// Sync trips
  Future<void> _syncTrips(SyncResult result) async {
    try {
      await _tripRepository.getTrips(forceRefresh: true);
      result.syncedItems.add('trips');
    } catch (e) {
      if (e is ConnectionException) {
        // Offline - not an error
        result.syncedItems.add('trips (offline)');
      } else {
        result.errors.add('Failed to sync trips: ${e.toString()}');
      }
    }
  }

  /// Check if online
  Future<bool> isOnline() async {
    try {
      await _tripRepository.getTrips(forceRefresh: true);
      return true;
    } catch (e) {
      return e is! ConnectionException;
    }
  }
}

/// Sync result
class SyncResult {
  bool success = false;
  final List<String> syncedItems = [];
  final List<String> errors = [];

  @override
  String toString() {
    return 'SyncResult(success: $success, items: ${syncedItems.length}, errors: ${errors.length})';
  }
}

