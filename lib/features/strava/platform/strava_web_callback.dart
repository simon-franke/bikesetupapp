import 'dart:convert';
import 'package:bikesetupapp/features/strava/repositories/strava_token_storage.dart';
import 'package:bikesetupapp/features/strava/models/strava_auth.dart';
import 'package:web/web.dart' as web;

const _pendingKey = 'strava_pending_auth';

/// Session storage binds the callback to the initiating tab and Firebase user.
void rememberStravaWebAuth({required String userId, required String state}) {
  web.window.sessionStorage.setItem(
      _pendingKey,
      jsonEncode({
        'userId': userId,
        'state': state,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      }));
}

void clearPendingStravaWebAuth() =>
    web.window.sessionStorage.removeItem(_pendingKey);

Future<bool> handleStravaWebCallback({required String? userId}) async {
  final uri = Uri.parse(web.window.location.href);
  final encoded = uri.queryParameters['strava_auth'];
  if (encoded == null) return false;
  final state = uri.queryParameters['strava_state'];
  final params = Map<String, String>.from(uri.queryParameters)
    ..remove('strava_auth')
    ..remove('strava_state');
  web.window.history
      .replaceState(null, '', uri.replace(queryParameters: params).toString());

  try {
    final raw = web.window.sessionStorage.getItem(_pendingKey);
    if (raw == null || userId == null) return false;
    final pending = jsonDecode(raw) as Map<String, dynamic>;
    final age =
        DateTime.now().millisecondsSinceEpoch - (pending['createdAt'] as int);
    if (state == null ||
        state != pending['state'] ||
        userId != pending['userId'] ||
        age < 0 ||
        age > const Duration(minutes: 10).inMilliseconds) {
      return false;
    }
    // A matching callback is consumed even if denied or malformed.
    clearPendingStravaWebAuth();
    if (encoded == 'error') return false;
    final json =
        jsonDecode(utf8.decode(base64Url.decode(base64Url.normalize(encoded))))
            as Map<String, dynamic>;
    final auth = StravaAuth.fromTokenResponse(json,
        scopes: StravaAuth.parseScopes(json['scope'] as String?));
    await StravaTokenStorage.saveAuth(auth, userId: userId);
    return true;
  } catch (_) {
    return false;
  }
}

void openStravaAuthInTab(String url) => web.window.location.href = url;
