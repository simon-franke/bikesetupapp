import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:bikesetupapp/models/strava_auth.dart';

class StravaTokenStorage {
  static const _key = 'strava_auth';
  static const _storage = FlutterSecureStorage();

  static Future<void> saveAuth(StravaAuth auth) async {
    await _storage.write(key: _key, value: jsonEncode(auth.toJson()));
  }

  static Future<StravaAuth?> getAuth() async {
    final raw = await _storage.read(key: _key);
    if (raw == null) return null;
    return StravaAuth.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  static Future<void> clearAuth() async {
    await _storage.delete(key: _key);
  }
}
