"""
Widget tests for TripCard.

Tests critical rendering scenarios and user interactions.
"""
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:features/trips/widgets/trip_card.dart';
import 'package:data/models/trip.dart';

void main() {
  final testTrip = Trip(
    id: 'trip-1',
    title: 'Test Trip',
    description: 'Test Description',
    status: 'planned',
    startDate: DateTime(2024, 1, 1),
    endDate: DateTime(2024, 1, 7),
  );
  
  group('TripCard', () {
    testWidgets('displays trip title', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TripCard(trip: testTrip),
          ),
        ),
      );
      
      // Assert
      expect(find.text('Test Trip'), findsOneWidget);
    });
    
    testWidgets('displays trip description when provided', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TripCard(trip: testTrip),
          ),
        ),
      );
      
      // Assert
      expect(find.text('Test Description'), findsOneWidget);
    });
    
    testWidgets('does not display description when null', (WidgetTester tester) async {
      // Arrange
      final tripWithoutDescription = testTrip.copyWith(description: null);
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TripCard(trip: tripWithoutDescription),
          ),
        ),
      );
      
      // Assert
      expect(find.text('Test Description'), findsNothing);
    });
    
    testWidgets('calls onTap when card is tapped', (WidgetTester tester) async {
      // Arrange
      bool tapped = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TripCard(
              trip: testTrip,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );
      
      // Act
      await tester.tap(find.byType(TripCard));
      await tester.pump();
      
      // Assert
      expect(tapped, isTrue);
    });
    
    testWidgets('displays status chip', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TripCard(trip: testTrip),
          ),
        ),
      );
      
      // Assert
      expect(find.text('planned'), findsOneWidget);
    });
  });
}

