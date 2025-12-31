import '../../../core/storage/local_db.dart';
import '../../models/itinerary.dart';

/// Local data source for itineraries
class ItineraryLocalDataSource {
  /// Get itinerary by ID
  Future<ItineraryModel?> getItinerary(String itineraryId) async {
    final box = LocalDatabase.itinerariesBox;
    final data = box.get(itineraryId) as Map<String, dynamic>?;
    if (data == null) return null;
    return ItineraryModel.fromJson(data);
  }

  /// Get itineraries for trip
  Future<List<ItineraryModel>> getItineraries(String tripId) async {
    final box = LocalDatabase.itinerariesBox;
    final itineraries = <ItineraryModel>[];
    for (var key in box.keys) {
      final data = box.get(key) as Map<String, dynamic>?;
      if (data != null) {
        final itinerary = ItineraryModel.fromJson(data);
        if (itinerary.tripId == tripId) {
          itineraries.add(itinerary);
        }
      }
    }
    return itineraries;
  }

  /// Save itinerary
  Future<void> saveItinerary(ItineraryModel itinerary) async {
    final box = LocalDatabase.itinerariesBox;
    await box.put(itinerary.id, itinerary.toJson());
  }

  /// Save multiple itineraries
  Future<void> saveItineraries(List<ItineraryModel> itineraries) async {
    final box = LocalDatabase.itinerariesBox;
    final Map<String, dynamic> data = {};
    for (var itinerary in itineraries) {
      data[itinerary.id] = itinerary.toJson();
    }
    await box.putAll(data);
  }

  /// Clear all
  Future<void> clearAll() async {
    await LocalDatabase.itinerariesBox.clear();
  }
}

