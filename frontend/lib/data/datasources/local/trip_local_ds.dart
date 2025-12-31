import '../../../core/storage/local_db.dart';
import '../../models/trip.dart';

/// Local data source for trips using Hive
class TripLocalDataSource {
  /// Get all trips from local storage
  Future<List<TripModel>> getTrips() async {
    final box = LocalDatabase.tripsBox;
    final trips = <TripModel>[];
    for (var key in box.keys) {
      final data = box.get(key) as Map<String, dynamic>?;
      if (data != null) {
        trips.add(TripModel.fromJson(data));
      }
    }
    return trips;
  }

  /// Get trip by ID
  Future<TripModel?> getTripById(String tripId) async {
    final box = LocalDatabase.tripsBox;
    final data = box.get(tripId) as Map<String, dynamic>?;
    if (data == null) return null;
    return TripModel.fromJson(data);
  }

  /// Save trip
  Future<void> saveTrip(TripModel trip) async {
    final box = LocalDatabase.tripsBox;
    await box.put(trip.id, trip.toJson());
  }

  /// Save multiple trips
  Future<void> saveTrips(List<TripModel> trips) async {
    final box = LocalDatabase.tripsBox;
    final Map<String, dynamic> data = {};
    for (var trip in trips) {
      data[trip.id] = trip.toJson();
    }
    await box.putAll(data);
  }

  /// Delete trip
  Future<void> deleteTrip(String tripId) async {
    final box = LocalDatabase.tripsBox;
    await box.delete(tripId);
  }

  /// Clear all trips
  Future<void> clearAll() async {
    await LocalDatabase.tripsBox.clear();
  }
}

