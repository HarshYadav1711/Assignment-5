"""
Test helpers for common test setup and utilities.
"""
import 'package:flutter_test/flutter_test.dart';
import 'package:data/repositories/trip_repository.dart';
import 'package:data/repositories/auth_repository.dart';
import 'package:mockito/mockito.dart';

/// Creates a mock trip repository
MockTripRepository createMockTripRepository() {
  return MockTripRepository();
}

/// Creates a mock auth repository
MockAuthRepository createMockAuthRepository() {
  return MockAuthRepository();
}

/// Waits for async operations to complete
Future<void> waitForAsync(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(Duration(milliseconds: 100));
}

/// Finds widget by type and text
Finder findWidgetByTypeAndText(Type type, String text) {
  return find.descendant(
    of: find.byType(type),
    matching: find.text(text),
  );
}

