import 'dart:async';
import 'package:flutter/services.dart';
import 'package:bikesetupapp/common/models/command_result.dart';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:bikesetupapp/features/strava/models/strava_auth.dart';
import 'package:bikesetupapp/features/strava/models/strava_exception.dart';
import 'package:bikesetupapp/features/strava/repositories/strava_token_storage.dart';
import 'package:bikesetupapp/features/strava/platform/strava_web_callback_stub.dart'
    if (dart.library.js_interop) 'package:bikesetupapp/features/strava/platform/strava_web_callback.dart';

class StravaAuthService {
  StravaAuthService(
      {required String? Function() userId, http.Client? client, bool? web})
      : _userId = userId,
        _client = client,
        _web = web ?? kIsWeb;
  final String? Function() _userId;
  final http.Client? _client;
  final bool _web;
  int _generation = 0;
  final Map<String, Future<StravaAuth?>> _refreshes = {};
  static const _authorizeUrl = 'https://www.strava.com/oauth/authorize';
  static const _tokenUrl = 'https://www.strava.com/oauth/token';
  static const _deauthorizeUrl = 'https://www.strava.com/oauth/deauthorize';
  static const _redirectUri = 'bikesetup://localhost';
  static const _callbackScheme = 'bikesetup';
  static const _functionBase =
      'https://us-central1-bikesetupapp-bd22a.cloudfunctions.net';
  static const _requestedScopes = 'read,profile:read_all,activity:read_all';

  String get _clientId => dotenv.env['STRAVA_CLIENT_ID'] ?? '';
  String get _clientSecret => dotenv.env['STRAVA_CLIENT_SECRET'] ?? '';

  Future<http.Response> _post(Uri uri, Map<String, String> body) async {
    try {
      return await (_client?.post(uri, body: body) ??
              http.post(uri, body: body))
          .timeout(const Duration(seconds: 15));
    } on http.ClientException catch (error, stack) {
      throw AppFailure(FailureCode.network, cause: error, stackTrace: stack);
    } on TimeoutException catch (error, stack) {
      throw AppFailure(FailureCode.network, cause: error, stackTrace: stack);
    }
  }

  String _newState() {
    final random = Random.secure();
    return base64Url
        .encode(List<int>.generate(32, (_) => random.nextInt(256)))
        .replaceAll('=', '');
  }

  Future<StravaAuth?> getAuth() async {
    final owner = _userId();
    final generation = _generation;
    if (owner == null) return null;
    final auth = await StravaTokenStorage.getAuth(userId: owner);
    return _userId() == owner && generation == _generation ? auth : null;
  }

  Future<StravaAuth?> authorize() async {
    final owner = _userId();
    if (owner == null) return null;
    final generation = ++_generation;
    final state = _newState();
    try {
      final result = await FlutterWebAuth2.authenticate(
          url: _authUrl(_redirectUri, state),
          callbackUrlScheme: _callbackScheme);
      final callback = Uri.parse(result);
      if (callback.queryParameters['state'] != state) return null;
      final code = callback.queryParameters['code'];
      if (code == null) return null;
      final response = await _post(Uri.parse(_tokenUrl), {
        'client_id': _clientId,
        'client_secret': _clientSecret,
        'code': code,
        'grant_type': 'authorization_code',
      });
      if (response.statusCode != 200) {
        throw AppFailure(FailureCode.connectionExpired,
            statusCode: response.statusCode);
      }
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final auth = StravaAuth.fromTokenResponse(json,
          scopes: StravaAuth.parseScopes(callback.queryParameters['scope']));
      if (_userId() != owner || generation != _generation) return null;
      await StravaTokenStorage.saveAuth(auth, userId: owner);
      return auth;
    } on PlatformException catch (error, stack) {
      if (error.code.toLowerCase().contains('cancel')) return null;
      throw AppFailure(FailureCode.authenticationFailed,
          cause: error, stackTrace: stack);
    } on FormatException catch (error, stack) {
      throw AppFailure(FailureCode.invalidResponse,
          cause: error, stackTrace: stack);
    } on TypeError catch (error, stack) {
      throw AppFailure(FailureCode.invalidResponse,
          cause: error, stackTrace: stack);
    }
  }

