"""
Mock factories for creating test data.

Provides consistent test data creation across all tests.
"""
import 'package:data/models/trip.dart';
import 'package:data/models/user.dart';
import 'package:data/models/itinerary.dart';
import 'package:data/models/poll.dart';
import 'package:data/models/message.dart';

class MockTripFactory {
  static Trip create({
    String? id,
    String? title,
    String? description,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return Trip(
      id: id ?? 'trip-${DateTime.now().millisecondsSinceEpoch}',
      title: title ?? 'Test Trip',
      description: description ?? 'Test Description',
      status: status ?? 'planned',
      startDate: startDate,
      endDate: endDate,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
  
  static List<Trip> createList({int count = 3}) {
    return List.generate(
      count,
      (index) => create(
        id: 'trip-$index',
        title: 'Trip $index',
      ),
    );
  }
}

class MockUserFactory {
  static User create({
    String? id,
    String? email,
    String? username,
  }) {
    return User(
      id: id ?? 'user-${DateTime.now().millisecondsSinceEpoch}',
      email: email ?? 'test@example.com',
      username: username ?? 'testuser',
    );
  }
}

class MockItineraryFactory {
  static Itinerary create({
    String? id,
    String? tripId,
    DateTime? date,
  }) {
    return Itinerary(
      id: id ?? 'itinerary-${DateTime.now().millisecondsSinceEpoch}',
      tripId: tripId ?? 'trip-1',
      date: date ?? DateTime.now(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}

class MockPollFactory {
  static Poll create({
    String? id,
    String? tripId,
    String? question,
  }) {
    return Poll(
      id: id ?? 'poll-${DateTime.now().millisecondsSinceEpoch}',
      tripId: tripId ?? 'trip-1',
      question: question ?? 'Test Question',
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}

class MockMessageFactory {
  static ChatMessage create({
    String? id,
    String? chatRoomId,
    String? content,
    String? senderId,
  }) {
    return ChatMessage(
      id: id ?? 'message-${DateTime.now().millisecondsSinceEpoch}',
      chatRoomId: chatRoomId ?? 'room-1',
      content: content ?? 'Test message',
      senderId: senderId ?? 'user-1',
      createdAt: DateTime.now(),
    );
  }
}

