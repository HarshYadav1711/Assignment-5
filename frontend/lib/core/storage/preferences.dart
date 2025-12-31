import 'package:shared_preferences/shared_preferences.dart';

/// Wrapper for SharedPreferences
class AppPreferences {
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  static SharedPreferences get instance {
    if (_prefs == null) {
      throw Exception('AppPreferences not initialized. Call init() first.');
    }
    return _prefs!;
  }

  // String
  static Future<bool> setString(String key, String value) async {
    return await instance.setString(key, value);
  }

  static String? getString(String key) {
    return instance.getString(key);
  }

  // Int
  static Future<bool> setInt(String key, int value) async {
    return await instance.setInt(key, value);
  }

  static int? getInt(String key) {
    return instance.getInt(key);
  }

  // Bool
  static Future<bool> setBool(String key, bool value) async {
    return await instance.setBool(key, value);
  }

  static bool? getBool(String key) {
    return instance.getBool(key);
  }

  // Double
  static Future<bool> setDouble(String key, double value) async {
    return await instance.setDouble(key, value);
  }

  static double? getDouble(String key) {
    return instance.getDouble(key);
  }

  // Remove
  static Future<bool> remove(String key) async {
    return await instance.remove(key);
  }

  // Clear all
  static Future<bool> clear() async {
    return await instance.clear();
  }

  // Check if key exists
  static bool containsKey(String key) {
    return instance.containsKey(key);
  }
}

