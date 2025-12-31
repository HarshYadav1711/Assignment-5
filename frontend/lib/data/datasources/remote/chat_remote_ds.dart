import '../../../core/network/api_client.dart';
import '../../../core/network/network_exception.dart';
import '../../models/message.dart';

/// Remote data source for chat
class ChatRemoteDataSource {
  final ApiClient _apiClient;

  ChatRemoteDataSource(this._apiClient);

  /// Get message history
  Future<List<ChatMessageModel>> getMessages(String chatRoomId) async {
    try {
      final response = await _apiClient.get(
        '/chat/rooms/$chatRoomId/messages/',
      );
      final results = response.data['results'] as List<dynamic>? ??
          response.data as List<dynamic>;
      return results
          .map((json) =>
              ChatMessageModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw NetworkException('Failed to load messages: ${e.toString()}');
    }
  }

  /// Send message
  Future<ChatMessageModel> sendMessage(
    String chatRoomId,
    String content, {
    String? replyToId,
  }) async {
    try {
      final response = await _apiClient.post(
        '/chat/messages/',
        data: {
          'chat_room': chatRoomId,
          'content': content,
          if (replyToId != null) 'reply_to': replyToId,
        },
      );
      return ChatMessageModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw NetworkException('Failed to send message: ${e.toString()}');
    }
  }
}

