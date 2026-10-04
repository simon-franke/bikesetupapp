import 'package:bikesetupapp/common/controllers/operation_controller.dart';
import 'package:bikesetupapp/common/models/command_result.dart';
import 'package:bikesetupapp/features/strava/controllers/strava_controller.dart';
import 'package:bikesetupapp/features/strava/controllers/strava_connection_controller.dart';

class ServicesController extends OperationController {
  ServicesController(this._strava, this._connection, String bikeId)
      : _bikeId = bikeId;
  final StravaController _strava;
  final StravaConnectionController _connection;
  String _bikeId;
  bool _connected = false;
  bool _syncing = false;
  double? _mileageKm;
  DateTime? _lastSyncTime;
  bool _mileageError = false;
  String get bikeId => _bikeId;
  bool get connected => _connected;
  bool get syncing => _syncing;
  double? get mileageKm => _mileageKm;
  DateTime? get lastSyncTime => _lastSyncTime;
  bool get mileageError => _mileageError;

  Future<CommandResult<void>> selectBike(String id) {
    _bikeId = id;
    _mileageKm = null;
    _mileageError = false;
    emit();
    return load();
  }

  Future<CommandResult<void>> load() => command(() async {
        final generation = beginRequest('load');
        await _load(generation);
      });

  Future<void> _load(int generation) async {
    final id = _bikeId;
    try {
      final auth = await _connection.getAuth();
      _check(generation);
      final lastSync = await _connection.getLastSyncTime();
      _check(generation);
      final km = await _strava.getMileageForBike(id);
      _check(generation);
      _connected = auth != null;
      _lastSyncTime = lastSync;
      _mileageKm = km;
      _mileageError = false;
      emit();
    } catch (error) {
      if (isCurrentRequest('load', generation) && error is! CommandAborted) {
        _mileageKm = null;
        _mileageError = true;
        emit();
      }
      rethrow;
    }
  }

  void _check(int generation) {
    if (!isCurrentRequest('load', generation)) throw const CommandAborted();
  }

  Future<CommandResult<void>> sync() => share('sync', () => command(_sync));
  Future<void> _sync() async {
    final generation = beginRequest('load');
    if (!_connected) {
      await _load(generation);
      return;
    }
    _syncing = true;
    emit();
    try {
      final result = await _strava.sync();
      _check(generation);
      if (result.isCancelled) throw const CommandAborted();
      await _load(generation);
      result.requireValue();
    } finally {
      if (!isDisposed) {
        _syncing = false;
        emit();
      }
    }
  }

  Future<CommandResult<void>> connect({required bool web}) => share(
      'connect',
      () => command(() async {
            final generation = beginRequest('load');
            if (web) {
              (await _connection.authorizeWeb()).requireValue();
              return;
            }
            final result = await _connection.authorize();
            _check(generation);
            result.requireValue();
            _connected = true;
            emit();
            await _sync();
          }));
}
