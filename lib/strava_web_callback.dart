// Web implementation: parses the Strava auth payload that the Firebase
// Function encodes into the URL after a successful OAuth exchange, saves the
// tokens, and strips the param from the browser's address bar.
//
// Imported via conditional import — the stub at
// strava_web_callback_stub.dart is used on all non-web platforms.

import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import 'package:bikesetupapp/app_services/strava_token_storage.dart';
import 'package:bikesetupapp/models/strava_auth.dart';

/// Checks whether the current URL contains a `strava_auth` query parameter
/// written by the Firebase Function redirect.
///
/// Returns `true` if tokens were successfully saved (new auth).
/// Returns `false` if there was no callback, or if it was an error.
Future<bool> handleStravaWebCallback() async {
  final uri = Uri.parse(html.window.location.href);
  final encoded = uri.queryParameters['strava_auth'];

  // Nothing to handle on a normal app load.
  if (encoded == null) return false;

  // Always strip the param so a page refresh does not re-process it.
  _stripStravaAuthParam(uri);

  if (encoded == 'error') return false;

  try {
    // The Firebase Function uses Buffer.toString('base64url') — URL-safe
    // base64 with no padding. Dart's base64Url codec with normalize() handles
    // the missing padding.
    final bytes = base64Url.decode(base64Url.normalize(encoded));
    final json = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;

    // The Firebase Function forwards Strava's raw response, which uses
    // snake_case keys and nests the athlete under an 'athlete' object.
    final auth = StravaAuth(
      accessToken: json['access_token'] as String? ?? '',
      refreshToken: json['refresh_token'] as String? ?? '',
      expiresAt: json['expires_at'] as int? ?? 0,
      athleteId: (json['athlete'] as Map<String, dynamic>?)?['id'] as int? ?? 0,
    );

    await StravaTokenStorage.saveAuth(auth);
    return true;
  } catch (e) {
    // Malformed payload — silently ignore so the app still loads normally.
    return false;
  }
}

/// Navigates the current browser tab to [url].
///
/// This is a full-page navigation (not a new tab or popup), which avoids
/// popup blockers. The Firebase Function will redirect back to the app after
/// the token exchange.
void openStravaAuthInTab(String url) {
  html.window.location.href = url;
}

void _stripStravaAuthParam(Uri uri) {
  final params = Map<String, String>.from(uri.queryParameters)
    ..remove('strava_auth');
  final cleaned = uri.replace(queryParameters: params.isEmpty ? null : params);
  html.window.history.replaceState(null, '', cleaned.toString());
}
