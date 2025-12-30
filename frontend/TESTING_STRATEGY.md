# Testing Strategy

## Overview

This document outlines the testing strategy for the Smart Trip Planner Flutter app, focusing on critical paths and avoiding test bloat.

---

## Testing Philosophy

### What We Test

1. **Critical Business Logic**: Auth flow, data loading, sync
2. **State Transitions**: BLoC state changes
3. **Error Handling**: Error states and recovery
4. **User Flows**: Key user interactions

### What We Don't Test (Intentionally)

1. **UI Rendering Details**: Colors, spacing, exact pixel positions
   - **Why**: These are visual and change frequently
   - **Alternative**: Manual QA and design reviews

2. **Third-Party Libraries**: Hive, Dio, etc.
   - **Why**: These are already tested by their maintainers
   - **Alternative**: Integration tests if issues arise

3. **Simple Getters/Setters**: Basic model properties
   - **Why**: Low value, high maintenance
   - **Alternative**: Type system catches most issues

4. **Trivial Widgets**: Pure presentational components
   - **Why**: Low risk, high maintenance
   - **Alternative**: Manual testing during development

5. **Edge Cases in Non-Critical Paths**: Rare error scenarios
   - **Why**: Low probability, high test maintenance
   - **Alternative**: Error boundaries and monitoring

---

## Test Types

### 1. Unit Tests (BLoC)

**Purpose:** Test business logic in isolation

**Focus:**
- State transitions
- Event handling
- Error scenarios
- Optimistic updates

**Tools:**
- `bloc_test` package
- `mockito` for mocking

**Coverage Target:** 80% of BLoC logic

### 2. Widget Tests

**Purpose:** Test UI components in isolation

**Focus:**
- Critical user-facing widgets
- State-dependent rendering
- User interactions

**Tools:**
- `flutter_test` package
- `mocktail` for mocking

**Coverage Target:** Key widgets only

### 3. Integration Tests (Future)

**Purpose:** Test complete user flows

**Focus:**
- End-to-end scenarios
- Real device testing

**Status:** Not implemented yet (manual testing for now)

---

## Test Structure

```
test/
├── unit/
│   ├── bloc/
│   │   ├── auth_bloc_test.dart
│   │   ├── trip_list_bloc_test.dart
│   │   └── sync_manager_test.dart
│   └── repositories/
│       └── trip_repository_test.dart
│
├── widget/
│   ├── trip_card_test.dart
│   └── loading_states_test.dart
│
└── helpers/
    ├── mock_factories.dart
    └── test_helpers.dart
```

---

## Critical Test Scenarios

### 1. Auth Flow

**Tests:**
- ✅ Login success
- ✅ Login failure (invalid credentials)
- ✅ Token refresh
- ✅ Logout
- ❌ Network timeout (handled by error boundary)
- ❌ Token expiry edge cases (monitored in production)

### 2. Trip Loading

**Tests:**
- ✅ Load trips success
- ✅ Load trips from cache (offline)
- ✅ Load trips error
- ✅ Refresh trips
- ❌ Partial load scenarios (handled by error state)

### 3. Offline-to-Online Sync

**Tests:**
- ✅ Sync pending changes
- ✅ Conflict resolution
- ✅ Sync failure handling
- ❌ Complex merge scenarios (manual testing)

### 4. Error States

**Tests:**
- ✅ Network errors
- ✅ Validation errors
- ✅ Server errors (500)
- ✅ Unauthorized errors
- ❌ All HTTP status codes (covered by error handler)

---

## Test Data

### Mock Factories

Use factories to create test data consistently:

```dart
class MockTripFactory {
  static Trip create({String? id, String? title}) {
    return Trip(
      id: id ?? 'test-id',
      title: title ?? 'Test Trip',
      // ... other fields
    );
  }
}
```

### Test Helpers

Create helpers for common test setup:

```dart
class TestHelpers {
  static TripRepository createMockRepository() {
    return MockTripRepository();
  }
}
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

## Coverage Goals

- **BLoCs**: 80%+ coverage
- **Repositories**: 70%+ coverage
- **Widgets**: 50%+ coverage (key widgets only)
- **Overall**: 60%+ coverage

**Note:** 100% coverage is not the goal. Focus on meaningful tests.

---

## Maintenance Strategy

1. **Update tests when behavior changes**: Keep tests in sync with code
2. **Remove obsolete tests**: Delete tests for removed features
3. **Refactor tests**: Keep tests DRY and maintainable
4. **Review coverage**: Periodically review what's not covered

---

## Summary

### Test Coverage

- ✅ **Critical paths**: Auth, data loading, sync
- ✅ **Error handling**: Network, validation, server errors
- ✅ **State management**: BLoC state transitions
- ❌ **UI details**: Colors, spacing, exact layout
- ❌ **Third-party code**: Libraries are already tested
- ❌ **Edge cases**: Low probability scenarios

### Testing Principles

1. **Test behavior, not implementation**
2. **Focus on critical paths**
3. **Keep tests maintainable**
4. **Avoid test bloat**
5. **Use mocks appropriately**

This strategy provides meaningful test coverage while avoiding unnecessary maintenance burden.

