import '../../../core/network/api_client.dart';
import '../../../core/network/network_exception.dart';
import '../../models/user.dart';

/// Remote data source for authentication
class AuthRemoteDataSource {
  final ApiClient _apiClient;

  AuthRemoteDataSource(this._apiClient);

  /// Login
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _apiClient.post(
        '/auth/login/',
        data: {
          'email': email,
          'password': password,
        },
      );
      return {
        'access': response.data['access'] as String,
        'refresh': response.data['refresh'] as String,
        'user': UserModel.fromJson(response.data['user'] as Map<String, dynamic>),
      };
    } catch (e) {
      throw NetworkException('Login failed: ${e.toString()}');
    }
  }

  /// Register
  Future<UserModel> register({
    required String email,
    required String password,
    String? firstName,
    String? lastName,
  }) async {
    try {
      final response = await _apiClient.post(
        '/auth/register/',
        data: {
          'email': email,
          'password': password,
          'password_confirm': password,
          if (firstName != null) 'first_name': firstName,
          if (lastName != null) 'last_name': lastName,
        },
      );
      return UserModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw NetworkException('Registration failed: ${e.toString()}');
    }
  }

  /// Get current user
  Future<UserModel> getCurrentUser() async {
    try {
      final response = await _apiClient.get('/auth/me/');
      return UserModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw NetworkException('Failed to get user: ${e.toString()}');
    }
  }

  /// Refresh token
  Future<Map<String, String>> refreshToken(String refreshToken) async {
    try {
      final response = await _apiClient.post(
        '/auth/refresh/',
        data: {'refresh': refreshToken},
      );
      return {
        'access': response.data['access'] as String,
        'refresh': response.data['refresh'] as String? ?? refreshToken,
      };
    } catch (e) {
      throw NetworkException('Token refresh failed: ${e.toString()}');
    }
  }

  /// Logout
  Future<void> logout() async {
    try {
      await _apiClient.post('/auth/logout/');
    } catch (e) {
      // Logout can fail silently
    }
  }
}

