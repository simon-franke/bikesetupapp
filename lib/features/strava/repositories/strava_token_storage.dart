import 'package:bikesetupapp/common/data/platform_operation.dart';
import 'package:bikesetupapp/common/models/command_result.dart';
import 'package:bikesetupapp/common/controllers/write_queue.dart';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:bikesetupapp/features/strava/models/strava_auth.dart';

class StravaTokenStorage {
  static const _storage = FlutterSecureStorage();
  static final WriteQueue _writes = WriteQueue();
  static Future<void> _mutate(Future<void> Function() action) =>
      _writes.enqueue(
          () => platformOperation(action, fallback: FailureCode.saveFailed));

  static Future<void> saveAuth(StravaAuth auth, {required String userId}) =>
      _mutate(() => _storage.write(
          key: 'strava_auth_$userId', value: jsonEncode(auth.toJson())));

  static Future<StravaAuth?> getAuth({required String userId}) async {
    // Unscoped legacy credentials have no provable owner; never adopt them.
    final raw = await _writes.enqueue(() => platformOperation(
        () => _storage.read(key: 'strava_auth_$userId'),
        fallback: FailureCode.loadFailed));
    if (raw == null) return null;
    try {
      return StravaAuth.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } on FormatException catch (error, stack) {
      throw AppFailure(FailureCode.invalidResponse,
          cause: error, stackTrace: stack);
    } on TypeError catch (error, stack) {
      throw AppFailure(FailureCode.invalidResponse,
          cause: error, stackTrace: stack);
    }
  }

  static Future<void> clearAuth({required String userId}) => _mutate(() async {
        await _storage.delete(key: 'strava_auth_$userId');
        await _storage.delete(key: 'strava_auth');
      });
}
