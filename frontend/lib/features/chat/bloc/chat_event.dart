import 'package:equatable/equatable.dart';

/// Chat events
abstract class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object?> get props => [];
}

/// Connect to chat
class ConnectChatEvent extends ChatEvent {
  final String tripId;

  const ConnectChatEvent(this.tripId);

  @override
  List<Object?> get props => [tripId];
}

/// Disconnect from chat
class DisconnectChatEvent extends ChatEvent {
  const DisconnectChatEvent();
}

/// Send message
class SendMessageEvent extends ChatEvent {
  final String content;
  final String? replyToId;

  const SendMessageEvent(this.content, {this.replyToId});

  @override
  List<Object?> get props => [content, replyToId];
}

/// Message received
class MessageReceivedEvent extends ChatEvent {
  final Map<String, dynamic> messageData;

  const MessageReceivedEvent(this.messageData);

  @override
  List<Object?> get props => [messageData];
}

/// Load message history
class LoadMessageHistoryEvent extends ChatEvent {
  final String chatRoomId;

  const LoadMessageHistoryEvent(this.chatRoomId);

  @override
  List<Object?> get props => [chatRoomId];
}

