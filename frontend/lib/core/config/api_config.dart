/// API configuration for the Smart Trip Planner backend.
class ApiConfig {
  // For local development
  static const String baseUrl = 'http://localhost:8000';
  
  // For Android emulator, use:
  // static const String baseUrl = 'http://10.0.2.2:8000';
  
  // For iOS simulator, use:
  // static const String baseUrl = 'http://localhost:8000';
  
  static const String apiVersion = 'v1';
  static const String apiBase = '/api/$apiVersion';
  
  // WebSocket configuration
  static String get wsUrl => baseUrl.replaceFirst('http://', 'ws://').replaceFirst('https://', 'wss://');
  static String get wsBase => '$wsUrl/ws';
}

