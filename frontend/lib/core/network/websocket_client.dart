import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../config/api_config.dart';
import '../services/auth_service.dart';

/// WebSocket client for real-time communication
class WebSocketClient {
  WebSocketChannel? _channel;
  final AuthService _authService = AuthService();
  final StreamController<Map<String, dynamic>> _messageController =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;

  bool get isConnected => _channel != null;

  /// Connect to WebSocket for a trip
  Future<void> connect(String tripId) async {
    try {
      final token = await _authService.getAccessToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final wsUrl = '${ApiConfig.wsBase}/chat/$tripId/?token=$token';
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

      // Listen for messages
      _channel!.stream.listen(
        (data) {
          try {
            final message = jsonDecode(data) as Map<String, dynamic>;
            _messageController.add(message);
          } catch (e) {
            // Handle non-JSON messages
            _messageController.add({'type': 'error', 'data': data.toString()});
          }
        },
        onError: (error) {
          _messageController.add({
            'type': 'error',
            'data': error.toString(),
          });
        },
        onDone: () {
          _messageController.add({'type': 'disconnected'});
        },
      );
    } catch (e) {
      throw Exception('Failed to connect: $e');
    }
  }

  /// Send message via WebSocket
  void send(Map<String, dynamic> message) {
    if (_channel == null) {
      throw Exception('WebSocket not connected');
    }
    _channel!.sink.add(jsonEncode(message));
  }

  /// Disconnect
  Future<void> disconnect() async {
    await _channel?.sink.close();
    _channel = null;
  }

  /// Dispose
  void dispose() {
    disconnect();
    _messageController.close();
  }
}

