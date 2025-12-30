# Feature Implementation Guide

## Overview

This document provides detailed implementation guidance for each feature in the Flutter app, including BLoC structure, UI components, and data flow.

---

## 1. Auth Feature

### Structure

```
features/auth/
├── bloc/
│   ├── auth_bloc.dart
│   ├── auth_event.dart
│   └── auth_state.dart
├── pages/
│   ├── login_page.dart
│   └── register_page.dart
└── widgets/
    ├── login_form.dart
    └── register_form.dart
```

### BLoC Implementation

**Events:**
```dart
abstract class AuthEvent {}
class LoginEvent extends AuthEvent {
  final String email;
  final String password;
  LoginEvent(this.email, this.password);
}
class RegisterEvent extends AuthEvent {
  final String email;
  final String password;
  final String username;
  RegisterEvent(this.email, this.password, this.username);
}
class LogoutEvent extends AuthEvent {}
class CheckAuthEvent extends AuthEvent {}
```

**States:**
```dart
abstract class AuthState {}
class AuthInitial extends AuthState {}
class AuthLoading extends AuthState {}
class Authenticated extends AuthState {
  final User user;
  Authenticated(this.user);
}
class Unauthenticated extends AuthState {}
class AuthError extends AuthState {
  final String message;
  AuthError(this.message);
}
```

**BLoC:**
```dart
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository repository;
  
  AuthBloc(this.repository) : super(AuthInitial()) {
    on<LoginEvent>(_onLogin);
    on<RegisterEvent>(_onRegister);
    on<LogoutEvent>(_onLogout);
    on<CheckAuthEvent>(_onCheckAuth);
    
    // Check auth status on initialization
    add(CheckAuthEvent());
  }
  
  Future<void> _onLogin(
    LoginEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final user = await repository.login(event.email, event.password);
      emit(Authenticated(user));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }
  
  // ... other handlers
}
```

### Data Flow

```
Login Page
  ↓ User enters credentials
LoginEvent(email, password)
  ↓
AuthBloc
  ↓ emit(AuthLoading())
UI shows loading
  ↓
AuthRepository.login()
  ↓
API: POST /api/v1/auth/login/
  ↓
Token received
  ↓ Save to storage
AuthBloc
  ↓ emit(Authenticated(user))
UI navigates to home
```

---

## 2. Trip List & Details

### Trip List Feature

**Structure:**
```
features/trips/
├── bloc/
│   ├── trip_list_bloc.dart
│   ├── trip_list_event.dart
│   └── trip_list_state.dart
├── pages/
│   └── trip_list_page.dart
└── widgets/
    └── trip_card.dart
```

**Events:**
```dart
class LoadTripListEvent extends TripListEvent {}
class RefreshTripListEvent extends TripListEvent {}
class CreateTripEvent extends TripListEvent {
  final Trip trip;
  CreateTripEvent(this.trip);
}
class DeleteTripEvent extends TripListEvent {
  final String tripId;
  DeleteTripEvent(this.tripId);
}
```

**States:**
```dart
class TripListInitial extends TripListState {}
class TripListLoading extends TripListState {}
class TripListLoaded extends TripListState {
  final List<Trip> trips;
  TripListLoaded(this.trips);
}
class TripListError extends TripListState {
  final String message;
  TripListError(this.message);
}
```

**Optimistic Updates:**
```dart
Future<void> _onDeleteTrip(
  DeleteTripEvent event,
  Emitter<TripListState> emit,
) async {
  // Optimistic update
  if (state is TripListLoaded) {
    final updatedTrips = (state as TripListLoaded)
        .trips
        .where((t) => t.id != event.tripId)
        .toList();
    emit(TripListLoaded(updatedTrips));
  }
  
  // Sync with backend
  try {
    await repository.deleteTrip(event.tripId);
  } catch (e) {
    // Revert on error
    add(LoadTripListEvent());
  }
}
```

### Trip Detail Feature

**Structure:**
```
features/trips/
├── bloc/
│   ├── trip_detail_bloc.dart
│   ├── trip_detail_event.dart
│   └── trip_detail_state.dart
├── pages/
│   └── trip_detail_page.dart
└── widgets/
    ├── trip_info_section.dart
    ├── collaborator_list.dart
    └── invite_dialog.dart
```

