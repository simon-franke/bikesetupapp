import 'package:firebase_auth/firebase_auth.dart';
import 'package:bikesetupapp/common/controllers/operation_controller.dart';
import 'package:bikesetupapp/features/auth/controllers/auth_controller.dart';
import 'package:bikesetupapp/features/strava/controllers/strava_controller.dart';
import 'package:bikesetupapp/features/strava/controllers/strava_connection_controller.dart';

class SettingsController extends OperationController {
  SettingsController(this._auth, this._connection, this._stravaForUser)
      : user = _auth.currentUser;
  final AuthController _auth;
  final StravaConnectionController _connection;
  final StravaController Function(String) _stravaForUser;
  User? user;
  bool connected = false;
  int? athleteId;
  int bikeCount = 0;
  int _generation = 0;

  Future<void> load() async {
    final generation = ++_generation;
    final auth = await _connection.getAuth();
    var count = 0;
    final currentUser = user;
    if (auth != null && currentUser != null) {
      try {
        count = (await _stravaForUser(currentUser.uid).getStravaBikes().first)
            .length;
      } catch (_) {
        /* Bike count is optional; connection state remains available. */
      }
    }
    if (isDisposed || generation != _generation) return;
    connected = auth != null;
    athleteId = auth?.athleteId;
    bikeCount = count;
    emit();
  }

  Future<String?> connect() async {
    final auth = await _connection.authorize();
    if (auth == null || isDisposed) return null;
    connected = true;
    athleteId = auth.athleteId;
    emit();
    final currentUser = user;
    String? message;
    if (currentUser != null) {
      final strava = _stravaForUser(currentUser.uid);
      if (!await strava.sync()) {
        message = strava.lastError ?? 'Could not sync Strava. Try again.';
      }
      await load();
    }
    return message;
  }

  Future<void> connectWeb() => _connection.authorizeWeb();
  Future<void> disconnect() => run(() async {
        ++_generation;
        final currentUser = user;
        await _connection.deauthorize();
        if (currentUser != null) {
          await _stravaForUser(currentUser.uid).deleteAllStravaBikes();
        }
        connected = false;
        athleteId = null;
        bikeCount = 0;
        emit();
      });
  Future<void> signOut() => run(() async {
        ++_generation;
        await _auth.signOut();
        user = null;
        emit();
      });
}
