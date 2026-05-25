import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:bikesetupapp/models/strava_auth.dart';
import 'package:bikesetupapp/app_services/strava_token_storage.dart';
import 'package:bikesetupapp/strava_web_callback_stub.dart'
    if (dart.library.html) 'package:bikesetupapp/strava_web_callback.dart';

class StravaAuthService {
  static const _authorizeUrl = 'https://www.strava.com/oauth/authorize';
  static const _tokenUrl = 'https://www.strava.com/oauth/token';
  static const _deauthorizeUrl = 'https://www.strava.com/oauth/deauthorize';
  static const _redirectUri = 'bikesetup://localhost';
  static const _callbackScheme = 'bikesetup';

  /// The Firebase Function URL that handles the Strava OAuth callback on web.
  /// It exchanges the authorization code for tokens (keeping the client secret
  /// server-side) and redirects back to the app with encoded tokens.
  static const _webCallbackFunctionUrl =
      'https://us-central1-bikesetupapp-bd22a.cloudfunctions.net/stravaCallback';

  String get _clientId => dotenv.env['STRAVA_CLIENT_ID'] ?? '';
  String get _clientSecret => dotenv.env['STRAVA_CLIENT_SECRET'] ?? '';

  Future<StravaAuth?> authorize() async {
    try {
      debugPrint('Strava client_id: "$_clientId"');
      debugPrint('Strava client_secret length: ${_clientSecret.length}');
      debugPrint('dotenv keys: ${dotenv.env.keys.toList()}');

      final url = Uri.parse('$_authorizeUrl'
          '?client_id=$_clientId'
          '&response_type=code'
          '&redirect_uri=$_redirectUri'
          '&scope=read,profile:read_all,activity:read'
          '&approval_prompt=auto');

      final result = await FlutterWebAuth2.authenticate(
        url: url.toString(),
        callbackUrlScheme: _callbackScheme,
      );

      final code = Uri.parse(result).queryParameters['code'];
      if (code == null) return null;

      return _exchangeToken(code);
    } catch (e) {
      debugPrint('Strava authorize error: $e');
      return null;
    }
  }

  Future<StravaAuth?> _exchangeToken(String code) async {
    try {
      debugPrint('Token exchange - client_id: "$_clientId", code: "$code"');
      final response = await http.post(
        Uri.parse(_tokenUrl),
        body: {
          'client_id': _clientId,
          'client_secret': _clientSecret,
          'code': code,
          'grant_type': 'authorization_code',
        },
      );
      debugPrint('Token exchange response: ${response.statusCode} ${response.body}');
      if (response.statusCode != 200) return null;

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final auth = StravaAuth(
        accessToken: json['access_token'] as String? ?? '',
        refreshToken: json['refresh_token'] as String? ?? '',
        expiresAt: json['expires_at'] as int? ?? 0,
        athleteId: (json['athlete'] as Map<String, dynamic>?)?['id'] as int? ?? 0,
      );
      await StravaTokenStorage.saveAuth(auth);
      return auth;
    } catch (e) {
      debugPrint('Strava token exchange error: $e');
      return null;
    }
  }

  Future<StravaAuth?> refreshToken(StravaAuth current) async {
    try {
      final response = await http.post(
        Uri.parse(_tokenUrl),
        body: {
          'client_id': _clientId,
          'client_secret': _clientSecret,
          'refresh_token': current.refreshToken,
          'grant_type': 'refresh_token',
        },
      );
      if (response.statusCode != 200) return null;

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final auth = StravaAuth(
        accessToken: json['access_token'] as String? ?? '',
        refreshToken: json['refresh_token'] as String? ?? '',
        expiresAt: json['expires_at'] as int? ?? 0,
        athleteId: current.athleteId,
      );
      await StravaTokenStorage.saveAuth(auth);
      return auth;
    } catch (e) {
      debugPrint('Strava token refresh error: $e');
      return null;
    }
  }

  Future<String?> getValidToken() async {
    var auth = await StravaTokenStorage.getAuth();
    if (auth == null) return null;

    if (auth.isExpired) {
      auth = await refreshToken(auth);
      if (auth == null) return null;
    }
    return auth.accessToken;
  }

  /// Web-only: builds the Strava authorization URL pointing to the Firebase
  /// Function as the redirect URI, then navigates the current browser tab to
  /// it. The function will redirect back to the app with encoded tokens.
  ///
  /// The page navigates away immediately — there is no return value.
  /// Tokens are saved by [handleStravaWebCallback] on the next app startup.
  Future<void> authorizeWeb() async {
    openStravaAuthInTab(buildWebAuthUrl());
  }

  /// Returns the Strava OAuth authorization URL for use on web (redirect URI
  /// points to the Firebase Function proxy instead of the custom scheme).
  String buildWebAuthUrl() {
    return '$_authorizeUrl'
        '?client_id=$_clientId'
        '&response_type=code'
        '&redirect_uri=${Uri.encodeComponent(_webCallbackFunctionUrl)}'
        '&scope=read,profile:read_all,activity:read'
        '&approval_prompt=auto';
  }

  Future<void> deauthorize() async {
    final auth = await StravaTokenStorage.getAuth();
    if (auth != null) {
      try {
        await http.post(
          Uri.parse(_deauthorizeUrl),
          body: {'access_token': auth.accessToken},
        );
      } catch (e) {
        debugPrint('Strava deauthorize error: $e');
      }
    }
    await StravaTokenStorage.clearAuth();
  }
}