  Future<StravaAuth?> refreshToken(StravaAuth current) {
    final owner = _userId();
    if (owner == null) return Future.value(null);
    return _refreshes.putIfAbsent(
        owner,
        () => _refreshToken(current, owner, _generation).whenComplete(() {
              _refreshes.remove(owner);
            }));
  }

  Future<StravaAuth?> _refreshToken(
      StravaAuth current, String owner, int generation) async {
    try {
      final response = await _post(
          Uri.parse(_web ? '$_functionBase/stravaRefresh' : _tokenUrl), {
        if (!_web) ...{
          'client_id': _clientId,
          'client_secret': _clientSecret,
          'grant_type': 'refresh_token'
        },
        'refresh_token': current.refreshToken,
      });
      if (response.statusCode != 200) {
        throw AppFailure(FailureCode.connectionExpired,
            statusCode: response.statusCode);
      }
      final auth = StravaAuth.fromTokenResponse(
          jsonDecode(response.body) as Map<String, dynamic>,
          athleteId: current.athleteId,
          scopes: current.scopes);
      if (_userId() != owner || generation != _generation) return null;
      await StravaTokenStorage.saveAuth(auth, userId: owner);
      return auth;
    } on FormatException catch (error, stack) {
      throw AppFailure(FailureCode.invalidResponse,
          cause: error, stackTrace: stack);
    } on TypeError catch (error, stack) {
      throw AppFailure(FailureCode.invalidResponse,
          cause: error, stackTrace: stack);
    }
  }

  Future<String?> getValidToken() async {
    final generation = _generation;
    final owner = _userId();
    var auth = await getAuth();
    if (auth == null || _userId() != owner || generation != _generation) {
      return null;
    }
    if (auth.isExpired) auth = await refreshToken(auth);
    return _userId() == owner && generation == _generation
        ? auth?.accessToken
        : null;
  }

  Future<String?> getMileageToken() async {
    final owner = _userId();
    final auth = await getAuth();
    if (auth == null || _userId() != owner) return null;
    if (!auth.scopes.contains('activity:read_all')) {
      throw const StravaInsufficientScopeException();
    }
    final token = await getValidToken();
    return _userId() == owner ? token : null;
  }

  Future<void> authorizeWeb() async {
    ++_generation;
    final owner = _userId();
    if (owner == null) throw const AppFailure(FailureCode.authenticationFailed);
    final state = _newState();
    rememberStravaWebAuth(userId: owner, state: state);
    openStravaAuthInTab(buildWebAuthUrl(state: state));
  }

  String _authUrl(String redirect, String state) =>
      Uri.parse(_authorizeUrl).replace(queryParameters: {
        'client_id': _clientId,
        'response_type': 'code',
        'redirect_uri': redirect,
        'scope': _requestedScopes,
        'approval_prompt': 'force',
        'state': state
      }).toString();

  String buildWebAuthUrl({required String state}) =>
      _authUrl('$_functionBase/stravaCallback', state);

  Future<void> clearAuth() async {
    ++_generation;
    clearPendingStravaWebAuth();
    final owner = _userId();
    if (owner != null) await StravaTokenStorage.clearAuth(userId: owner);
  }

  Future<void> deauthorize() async {
    final owner = _userId();
    final auth = await getAuth();
    if (owner != _userId()) return;
    await clearAuth();
    if (auth != null) {
      try {
        await _post(
            Uri.parse(_deauthorizeUrl), {'access_token': auth.accessToken});
      } on AppFailure {/* Local credentials are already cleared. */}
    }
  }
}
