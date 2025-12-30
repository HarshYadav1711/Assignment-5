"""
Widget tests for loading state widgets.

Tests critical loading, error, and empty state rendering.
"""
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared/widgets/loading_states.dart';

void main() {
  group('LoadingIndicator', () {
    testWidgets('displays loading spinner', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LoadingIndicator(),
          ),
        ),
      );
      
      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
    
    testWidgets('displays message when provided', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LoadingIndicator(message: 'Loading trips...'),
          ),
        ),
      );
      
      // Assert
      expect(find.text('Loading trips...'), findsOneWidget);
    });
  });
  
  group('EmptyStateWidget', () {
    testWidgets('displays message and icon', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyStateWidget(
              message: 'No trips found',
              icon: Icons.flight_takeoff,
            ),
          ),
        ),
      );
      
      // Assert
      expect(find.text('No trips found'), findsOneWidget);
      expect(find.byIcon(Icons.flight_takeoff), findsOneWidget);
    });
    
    testWidgets('displays action button when provided', (WidgetTester tester) async {
      // Arrange
      bool actionCalled = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyStateWidget(
              message: 'No trips found',
              icon: Icons.flight_takeoff,
              onAction: () => actionCalled = true,
              actionLabel: 'Create Trip',
            ),
          ),
        ),
      );
      
      // Act
      await tester.tap(find.text('Create Trip'));
      await tester.pump();
      
      // Assert
      expect(actionCalled, isTrue);
    });
  });
  
  group('ErrorStateWidget', () {
    testWidgets('displays error message', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorStateWidget(
              message: 'Failed to load trips',
            ),
          ),
        ),
      );
      
      // Assert
      expect(find.text('Failed to load trips'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });
    
    testWidgets('displays retry button when retryable', (WidgetTester tester) async {
      // Arrange
      bool retryCalled = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorStateWidget(
              message: 'Failed to load trips',
              onRetry: () => retryCalled = true,
              retryable: true,
            ),
          ),
        ),
      );
      
      // Act
      await tester.tap(find.text('Retry'));
      await tester.pump();
      
      // Assert
      expect(retryCalled, isTrue);
    });
    
    testWidgets('does not display retry button when not retryable', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorStateWidget(
              message: 'Failed to load trips',
              retryable: false,
            ),
          ),
        ),
      );
      
      // Assert
      expect(find.text('Retry'), findsNothing);
    });
  });
}

