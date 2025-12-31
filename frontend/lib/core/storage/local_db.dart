import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

/// Local database using Hive
class LocalDatabase {
  static const String _tripBoxName = 'trips';
  static const String _itineraryBoxName = 'itineraries';
  static const String _pollBoxName = 'polls';
  static const String _messageBoxName = 'messages';

  static bool _initialized = false;

  /// Initialize Hive
  static Future<void> init() async {
    if (_initialized) return;

    await Hive.initFlutter();
    
    // Open boxes
    await Hive.openBox(_tripBoxName);
    await Hive.openBox(_itineraryBoxName);
    await Hive.openBox(_pollBoxName);
    await Hive.openBox(_messageBoxName);

    _initialized = true;
  }

  /// Get trips box
  static Box get tripsBox => Hive.box(_tripBoxName);

  /// Get itineraries box
  static Box get itinerariesBox => Hive.box(_itineraryBoxName);

  /// Get polls box
  static Box get pollsBox => Hive.box(_pollBoxName);

  /// Get messages box
  static Box get messagesBox => Hive.box(_messageBoxName);

  /// Clear all data
  static Future<void> clearAll() async {
    await tripsBox.clear();
    await itinerariesBox.clear();
    await pollsBox.clear();
    await messagesBox.clear();
  }

  /// Close all boxes
  static Future<void> close() async {
    await Hive.close();
    _initialized = false;
  }
}

