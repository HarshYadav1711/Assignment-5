/// App-wide constants
class AppConstants {
  // API
  static const int apiTimeoutSeconds = 30;
  static const int maxRetryAttempts = 3;

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // Validation
  static const int minPasswordLength = 8;
  static const int maxEmailLength = 254;
  static const int maxTripTitleLength = 200;
  static const int maxMessageLength = 10000;

  // Cache
  static const Duration cacheExpiration = Duration(hours: 1);

  // Sync
  static const Duration syncInterval = Duration(seconds: 30);
  static const int maxSyncRetries = 5;

  // UI
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration debounceDelay = Duration(milliseconds: 500);
}

/// Route names
class RouteNames {
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/';
  static const String tripList = '/trips';
  static const String tripDetail = '/trips/:id';
  static const String createTrip = '/trips/create';
  static const String itinerary = '/trips/:id/itinerary';
  static const String polls = '/trips/:id/polls';
  static const String chat = '/trips/:id/chat';
}

