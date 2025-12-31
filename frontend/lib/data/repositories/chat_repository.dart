import '../datasources/remote/chat_remote_ds.dart';
import '../datasources/local/chat_local_ds.dart';
import '../models/message.dart';
import '../../core/network/network_exception.dart';
import '../../core/network/websocket_client.dart';

/// Repository for chat (offline-first with WebSocket)
class ChatRepository {
  final ChatRemoteDataSource _remoteDataSource;
  final ChatLocalDataSource _localDataSource;
  WebSocketClient? _wsClient;

  ChatRepository({
    required ChatRemoteDataSource remoteDataSource,
    required ChatLocalDataSource localDataSource,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource;

  /// Connect WebSocket
  Future<WebSocketClient> connectWebSocket(String tripId) async {
    _wsClient = WebSocketClient();
    await _wsClient!.connect(tripId);
    return _wsClient!;
  }

  /// Get message history
  Future<List<ChatMessageModel>> getMessageHistory(
    String chatRoomId, {
    bool forceRefresh = false,
  }) async {
    // Load from local first
    final localMessages = await _localDataSource.getMessages(chatRoomId);

    if (!forceRefresh && localMessages.isNotEmpty) {
      _syncMessages(chatRoomId).catchError((_) {});
      return localMessages;
    }

    // Try to sync with server
    try {
      final remoteMessages = await _remoteDataSource.getMessages(chatRoomId);
      await _localDataSource.saveMessages(remoteMessages);
      return remoteMessages;
    } catch (e) {
      if (e is ConnectionException && localMessages.isNotEmpty) {
        return localMessages;
      }
      rethrow;
    }
  }

  /// Send message
  Future<ChatMessageModel> sendMessage(
    String chatRoomId,
    String content, {
    String? replyToId,
  }) async {
    try {
      final message = await _remoteDataSource.sendMessage(
        chatRoomId,
        content,
        replyToId: replyToId,
      );
      await _localDataSource.saveMessage(message);
      return message;
    } catch (e) {
      rethrow;
    }
  }

  /// Disconnect WebSocket
  Future<void> disconnect() async {
    await _wsClient?.disconnect();
    _wsClient = null;
  }

  Future<void> _syncMessages(String chatRoomId) async {
    try {
      final messages = await _remoteDataSource.getMessages(chatRoomId);
      await _localDataSource.saveMessages(messages);
    } catch (_) {
      // Silently fail
    }
  }
}