**Events:**
```dart
class LoadTripDetailEvent extends TripDetailEvent {
  final String tripId;
  LoadTripDetailEvent(this.tripId);
}
class UpdateTripEvent extends TripDetailEvent {
  final Trip trip;
  UpdateTripEvent(this.trip);
}
class InviteCollaboratorEvent extends TripDetailEvent {
  final String email;
  final String role;
  InviteCollaboratorEvent(this.email, this.role);
}
```

**States:**
```dart
class TripDetailLoading extends TripDetailState {}
class TripDetailLoaded extends TripDetailState {
  final Trip trip;
  final List<Collaborator> collaborators;
  TripDetailLoaded(this.trip, this.collaborators);
}
class TripDetailError extends TripDetailState {
  final String message;
  TripDetailError(this.message);
}
```

---

## 3. Itinerary with Drag-and-Drop

### Structure

```
features/itineraries/
├── bloc/
│   ├── itinerary_bloc.dart
│   ├── itinerary_event.dart
│   └── itinerary_state.dart
├── pages/
│   └── itinerary_page.dart
└── widgets/
    ├── itinerary_day_card.dart
    ├── itinerary_item_tile.dart
    └── reorderable_item_list.dart
```

### Drag-and-Drop Implementation

**Events:**
```dart
class LoadItineraryEvent extends ItineraryEvent {
  final String tripId;
  final DateTime date;
  LoadItineraryEvent(this.tripId, this.date);
}
class ReorderItemsEvent extends ItineraryEvent {
  final String itineraryId;
  final List<String> itemIds;  // New order
  ReorderItemsEvent(this.itineraryId, this.itemIds);
}
class AddItemEvent extends ItineraryEvent {
  final String itineraryId;
  final ItineraryItem item;
  AddItemEvent(this.itineraryId, this.item);
}
```

**States:**
```dart
class ItineraryLoading extends ItineraryState {}
class ItineraryLoaded extends ItineraryState {
  final Itinerary itinerary;
  final List<ItineraryItem> items;  // Ordered items
  ItineraryLoaded(this.itinerary, this.items);
}
class ItineraryReordering extends ItineraryState {
  final List<ItineraryItem> items;  // Optimistic update
  ItineraryReordering(this.items);
}
```

**Reorder Handler:**
```dart
Future<void> _onReorderItems(
  ReorderItemsEvent event,
  Emitter<ItineraryState> emit,
) async {
  // 1. Optimistic update
  if (state is ItineraryLoaded) {
    final currentItems = (state as ItineraryLoaded).items;
    final reorderedItems = event.itemIds
        .map((id) => currentItems.firstWhere((item) => item.id == id))
        .toList();
    emit(ItineraryReordering(reorderedItems));
  }
  
  // 2. Sync with backend
  try {
    await repository.reorderItems(event.itineraryId, event.itemIds);
    
    // 3. Reload to get updated order values
    final itinerary = await repository.getItinerary(event.itineraryId);
    emit(ItineraryLoaded(itinerary, itinerary.items));
  } catch (e) {
    // 4. Revert on error
    add(LoadItineraryEvent(/* ... */));
  }
}
```

**UI Implementation:**
```dart
ReorderableListView(
  onReorder: (oldIndex, newIndex) {
    final items = state.items;
    if (newIndex > oldIndex) newIndex--;
    
    final item = items.removeAt(oldIndex);
    items.insert(newIndex, item);
    
    // Dispatch reorder event
    bloc.add(ReorderItemsEvent(
      itineraryId,
      items.map((i) => i.id).toList(),
    ));
  },
  children: state.items.map((item) => 
    ItineraryItemTile(item: item)
  ).toList(),
)
```

---

## 4. Polls Feature

### Structure

```
features/polls/
├── bloc/
│   ├── poll_bloc.dart
│   ├── poll_event.dart
│   └── poll_state.dart
├── pages/
│   ├── poll_list_page.dart
│   └── poll_detail_page.dart
└── widgets/
    ├── poll_card.dart
    ├── poll_option_tile.dart
    └── vote_result_chart.dart
```

### BLoC Implementation

