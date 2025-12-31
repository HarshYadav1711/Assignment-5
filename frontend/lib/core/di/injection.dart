import '../network/api_client.dart';
import '../services/auth_service.dart';
import '../storage/local_db.dart';
import '../storage/preferences.dart';
import '../../data/datasources/remote/auth_remote_ds.dart';
import '../../data/datasources/remote/trip_remote_ds.dart';
import '../../data/datasources/local/trip_local_ds.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/trip_repository.dart';
import '../../features/auth/bloc/auth_bloc.dart';
import '../../features/trips/bloc/trip_list_bloc.dart';

/// Dependency injection container
class Injection {
  static late final ApiClient apiClient;
  static late final AuthService authService;
  static late final AuthRepository authRepository;
  static late final TripRepository tripRepository;
  static late final AuthBloc authBloc;
  static late final TripListBloc tripListBloc;

  /// Initialize all dependencies
  static Future<void> init() async {
    // Initialize storage
    await AppPreferences.init();
    await LocalDatabase.init();

    // Core services
    apiClient = ApiClient();
    authService = AuthService();

    // Data sources
    final authRemoteDs = AuthRemoteDataSource(apiClient);
    final tripRemoteDs = TripRemoteDataSource(apiClient);
    final tripLocalDs = TripLocalDataSource();

    // Repositories
    authRepository = AuthRepository(
      remoteDataSource: authRemoteDs,
      authService: authService,
    );
    tripRepository = TripRepository(
      remoteDataSource: tripRemoteDs,
      localDataSource: tripLocalDs,
    );

    // BLoCs
    authBloc = AuthBloc(authRepository);
    tripListBloc = TripListBloc(tripRepository);
  }
}

