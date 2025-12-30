# Test Documentation

## Overview

This directory contains unit and widget tests for the Smart Trip Planner Flutter app, focusing on critical paths and avoiding test bloat.

---

## Test Structure

```
test/
├── unit/
│   └── bloc/
│       ├── auth_bloc_test.dart          # Auth flow tests
│       ├── trip_list_bloc_test.dart    # Trip loading tests
│       └── sync_manager_test.dart      # Sync tests
│
├── widget/
│   ├── trip_card_test.dart            # Trip card widget tests
│   └── loading_states_test.dart       # Loading state widget tests
│
└── helpers/
    ├── mock_factories.dart            # Test data factories
    └── test_helpers.dart              # Test utilities
```

---

## Running Tests

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/unit/bloc/auth_bloc_test.dart

# Run with coverage
flutter test --coverage
```

---

## Test Coverage

### What is Tested

1. **Auth Flow** (`auth_bloc_test.dart`)
   - ✅ Login success
   - ✅ Login failure
   - ✅ Logout
   - ✅ Token refresh check

2. **Trip Loading** (`trip_list_bloc_test.dart`)
   - ✅ Load trips success
   - ✅ Load trips error
   - ✅ Refresh trips
   - ✅ Optimistic delete
   - ✅ Optimistic create

3. **Sync** (`sync_manager_test.dart`)
   - ✅ Sync pending changes
   - ✅ Sync failure handling
   - ✅ Conflict resolution

4. **Widgets** (`trip_card_test.dart`, `loading_states_test.dart`)
   - ✅ Critical widget rendering
   - ✅ User interactions
   - ✅ State-dependent rendering

### What is NOT Tested (Intentionally)

1. **UI Details**
   - Colors, spacing, exact pixel positions
   - **Why**: Visual details change frequently, low value
   - **Alternative**: Manual QA

2. **Third-Party Libraries**
   - Hive, Dio, etc.
   - **Why**: Already tested by maintainers
   - **Alternative**: Integration tests if issues arise

3. **Simple Getters/Setters**
   - Basic model properties
   - **Why**: Low value, high maintenance
   - **Alternative**: Type system

4. **Trivial Widgets**
   - Pure presentational components
   - **Why**: Low risk, high maintenance
   - **Alternative**: Manual testing

5. **Edge Cases**
   - Rare error scenarios
   - **Why**: Low probability, high maintenance
   - **Alternative**: Error boundaries and monitoring

---

## Test Patterns

### BLoC Testing

```dart
blocTest<AuthBloc, AuthState>(
  'description',
  build: () => bloc,
  act: (bloc) => bloc.add(Event()),
  expect: () => [State1(), State2()],
  verify: (_) => verify(...).called(1),
);
```

### Widget Testing

```dart
testWidgets('description', (tester) async {
  await tester.pumpWidget(MyWidget());
  expect(find.text('Expected'), findsOneWidget);
});
```

---

## Maintenance

- **Update tests when behavior changes**: Keep in sync with code
- **Remove obsolete tests**: Delete tests for removed features
- **Refactor tests**: Keep DRY and maintainable
- **Review coverage**: Periodically review what's not covered

---

## Coverage Goals

- **BLoCs**: 80%+ coverage
- **Repositories**: 70%+ coverage
- **Widgets**: 50%+ coverage (key widgets only)
- **Overall**: 60%+ coverage

**Note:** 100% coverage is not the goal. Focus on meaningful tests.

---

## Summary

Tests focus on:
- ✅ Critical business logic
- ✅ State transitions
- ✅ Error handling
- ✅ User interactions

Tests avoid:
- ❌ UI visual details
- ❌ Third-party code
- ❌ Trivial code
- ❌ Low-probability edge cases

This strategy provides meaningful test coverage while avoiding unnecessary maintenance burden.

