import '../features/settings/repositories/theme_preferences_repository.dart';
import '../features/settings/repositories/shared_preferences_theme_repository.dart';
import 'startup/startup_controller.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import '../features/bikes/controllers/bikes_controller.dart';
import '../features/bikes/repositories/firestore_bikes_repository.dart';
import '../features/bikes/repositories/bikes_repository.dart';
import '../features/setups/controllers/setups_controller.dart';
import '../features/setups/repositories/firestore_setups_repository.dart';
import '../features/setups/repositories/setups_repository.dart';
import '../features/maintenance/controllers/maintenance_controller.dart';
import '../features/maintenance/repositories/firestore_maintenance_repository.dart';
import '../features/maintenance/repositories/maintenance_repository.dart';
import '../features/strava/controllers/strava_controller.dart';
import '../features/strava/repositories/firestore_strava_bikes_repository.dart';
import '../features/strava/repositories/strava_bikes_repository.dart';
import '../features/auth/controllers/auth_controller.dart';
import '../features/auth/repositories/auth_repository.dart';
import '../features/auth/repositories/firebase_auth_repository.dart';
import '../features/strava/controllers/strava_connection_controller.dart';
import '../features/strava/repositories/platform_strava_repository.dart';
import '../features/strava/repositories/strava_repository.dart';

/// Composition root. Tests can provide this with in-memory repository factories.
class AppDependencies {
  AppDependencies({
    ThemePreferencesRepository? themePreferences,
    AuthRepository? authRepository,
    StravaRepository? stravaRepository,
    BikesRepository Function(String)? bikesRepository,
    SetupsRepository Function(String)? setupsRepository,
    MaintenanceRepository Function(String)? maintenanceRepository,
    StravaBikesRepository Function(String)? stravaBikesRepository,
  })  : themePreferences =
            themePreferences ?? SharedPreferencesThemeRepository(),
        _authRepository = authRepository,
        _stravaRepository = stravaRepository,
        _bikes = bikesRepository ?? ((id) => FirestoreBikesRepository(id)),
        _setups = setupsRepository ?? ((id) => FirestoreSetupsRepository(id)),
        _maintenance = maintenanceRepository ??
            ((id) => FirestoreMaintenanceRepository(id)),
        _stravaBikes = stravaBikesRepository ??
            ((id) => FirestoreStravaBikesRepository(id));

  static final instance = AppDependencies();
  static AppDependencies of(BuildContext context) {
    try {
      return Provider.of<AppDependencies>(context, listen: false);
    } on ProviderNotFoundException {
      return instance;
    }
  }

  final ThemePreferencesRepository themePreferences;
  final AuthRepository? _authRepository;
  final StravaRepository? _stravaRepository;
  final BikesRepository Function(String) _bikes;
  final SetupsRepository Function(String) _setups;
  final MaintenanceRepository Function(String) _maintenance;
  final StravaBikesRepository Function(String) _stravaBikes;
  late final AuthController auth = _own(AuthController(
      _authRepository ?? FirebaseAuthRepository(),
      onSignedOut: clearUsers,
      onSigningOut: () => _connection.clearAuth()));
  late final StravaRepository _connection = _stravaRepository ??
      PlatformStravaRepository(userId: () => auth.currentUser?.uid);
  late final StravaConnectionController stravaConnection =
      _own(StravaConnectionController(_connection));
  final Map<String, UserControllers> _users = {};

  UserControllers forUser(String id) => _users.putIfAbsent(
      id,
      () => UserControllers(
            bikesRepository: () => _bikes(id),
            setupsRepository: () => _setups(id),
            maintenanceRepository: () => _maintenance(id),
            stravaBikesRepository: () => _stravaBikes(id),
            stravaRepository: () => _connection,
          ));

  final List<ChangeNotifier> _owned = [];
  T _own<T extends ChangeNotifier>(T controller) {
    _owned.add(controller);
    return controller;
  }

  void clearUsers() {
    for (final user in _users.values) {
      user.dispose();
    }
    _users.clear();
  }

  void dispose() {
    clearUsers();
    for (final controller in _owned) {
      controller.dispose();
    }
    _owned.clear();
  }
}

class UserControllers {
  UserControllers({
    required BikesRepository Function() bikesRepository,
    required SetupsRepository Function() setupsRepository,
    required MaintenanceRepository Function() maintenanceRepository,
    required StravaBikesRepository Function() stravaBikesRepository,
    required StravaRepository Function() stravaRepository,
  })  : _bikes = bikesRepository,
        _setups = setupsRepository,
        _maintenance = maintenanceRepository,
        _stravaBikes = stravaBikesRepository,
        _connection = stravaRepository;
  final BikesRepository Function() _bikes;
  final SetupsRepository Function() _setups;
  final MaintenanceRepository Function() _maintenance;
  final StravaBikesRepository Function() _stravaBikes;
  final StravaRepository Function() _connection;
  final List<ChangeNotifier> _owned = [];
  T _own<T extends ChangeNotifier>(T controller) {
    _owned.add(controller);
    return controller;
  }

  late final BikesController bikes = _own(BikesController(_bikes(), _setups()));
  late final StartupController startup = StartupController(_bikes(), _setups());
  late final SetupsController setups = _own(SetupsController(_setups()));
  late final MaintenanceController maintenance =
      _own(MaintenanceController(_maintenance()));
  late final StravaController strava =
      _own(StravaController(_stravaBikes(), _connection()));
  void dispose() {
    for (final controller in _owned) {
      controller.dispose();
    }
    _owned.clear();
  }
}
