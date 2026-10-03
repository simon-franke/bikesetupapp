import 'package:bikesetupapp/common/controllers/operation_controller.dart';
import 'package:bikesetupapp/features/strava/controllers/strava_controller.dart';
import 'package:bikesetupapp/features/strava/controllers/strava_connection_controller.dart';

class ServicesController extends OperationController {
  ServicesController(this._strava, this._connection, this.bikeId);
  final StravaController _strava;
  final StravaConnectionController _connection;
  String bikeId;
  bool connected = false;
  bool syncing = false;
  double? mileageKm;
  DateTime? lastSyncTime;
  bool mileageError = false;
  int _loadGeneration = 0;

  void selectBike(String id) {
    bikeId = id;
    mileageKm = null;
    loadMileage();
  }

  Future<void> load() async {
    try {
      final auth = await _connection.getAuth();
      final lastSync = await _connection.getLastSyncTime();
      if (isDisposed) return;
      connected = auth != null;
      lastSyncTime = lastSync;
      emit();
      await loadMileage();
    } catch (_) {
      mileageError = true;
      emit();
    }
  }

  Future<void> loadMileage() async {
    final id = bikeId;
    final generation = ++_loadGeneration;
    try {
      final km = await _strava.getMileageForBike(id);
      if (isDisposed || generation != _loadGeneration || id != bikeId) return;
      mileageKm = km;
      mileageError = false;
    } catch (_) {
      if (isDisposed || generation != _loadGeneration || id != bikeId) return;
      mileageKm = null;
      mileageError = true;
    }
    emit();
  }

  Future<String?> sync() async {
    if (syncing) return null;
    if (!connected) {
      await loadMileage();
      return null;
    }
    syncing = true;
    emit();
    try {
      final synced = await _strava.sync();
      await load();
      return synced
          ? null
          : _strava.lastError ?? 'Could not sync Strava. Try again.';
    } catch (_) {
      return 'Could not load mileage. Try again.';
    } finally {
      syncing = false;
      emit();
    }
  }

  Future<String?> connect({required bool web}) async {
    if (web) {
      await _connection.authorizeWeb();
      return null;
    }
    final auth = await _connection.authorize();
    if (auth == null || isDisposed) return null;
    connected = true;
    emit();
    return sync();
  }
}
