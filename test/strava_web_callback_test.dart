@TestOn('browser')
library;

import 'dart:convert';

import 'package:bikesetupapp/app_services/strava_token_storage.dart';
import 'package:bikesetupapp/strava_web_callback.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:web/web.dart' as web;

void main() {
  late String originalUrl;

  void setUrl({String? auth}) {
    final uri = Uri.parse(originalUrl).replace(
      queryParameters: {'view': 'setup', if (auth != null) 'strava_auth': auth},
      fragment: 'rear-tire',
    );
    web.window.history.replaceState(null, '', uri.toString());
  }

  setUp(() {
    originalUrl = web.window.location.href;
    FlutterSecureStorage.setMockInitialValues({});
  });

  tearDown(() {
    web.window.history.replaceState(null, '', originalUrl);
  });

  test('ordinary visits leave the URL and stored auth untouched', () async {
    setUrl();
    final before = web.window.location.href;
    expect(await handleStravaWebCallback(), isFalse);
    expect(web.window.location.href, before);
    expect(await StravaTokenStorage.getAuth(), isNull);
  });

  test('callback saves tokens and removes only the OAuth query parameter',
      () async {
    final payload = base64Url
        .encode(utf8.encode(jsonEncode({
          'access_token': 'test-access',
          'refresh_token': 'test-refresh',
          'expires_at': 2000000000,
          'athlete': {'id': 42},
        })))
        .replaceAll('=', '');
    setUrl(auth: payload);
    final path = web.window.location.pathname;

    expect(await handleStravaWebCallback(), isTrue);
    final auth = await StravaTokenStorage.getAuth();
    expect(auth?.accessToken, 'test-access');
    expect(auth?.refreshToken, 'test-refresh');
    expect(auth?.expiresAt, 2000000000);
    expect(auth?.athleteId, 42);
    final cleaned = Uri.parse(web.window.location.href);
    expect(cleaned.path, path);
    expect(cleaned.queryParameters, {'view': 'setup'});
    expect(cleaned.fragment, 'rear-tire');
    expect(await handleStravaWebCallback(), isFalse);
    expect((await StravaTokenStorage.getAuth())?.accessToken, 'test-access');
  });

  for (final payload in ['error', '%%%']) {
    test('failed callback is removed without storing tokens: $payload',
        () async {
      setUrl(auth: payload);
      expect(await handleStravaWebCallback(), isFalse);
      expect(await StravaTokenStorage.getAuth(), isNull);
      expect(Uri.parse(web.window.location.href).queryParameters,
          {'view': 'setup'});
    });
  }

  test('redirect helper updates the current tab location', () {
    // A same-document destination exercises navigation without unloading tests.
    final target = Uri.parse(originalUrl)
        .replace(fragment: 'oauth-redirect-test')
        .toString();
    openStravaAuthInTab(target);
    expect(web.window.location.href, target);
  });
}
