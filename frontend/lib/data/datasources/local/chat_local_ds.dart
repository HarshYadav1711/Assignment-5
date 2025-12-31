import '../../../core/storage/local_db.dart';
import '../../models/message.dart';

/// Local data source for chat messages
class ChatLocalDataSource {
  /// Get messages for chat room
  Future<List<ChatMessageModel>> getMessages(String chatRoomId) async {
    final box = LocalDatabase.messagesBox;
    final messages = <ChatMessageModel>[];
    for (var key in box.keys) {
      final data = box.get(key) as Map<String, dynamic>?;
      if (data != null) {
        final message = ChatMessageModel.fromJson(data);
        if (message.chatRoomId == chatRoomId) {
          messages.add(message);
        }
      }
    }
    // Sort by created_at
    messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return messages;
  }

  /// Save message
  Future<void> saveMessage(ChatMessageModel message) async {
    final box = LocalDatabase.messagesBox;
    await box.put(message.id, message.toJson());
  }

  /// Save multiple messages
  Future<void> saveMessages(List<ChatMessageModel> messages) async {
    final box = LocalDatabase.messagesBox;
    final Map<String, dynamic> data = {};
    for (var message in messages) {
      data[message.id] = message.toJson();
    }
    await box.putAll(data);
  }

  /// Clear all
  Future<void> clearAll() async {
    await LocalDatabase.messagesBox.clear();
  }
}

