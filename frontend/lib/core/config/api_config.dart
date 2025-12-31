import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

/// API configuration for the Smart Trip Planner backend.
class ApiConfig {
  // Detect platform and set appropriate base URL
  static String get baseUrl {
    if (kIsWeb) {
      // For web, use localhost (works in most browsers)
      // If running in Docker or remote, you may need to change this
      return 'http://localhost:8000';
    } else {
      try {
        if (Platform.isAndroid) {
          // For Android emulator, use 10.0.2.2 to access host machine
          return 'http://10.0.2.2:8000';
        } else {
          // For iOS simulator and desktop, use localhost
          return 'http://localhost:8000';
        }
      } catch (e) {
        // Fallback if Platform is not available
        return 'http://localhost:8000';
      }
    }
  }
  
  static const String apiVersion = 'v1';
  static const String apiBase = '/api/$apiVersion';
  
  // WebSocket configuration
  static String get wsUrl => baseUrl.replaceFirst('http://', 'ws://').replaceFirst('https://', 'wss://');
  static String get wsBase => '$wsUrl/ws';
}

