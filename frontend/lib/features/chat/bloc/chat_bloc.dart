import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/chat_repository.dart';
import '../../../data/models/message.dart';
import '../../../core/network/websocket_client.dart';
import 'chat_event.dart';
import 'chat_state.dart';

/// Chat BLoC
class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ChatRepository _repository;
  WebSocketClient? _wsClient;
  StreamSubscription? _wsSubscription;
  String? _currentTripId;
  String? _currentChatRoomId;

  ChatBloc(this._repository) : super(ChatInitial()) {
    on<ConnectChatEvent>(_onConnect);
    on<DisconnectChatEvent>(_onDisconnect);
    on<SendMessageEvent>(_onSendMessage);
    on<MessageReceivedEvent>(_onMessageReceived);
    on<LoadMessageHistoryEvent>(_onLoadMessageHistory);
  }

  Future<void> _onConnect(
    ConnectChatEvent event,
    Emitter<ChatState> emit,
  ) async {
    emit(ChatConnecting());
    _currentTripId = event.tripId;

    try {
      // Try WebSocket first
      _wsClient = await _repository.connectWebSocket(event.tripId);
      
      // Load message history
      // Note: chatRoomId would come from trip - simplified for now
      final messages = await _repository.getMessageHistory(event.tripId);
      emit(ChatConnected(messages));

      // Listen for WebSocket messages
      _wsSubscription = _wsClient!.messageStream.listen((data) {
        if (data['type'] == 'chat_message') {
          add(MessageReceivedEvent(data));
        }
      });
    } catch (e) {
      // Fallback to REST API
      emit(ChatDisconnected('WebSocket unavailable. Using standard messaging.'));
      try {
        final messages = await _repository.getMessageHistory(event.tripId);
        emit(ChatConnected(messages));
      } catch (e2) {
        emit(ChatError('Failed to connect: ${e2.toString()}'));
      }
    }
  }

  Future<void> _onDisconnect(
    DisconnectChatEvent event,
    Emitter<ChatState> emit,
  ) async {
    await _wsSubscription?.cancel();
    await _repository.disconnect();
    _wsClient = null;
    emit(ChatInitial());
  }

  Future<void> _onSendMessage(
    SendMessageEvent event,
    Emitter<ChatState> emit,
  ) async {
    // Optimistic update
    if (state is ChatConnected && _currentChatRoomId != null) {
      final currentMessages = (state as ChatConnected).messages;
      final optimisticMessage = ChatMessageModel(
        id: 'temp-${DateTime.now().millisecondsSinceEpoch}',
        chatRoomId: _currentChatRoomId!,
        senderId: '', // Would be current user ID
        content: event.content,
        messageType: 'text',
        replyToId: event.replyToId,
        isEdited: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      emit(ChatConnected([...currentMessages, optimisticMessage]));
    }

    try {
      if (_wsClient != null && _wsClient!.isConnected) {
        // Send via WebSocket
        _wsClient!.send({
          'type': 'chat_message',
          'content': event.content,
          if (event.replyToId != null) 'reply_to': event.replyToId,
        });
      } else if (_currentChatRoomId != null) {
        // Fallback to REST
        final message = await _repository.sendMessage(
          _currentChatRoomId!,
          event.content,
          replyToId: event.replyToId,
        );
        if (state is ChatConnected) {
          final currentMessages = (state as ChatConnected).messages;
          final updatedMessages = currentMessages
              .where((m) => !m.id.startsWith('temp-'))
              .toList();
          emit(ChatConnected([...updatedMessages, message]));
        }
      }
    } catch (e) {
      emit(ChatError('Failed to send message: ${e.toString()}'));
      // Revert optimistic update
      if (state is ChatConnected && _currentChatRoomId != null) {
        add(LoadMessageHistoryEvent(_currentChatRoomId!));
      }
    }
  }

  Future<void> _onMessageReceived(
    MessageReceivedEvent event,
    Emitter<ChatState> emit,
  ) async {
    if (state is ChatConnected) {
      final message = ChatMessageModel.fromJson(event.messageData);
      final currentMessages = (state as ChatConnected).messages;
      // Avoid duplicates
      if (!currentMessages.any((m) => m.id == message.id)) {
        emit(ChatConnected([...currentMessages, message]));
      }
    }
  }

  Future<void> _onLoadMessageHistory(
    LoadMessageHistoryEvent event,
    Emitter<ChatState> emit,
  ) async {
    _currentChatRoomId = event.chatRoomId;
    try {
      final messages = await _repository.getMessageHistory(event.chatRoomId);
      emit(ChatConnected(messages));
    } catch (e) {
      emit(ChatError('Failed to load messages: ${e.toString()}'));
    }
  }

  @override
  Future<void> close() {
    _wsSubscription?.cancel();
    _repository.disconnect();
    return super.close();
  }
}

