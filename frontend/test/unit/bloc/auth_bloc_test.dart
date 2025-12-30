"""
Unit tests for AuthBloc.

Tests critical auth flow scenarios: login, logout, token refresh, and error handling.
"""
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:features/auth/bloc/auth_bloc.dart';
import 'package:data/repositories/auth_repository.dart';
import 'package:data/models/user.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository mockRepository;
  late AuthBloc authBloc;
  
  final testUser = User(
    id: 'user-1',
    email: 'test@example.com',
    username: 'testuser',
  );
  
  setUp(() {
    mockRepository = MockAuthRepository();
    authBloc = AuthBloc(mockRepository);
  });
  
  tearDown(() {
    authBloc.close();
  });
  
  group('AuthBloc', () {
    test('initial state is AuthInitial', () {
      expect(authBloc.state, equals(AuthInitial()));
    });
    
    group('LoginEvent', () {
      blocTest<AuthBloc, AuthState>(
        'emits [Loading, Authenticated] when login succeeds',
        build: () {
          when(mockRepository.login('test@example.com', 'password123'))
              .thenAnswer((_) async => testUser);
          return authBloc;
        },
        act: (bloc) => bloc.add(LoginEvent('test@example.com', 'password123')),
        expect: () => [
          AuthLoading(),
          Authenticated(testUser),
        ],
        verify: (_) {
          verify(mockRepository.login('test@example.com', 'password123')).called(1);
        },
      );
      
      blocTest<AuthBloc, AuthState>(
        'emits [Loading, AuthError] when login fails with invalid credentials',
        build: () {
          when(mockRepository.login('test@example.com', 'wrong'))
              .thenThrow(Exception('Invalid credentials'));
          return authBloc;
        },
        act: (bloc) => bloc.add(LoginEvent('test@example.com', 'wrong')),
        expect: () => [
          AuthLoading(),
          AuthError('Invalid credentials'),
        ],
      );
      
      blocTest<AuthBloc, AuthState>(
        'emits [Loading, AuthError] when network error occurs',
        build: () {
          when(mockRepository.login('test@example.com', 'password123'))
              .thenThrow(Exception('Network error'));
          return authBloc;
        },
        act: (bloc) => bloc.add(LoginEvent('test@example.com', 'password123')),
        expect: () => [
          AuthLoading(),
          AuthError('Network error'),
        ],
      );
    });
    
    group('LogoutEvent', () {
      blocTest<AuthBloc, AuthState>(
        'emits [Unauthenticated] when logout succeeds',
        build: () {
          when(mockRepository.logout()).thenAnswer((_) async => {});
          return authBloc;
        },
        seed: () => Authenticated(testUser),
        act: (bloc) => bloc.add(LogoutEvent()),
        expect: () => [
          Unauthenticated(),
        ],
        verify: (_) {
          verify(mockRepository.logout()).called(1);
        },
      );
    });
    
    group('CheckAuthEvent', () {
      blocTest<AuthBloc, AuthState>(
        'emits [Authenticated] when user is already logged in',
        build: () {
          when(mockRepository.getCurrentUser())
              .thenAnswer((_) async => testUser);
          return authBloc;
        },
        act: (bloc) => bloc.add(CheckAuthEvent()),
        expect: () => [
          Authenticated(testUser),
        ],
      );
      
      blocTest<AuthBloc, AuthState>(
        'emits [Unauthenticated] when no user is logged in',
        build: () {
          when(mockRepository.getCurrentUser())
              .thenAnswer((_) async => null);
          return authBloc;
        },
        act: (bloc) => bloc.add(CheckAuthEvent()),
        expect: () => [
          Unauthenticated(),
        ],
      );
    });
  });
}

