/// Network-related exceptions
class NetworkException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic originalError;

  NetworkException(this.message, {this.statusCode, this.originalError});

  @override
  String toString() => 'NetworkException: $message';
}

class UnauthorizedException extends NetworkException {
  UnauthorizedException([String? message])
      : super(message ?? 'Unauthorized', statusCode: 401);
}

class NotFoundException extends NetworkException {
  NotFoundException([String? message])
      : super(message ?? 'Not found', statusCode: 404);
}

class ServerException extends NetworkException {
  ServerException([String? message])
      : super(message ?? 'Server error', statusCode: 500);
}

class ConnectionException extends NetworkException {
  ConnectionException([String? message])
      : super(message ?? 'Connection error', statusCode: null);
}