**Events:**
```dart
class LoadPollsEvent extends PollEvent {
  final String tripId;
  LoadPollsEvent(this.tripId);
}
class VoteEvent extends PollEvent {
  final String pollId;
  final String optionId;
  VoteEvent(this.pollId, this.optionId);
}
class RemoveVoteEvent extends PollEvent {
  final String pollId;
  final String optionId;
  RemoveVoteEvent(this.pollId, this.optionId);
}
class CreatePollEvent extends PollEvent {
  final Poll poll;
  CreatePollEvent(this.poll);
}
```

**States:**
```dart
class PollsLoading extends PollState {}
class PollsLoaded extends PollState {
  final List<Poll> polls;
  PollsLoaded(this.polls);
}
class VoteSuccess extends PollState {
  final Poll poll;  // Updated poll with vote
  VoteSuccess(this.poll);
}
class VoteError extends PollState {
  final String message;
  VoteError(this.message);
}
```

**Voting Flow:**
```dart
Future<void> _onVote(
  VoteEvent event,
  Emitter<PollState> emit,
) async {
  // Optimistic update
  if (state is PollsLoaded) {
    final polls = (state as PollsLoaded).polls;
    final pollIndex = polls.indexWhere((p) => p.id == event.pollId);
    if (pollIndex != -1) {
      final updatedPoll = polls[pollIndex].copyWith(
        // Mark option as voted
        options: polls[pollIndex].options.map((opt) {
          if (opt.id == event.optionId) {
            return opt.copyWith(
              voteCount: opt.voteCount + 1,
              userVoted: true,
            );
          }
          return opt;
        }).toList(),
      );
      
      final updatedPolls = List<Poll>.from(polls);
      updatedPolls[pollIndex] = updatedPoll;
      emit(PollsLoaded(updatedPolls));
    }
  }
  
  // Sync with backend
  try {
    final updatedPoll = await repository.vote(event.pollId, event.optionId);
    emit(VoteSuccess(updatedPoll));
  } catch (e) {
    emit(VoteError(e.toString()));
    // Revert optimistic update
    add(LoadPollsEvent(/* tripId */));
  }
}
```

---

## 5. Chat UI Feature

### Structure

```
features/chat/
├── bloc/
│   ├── chat_bloc.dart
│   ├── chat_event.dart
│   └── chat_state.dart
├── pages/
│   └── chat_page.dart
└── widgets/
    ├── message_bubble.dart
    ├── message_input.dart
    ├── message_list.dart
    └── typing_indicator.dart
```

### BLoC Implementation

**Events:**
```dart
class ConnectChatEvent extends ChatEvent {
  final String tripId;
  ConnectChatEvent(this.tripId);
}
class DisconnectChatEvent extends ChatEvent {}
class SendMessageEvent extends ChatEvent {
  final String content;
  final String? replyToId;
  SendMessageEvent(this.content, {this.replyToId});
}
class MessageReceivedEvent extends ChatEvent {
  final ChatMessage message;
  MessageReceivedEvent(this.message);
}
class TypingEvent extends ChatEvent {
  final bool isTyping;
  TypingEvent(this.isTyping);
}
```

**States:**
```dart
class ChatInitial extends ChatState {}
class ChatConnecting extends ChatState {}
class ChatConnected extends ChatState {
  final List<ChatMessage> messages;
  ChatConnected(this.messages);
}
class ChatDisconnected extends ChatState {
  final String? reason;
  ChatDisconnected(this.reason);
}
class MessageSent extends ChatState {
  final ChatMessage message;
  MessageSent(this.message);
}
class MessageReceived extends ChatState {
  final ChatMessage message;
  MessageReceived(this.message);
}
```

