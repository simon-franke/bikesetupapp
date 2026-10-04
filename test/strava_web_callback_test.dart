@TestOn('browser')
library;

import 'dart:convert';
import 'package:bikesetupapp/features/strava/models/strava_auth.dart';
import 'package:bikesetupapp/features/strava/repositories/strava_token_storage.dart';
import 'package:bikesetupapp/features/strava/platform/strava_web_callback.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:web/web.dart' as web;

void main() {
  late String originalUrl;
  const state = 'pending-state';
  final payload = base64Url
      .encode(utf8.encode(jsonEncode({
        'access_token': 'test-access',
        'refresh_token': 'test-refresh',
        'expires_at': 2000000000,
        'athlete': {'id': 42},
        'scope': 'read,profile:read_all,activity:read_all',
      })))
      .replaceAll('=', '');
  const previous = StravaAuth(
      accessToken: 'previous',
      refreshToken: 'previous',
      expiresAt: 2000000000,
      athleteId: 99);

  void setUrl(
      {String? auth, String? callbackState = state, bool otherParams = true}) {
    final uri = Uri.parse(originalUrl).replace(queryParameters: {
      if (otherParams) 'view': 'setup',
      if (auth != null) 'strava_auth': auth,
      if (auth != null && callbackState != null) 'strava_state': callbackState,
    }, fragment: 'rear-tire');
    web.window.history.replaceState(null, '', uri.toString());
  }

  setUp(() {
    originalUrl = web.window.location.href;
    FlutterSecureStorage.setMockInitialValues({});
    clearPendingStravaWebAuth();
  });
  tearDown(() {
    clearPendingStravaWebAuth();
    web.window.history.replaceState(null, '', originalUrl);
  });

  test('ordinary visits leave URL and auth untouched', () async {
    setUrl();
    final before = web.window.location.href;
    expect(await handleStravaWebCallback(userId: 'user'), isFalse);
    expect(web.window.location.href, before);
    expect(await StravaTokenStorage.getAuth(userId: 'user'), isNull);
  });
  test('matching callback saves scoped tokens and granted scopes once',
      () async {
    rememberStravaWebAuth(userId: 'user', state: state);
    setUrl(auth: payload);
    expect(await handleStravaWebCallback(userId: 'user'), isTrue);
    final auth = await StravaTokenStorage.getAuth(userId: 'user');
    expect(auth?.accessToken, 'test-access');
    expect(auth?.refreshToken, 'test-refresh');
    expect(auth?.athleteId, 42);
    expect(auth?.scopes, contains('activity:read_all'));
    expect(await StravaTokenStorage.getAuth(userId: 'other'), isNull);
    final cleaned = Uri.parse(web.window.location.href);
    expect(cleaned.queryParameters, {'view': 'setup'});
    expect(cleaned.fragment, 'rear-tire');
    setUrl(auth: payload);
    expect(await handleStravaWebCallback(userId: 'user'), isFalse);
  });
  test('callback also removes credentials when there are no other parameters',
      () async {
    rememberStravaWebAuth(userId: 'user', state: state);
    setUrl(auth: payload, otherParams: false);
    expect(await handleStravaWebCallback(userId: 'user'), isTrue);
    expect(Uri.parse(web.window.location.href).queryParameters, isEmpty);
  });
  for (final mode in [
    'unsolicited',
    'wrong-state',
    'missing-state',
    'wrong-user',
    'signed-out',
    'expired'
  ]) {
    test('$mode callback cannot replace existing credentials', () async {
      await StravaTokenStorage.saveAuth(previous, userId: 'user');
      if (mode != 'unsolicited') {
        rememberStravaWebAuth(userId: 'user', state: state);
      }
      if (mode == 'expired') {
        web.window.sessionStorage.setItem(
            'strava_pending_auth',
            jsonEncode({
              'userId': 'user',
              'state': state,
              'createdAt': DateTime.now()
                  .subtract(const Duration(minutes: 11))
                  .millisecondsSinceEpoch,
            }));
      }
      setUrl(
          auth: payload,
          callbackState: mode == 'wrong-state'
              ? 'wrong'
              : mode == 'missing-state'
                  ? null
                  : state);
      expect(
          await handleStravaWebCallback(
              userId: mode == 'signed-out'
                  ? null
                  : mode == 'wrong-user'
                      ? 'other'
                      : 'user'),
          isFalse);
      expect((await StravaTokenStorage.getAuth(userId: 'user'))?.accessToken,
          'previous');
      expect(Uri.parse(web.window.location.href).queryParameters,
          {'view': 'setup'});
    });
  }
  for (final invalid in ['error', '%%%', base64Url.encode(utf8.encode('{}'))]) {
    test(
        'denied or invalid payload consumes state without replacing tokens: $invalid',
        () async {
      await StravaTokenStorage.saveAuth(previous, userId: 'user');
      rememberStravaWebAuth(userId: 'user', state: state);
      setUrl(auth: invalid);
      expect(await handleStravaWebCallback(userId: 'user'), isFalse);
      expect((await StravaTokenStorage.getAuth(userId: 'user'))?.accessToken,
          'previous');
      setUrl(auth: payload);
      expect(await handleStravaWebCallback(userId: 'user'), isFalse);
    });
  }
  test('redirect helper updates current tab location', () {
    final target = Uri.parse(originalUrl)
        .replace(fragment: 'oauth-redirect-test')
        .toString();
    openStravaAuthInTab(target);
    expect(web.window.location.href, target);
  });
}
