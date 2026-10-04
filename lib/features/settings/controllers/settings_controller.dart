import 'package:firebase_auth/firebase_auth.dart';
import 'package:bikesetupapp/common/controllers/operation_controller.dart';
import 'package:bikesetupapp/common/models/command_result.dart';
import 'package:bikesetupapp/features/auth/controllers/auth_controller.dart';
import 'package:bikesetupapp/features/strava/controllers/strava_controller.dart';
import 'package:bikesetupapp/features/strava/controllers/strava_connection_controller.dart';

class SettingsController extends OperationController {
  SettingsController(this._auth, this._connection, this._stravaForUser)
      : _user = _auth.currentUser;
  final AuthController _auth;
  final StravaConnectionController _connection;
  final StravaController Function(String) _stravaForUser;
  User? _user;
  bool _connected = false;
  int? _athleteId;
  int _bikeCount = 0;
  User? get user => _user;
  bool get connected => _connected;
  int? get athleteId => _athleteId;
  int get bikeCount => _bikeCount;

  void _check(int generation) {
    if (!isCurrentRequest('state', generation)) throw const CommandAborted();
  }

  Future<CommandResult<void>> load() =>
      command(() => _load(beginRequest('state')));
  Future<void> _load(int generation) async {
    final auth = await _connection.getAuth();
    _check(generation);
    final currentUser = _user;
    final count = auth == null || currentUser == null
        ? 0
        : (await _stravaForUser(currentUser.uid).getStravaBikes().first).length;
    _check(generation);
    _connected = auth != null;
    _athleteId = auth?.athleteId;
    _bikeCount = count;
    emit();
  }

  Future<CommandResult<void>> connect() => share(
      'connect',
      () => command(() async {
            final generation = beginRequest('state');
            final auth = (await _connection.authorize()).requireValue();
            _check(generation);
            _connected = true;
            _athleteId = auth.athleteId;
            emit();
            final currentUser = _user;
            if (currentUser != null) {
              final result = await _stravaForUser(currentUser.uid).sync();
              _check(generation);
              if (result.isCancelled) throw const CommandAborted();
              await _load(generation);
              result.requireValue();
            }
          }));
  Future<CommandResult<void>> connectWeb() => share(
      'connectWeb',
      () => command(() async {
            beginRequest('state');
            (await _connection.authorizeWeb()).requireValue();
          }));
  Future<CommandResult<void>> disconnect() => share(
      'disconnect',
      () => command(() async {
            final generation = beginRequest('state');
            final currentUser = _user;
            (await _connection.deauthorize()).requireValue();
            _check(generation);
            if (currentUser != null) {
              (await _stravaForUser(currentUser.uid).deleteAllStravaBikes())
                  .requireValue();
              _check(generation);
            }
            _connected = false;
            _athleteId = null;
            _bikeCount = 0;
            emit();
          }));
  Future<CommandResult<void>> signOut() => share(
      'signOut',
      () => command(() async {
            final generation = beginRequest('state');
            (await _auth.signOut()).requireValue();
            _check(generation);
            _user = null;
            _connected = false;
            _athleteId = null;
            _bikeCount = 0;
            emit();
          }));
}