**WebSocket Connection:**
```dart
class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ChatRepository repository;
  WebSocketChannel? _channel;
  
  ChatBloc(this.repository) : super(ChatInitial()) {
    on<ConnectChatEvent>(_onConnect);
    on<DisconnectChatEvent>(_onDisconnect);
    on<SendMessageEvent>(_onSendMessage);
    on<MessageReceivedEvent>(_onMessageReceived);
    on<TypingEvent>(_onTyping);
  }
  
  Future<void> _onConnect(
    ConnectChatEvent event,
    Emitter<ChatState> emit,
  ) async {
    emit(ChatConnecting());
    
    try {
      // Connect to WebSocket
      _channel = await repository.connectWebSocket(event.tripId);
      
      // Load message history
      final messages = await repository.getMessageHistory(event.tripId);
      emit(ChatConnected(messages));
      
      // Listen for incoming messages
      _channel!.stream.listen((data) {
        final message = ChatMessage.fromJson(jsonDecode(data));
        add(MessageReceivedEvent(message));
      });
    } catch (e) {
      // Fallback to REST API
      emit(ChatDisconnected('WebSocket unavailable. Using standard messaging.'));
      final messages = await repository.getMessageHistory(event.tripId);
      emit(ChatConnected(messages));
    }
  }
  
  Future<void> _onSendMessage(
    SendMessageEvent event,
    Emitter<ChatState> emit,
  ) async {
    // Optimistic update
    final optimisticMessage = ChatMessage(
      id: Uuid().v4(),
      content: event.content,
      sender: currentUser,
      createdAt: DateTime.now(),
    );
    
    if (state is ChatConnected) {
      final messages = (state as ChatConnected).messages;
      emit(ChatConnected([...messages, optimisticMessage]));
    }
    
    // Send via WebSocket or REST
    try {
      if (_channel != null) {
        _channel!.sink.add(jsonEncode({
          'type': 'chat_message',
          'content': event.content,
          'reply_to': event.replyToId,
        }));
      } else {
        // Fallback to REST
        final message = await repository.sendMessage(
          tripId,
          event.content,
          replyToId: event.replyToId,
        );
        emit(MessageSent(message));
      }
    } catch (e) {
      // Revert optimistic update
      add(ConnectChatEvent(tripId));
    }
  }
  
  @override
  Future<void> close() {
    _channel?.sink.close();
    return super.close();
  }
}
```

**Fallback to REST:**
```dart
// If WebSocket fails, use REST API with polling
if (state is ChatDisconnected) {
  // Poll for new messages every 5 seconds
  Timer.periodic(Duration(seconds: 5), (timer) async {
    final messages = await repository.getMessageHistory(tripId);
    if (messages.length > (state as ChatConnected).messages.length) {
      emit(ChatConnected(messages));
    }
  });
}
```

---

## Shared Components

### Loading Widget

```dart
// shared/widgets/loading_indicator.dart
class LoadingIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: CircularProgressIndicator(),
    );
  }
}
```

### Error Widget

```dart
// shared/widgets/error_widget.dart
class ErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  
  ErrorWidget(this.message, {this.onRetry});
  
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48),
          SizedBox(height: 16),
          Text(message),
          if (onRetry != null)
            ElevatedButton(
              onPressed: onRetry,
              child: Text('Retry'),
            ),
        ],
      ),
    );
  }
}
```

### BLoC Consumer Pattern

```dart
// Usage in UI
BlocConsumer<TripListBloc, TripListState>(
  listener: (context, state) {
    // Handle side effects (navigation, snackbars)
    if (state is TripListError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.message)),
      );
    }
  },
  builder: (context, state) {
    // Build UI based on state
    if (state is TripListLoading) {
      return LoadingIndicator();
    } else if (state is TripListLoaded) {
      return TripList(trips: state.trips);
    } else if (state is TripListError) {
      return ErrorWidget(
        state.message,
        onRetry: () => context.read<TripListBloc>().add(LoadTripListEvent()),
      );
    }
    return SizedBox.shrink();
  },
)
```

---

## Summary

### Feature Implementation Checklist

- [x] **Auth**: Login, register, logout, token management
- [x] **Trip List**: Load, refresh, create, delete with optimistic updates
- [x] **Trip Detail**: Load details, update, manage collaborators
- [x] **Itinerary**: Load, reorder items (drag-and-drop), add/update items
- [x] **Polls**: Load, vote, create polls with real-time updates
- [x] **Chat**: WebSocket connection, send/receive messages, typing indicators, fallback

### Key Patterns Used

1. **Optimistic Updates**: Update UI immediately, sync with backend
2. **Offline-First**: Load from local DB first, sync with server
3. **Error Recovery**: Retry mechanisms, error states
4. **State Management**: BLoC pattern for predictable state
5. **Separation of Concerns**: Clear layer boundaries

All features follow the same architectural patterns for consistency and maintainability.

