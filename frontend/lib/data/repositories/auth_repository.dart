import '../datasources/remote/auth_remote_ds.dart';
import '../models/user.dart';
import '../../core/services/auth_service.dart';

/// Repository for authentication
class AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  final AuthService _authService;

  AuthRepository({
    required AuthRemoteDataSource remoteDataSource,
    required AuthService authService,
  })  : _remoteDataSource = remoteDataSource,
        _authService = authService;

  /// Login
  Future<UserModel> login(String email, String password) async {
    final result = await _remoteDataSource.login(email, password);
    await _authService.saveTokens(result['access'], result['refresh']);
    return result['user'] as UserModel;
  }

  /// Register
  Future<UserModel> register({
    required String email,
    required String password,
    String? firstName,
    String? lastName,
  }) async {
    return await _remoteDataSource.register(
      email: email,
      password: password,
      firstName: firstName,
      lastName: lastName,
    );
  }

  /// Get current user
  Future<UserModel> getCurrentUser() async {
    return await _remoteDataSource.getCurrentUser();
  }

  /// Check if user is logged in
  Future<bool> isLoggedIn() async {
    return await _authService.isLoggedIn();
  }

  /// Logout
  Future<void> logout() async {
    try {
      await _remoteDataSource.logout();
    } finally {
      await _authService.clearTokens();
    }
  }
}

