import '../datasources/remote/trip_remote_ds.dart';
import '../datasources/local/trip_local_ds.dart';
import '../models/trip.dart';
import '../../core/network/network_exception.dart';

/// Repository for trips (offline-first)
class TripRepository {
  final TripRemoteDataSource _remoteDataSource;
  final TripLocalDataSource _localDataSource;

  TripRepository({
    required TripRemoteDataSource remoteDataSource,
    required TripLocalDataSource localDataSource,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource;

  /// Get all trips (offline-first)
  Future<List<TripModel>> getTrips({bool forceRefresh = false}) async {
    // 1. Load from local DB first (fast)
    final localTrips = await _localDataSource.getTrips();

    // 2. If not forcing refresh and we have local data, return it
    if (!forceRefresh && localTrips.isNotEmpty) {
      // Try to sync in background (don't wait)
      _syncTrips().catchError((_) {});
      return localTrips;
    }

    // 3. Try to sync with server
    try {
      final remoteTrips = await _remoteDataSource.getTrips();
      // 4. Update local DB
      await _localDataSource.saveTrips(remoteTrips);
      return remoteTrips;
    } catch (e) {
      // 5. If offline, return local data
      if (e is ConnectionException && localTrips.isNotEmpty) {
        return localTrips;
      }
      rethrow;
    }
  }

  /// Get trip by ID
  Future<TripModel> getTripById(String tripId) async {
    // Try local first
    final localTrip = await _localDataSource.getTripById(tripId);
    if (localTrip != null) {
      // Try to sync in background
      _syncTrip(tripId).catchError((_) {});
      return localTrip;
    }

    // Load from remote
    final trip = await _remoteDataSource.getTripById(tripId);
    await _localDataSource.saveTrip(trip);
    return trip;
  }

  /// Create trip
  Future<TripModel> createTrip(Map<String, dynamic> data) async {
    try {
      final trip = await _remoteDataSource.createTrip(data);
      await _localDataSource.saveTrip(trip);
      return trip;
    } catch (e) {
      // Could implement offline queue here
      rethrow;
    }
  }

  /// Update trip
  Future<TripModel> updateTrip(String tripId, Map<String, dynamic> data) async {
    try {
      final trip = await _remoteDataSource.updateTrip(tripId, data);
      await _localDataSource.saveTrip(trip);
      return trip;
    } catch (e) {
      rethrow;
    }
  }

  /// Delete trip
  Future<void> deleteTrip(String tripId) async {
    try {
      await _remoteDataSource.deleteTrip(tripId);
      await _localDataSource.deleteTrip(tripId);
    } catch (e) {
      rethrow;
    }
  }

  /// Get collaborators
  Future<List<CollaboratorModel>> getCollaborators(String tripId) async {
    return await _remoteDataSource.getCollaborators(tripId);
  }

  /// Invite collaborator
  Future<CollaboratorModel> inviteCollaborator(
    String tripId,
    String email,
    String role,
  ) async {
    return await _remoteDataSource.inviteCollaborator(tripId, email, role);
  }

  /// Sync trips with server (background)
  Future<void> _syncTrips() async {
    try {
      final remoteTrips = await _remoteDataSource.getTrips();
      await _localDataSource.saveTrips(remoteTrips);
    } catch (_) {
      // Silently fail - offline mode
    }
  }

  /// Sync single trip (background)
  Future<void> _syncTrip(String tripId) async {
    try {
      final trip = await _remoteDataSource.getTripById(tripId);
      await _localDataSource.saveTrip(trip);
    } catch (_) {
      // Silently fail
    }
  }
}

