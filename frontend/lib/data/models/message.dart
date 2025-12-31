/// Chat message model
class ChatMessageModel {
  final String id;
  final String chatRoomId;
  final String senderId;
  final String content;
  final String messageType; // text, image, file, system
  final String? replyToId;
  final bool isEdited;
  final DateTime createdAt;
  final DateTime updatedAt;
  final UserModel? sender; // Populated when loading messages

  ChatMessageModel({
    required this.id,
    required this.chatRoomId,
    required this.senderId,
    required this.content,
    required this.messageType,
    this.replyToId,
    required this.isEdited,
    required this.createdAt,
    required this.updatedAt,
    this.sender,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: json['id'] as String,
      chatRoomId: json['chat_room'] is String
          ? json['chat_room'] as String
          : (json['chat_room'] as Map)['id'] as String,
      senderId: json['sender'] is String
          ? json['sender'] as String
          : (json['sender'] as Map)['id'] as String,
      content: json['content'] as String,
      messageType: json['message_type'] as String? ?? 'text',
      replyToId: json['reply_to']?['id'] as String?,
      isEdited: json['is_edited'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      sender: json['sender'] is Map
          ? UserModel.fromJson(json['sender'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chat_room': chatRoomId,
      'content': content,
      'message_type': messageType,
      if (replyToId != null) 'reply_to': replyToId,
    };
  }

  ChatMessageModel copyWith({
    String? content,
    bool? isEdited,
  }) {
    return ChatMessageModel(
      id: id,
      chatRoomId: chatRoomId,
      senderId: senderId,
      content: content ?? this.content,
      messageType: messageType,
      replyToId: replyToId,
      isEdited: isEdited ?? this.isEdited,
      createdAt: createdAt,
      updatedAt: updatedAt,
      sender: sender,
    );
  }
}

