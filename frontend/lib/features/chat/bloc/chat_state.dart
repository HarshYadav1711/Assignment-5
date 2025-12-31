import 'package:equatable/equatable.dart';
import '../../../data/models/message.dart';

/// Chat states
abstract class ChatState extends Equatable {
  const ChatState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class ChatInitial extends ChatState {
  const ChatInitial();
}

/// Connecting state
class ChatConnecting extends ChatState {
  const ChatConnecting();
}

/// Connected state
class ChatConnected extends ChatState {
  final List<ChatMessageModel> messages;

  const ChatConnected(this.messages);

  @override
  List<Object?> get props => [messages];
}

/// Disconnected state
class ChatDisconnected extends ChatState {
  final String? reason;

  const ChatDisconnected(this.reason);

  @override
  List<Object?> get props => [reason];
}

/// Error state
class ChatError extends ChatState {
  final String message;

  const ChatError(this.message);

  @override
  List<Object?> get props => [message];
}

