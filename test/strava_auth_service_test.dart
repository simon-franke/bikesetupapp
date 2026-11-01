import 'package:bikesetupapp/common/models/command_result.dart';
import 'dart:async';
import 'dart:convert';
import 'package:bikesetupapp/features/strava/models/strava_auth.dart';
import 'package:bikesetupapp/features/strava/repositories/strava_auth_service.dart';
import 'package:bikesetupapp/features/strava/repositories/platform_strava_repository.dart';
import 'package:bikesetupapp/features/strava/repositories/strava_api_service.dart';
import 'package:bikesetupapp/features/strava/repositories/strava_token_storage.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

const expired = StravaAuth(
    accessToken: 'expired',
    refreshToken: 'refresh',
    expiresAt: 1,
    athleteId: 42,
    scopes: ['activity:read_all']);
http.Response renewed() => http.Response(
    jsonEncode({
      'access_token': 'renewed',
      'refresh_token': 'rotated',
      'expires_at': 2000000000,
    }),
    200);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
  });

  test('native code exchange uses backend and preserves identity and scopes',
      () async {
    final auth = StravaAuthService(
      userId: () => 'user',
      authenticate: ({required url, required callbackUrlScheme}) async {
        final request = Uri.parse(url);
        expect(
            request.queryParameters['redirect_uri'], 'bikesetup://localhost');
        expect(request.queryParameters['scope'], contains('activity:read_all'));
        expect(request.queryParameters['approval_prompt'], 'force');
        expect(request.queryParameters['state'], isNotEmpty);
        expect(callbackUrlScheme, 'bikesetup');
        return Uri.parse('bikesetup://localhost').replace(queryParameters: {
          'state': request.queryParameters['state']!,
          'code': 'one-use-code',
          'scope': 'read,activity:read_all',
        }).toString();
      },
      client: MockClient((request) async {
        expect(request.url.path, '/stravaExchange');
        expect(request.url.scheme, 'https');
        expect(request.method, 'POST');
        expect(request.bodyFields, {'code': 'one-use-code'});
        return http.Response(
            jsonEncode({
              ...jsonDecode(renewed().body) as Map<String, dynamic>,
              'athlete': {'id': 42},
            }),
            200);
      }),
    );
    expect((await auth.authorize())?.athleteId, 42);
    expect((await auth.getAuth())?.scopes, ['read', 'activity:read_all']);
  });

  for (final scenario in [
    'state',
    'expired',
    'denied',
    'owner',
    'signout',
    'scheme'
  ]) {
    test('native authorization rejects $scenario before code exchange',
        () async {
      var time = DateTime.utc(2026);
      String? owner = 'user';
      var exchanges = 0;
      late StravaAuthService auth;
      auth = StravaAuthService(
        userId: () => owner,
        now: () => time,
        authenticate: ({required url, required callbackUrlScheme}) async {
          final state = Uri.parse(url).queryParameters['state']!;
          if (scenario == 'expired') {
            time = time.add(const Duration(minutes: 10));
          }
          if (scenario == 'owner') owner = 'other';
          if (scenario == 'signout') await auth.clearAuth();
          return Uri.parse(scenario == 'scheme'
                  ? 'wrong://localhost'
                  : 'bikesetup://localhost')
              .replace(queryParameters: {
            'state': scenario == 'state' ? 'wrong-state' : state,
            'code': 'code',
            if (scenario == 'denied') 'error': 'access_denied',
          }).toString();
        },
        client: MockClient((_) async {
          exchanges++;
          return renewed();
        }),
      );
      expect(await auth.authorize(), isNull);
      expect(exchanges, 0);
      expect(await auth.getAuth(), isNull);
    });
  }

  test('signout during native exchange cannot restore credentials', () async {
    final started = Completer<void>();
    final response = Completer<http.Response>();
    final auth = StravaAuthService(
      userId: () => 'user',
      authenticate: ({required url, required callbackUrlScheme}) async =>
          'bikesetup://localhost?code=code&state=${Uri.parse(url).queryParameters['state']}',
      client: MockClient((_) {
        started.complete();
        return response.future;
      }),
    );
    final pending = auth.authorize();
    await started.future;
    await auth.clearAuth();
    response.complete(http.Response(
        jsonEncode({
          ...jsonDecode(renewed().body) as Map<String, dynamic>,
          'athlete': {'id': 42},
        }),
        200));
    expect(await pending, isNull);
    expect(await auth.getAuth(), isNull);
  });

  test(
      'refresh uses server proxy without a client secret and persists rotation',
      () async {
    await StravaTokenStorage.saveAuth(expired, userId: 'user');
    final auth = StravaAuthService(
        userId: () => 'user',
        client: MockClient((request) async {
          expect(request.url.path, '/stravaRefresh');
          expect(request.method, 'POST');
          expect(request.bodyFields, {'refresh_token': 'refresh'});
          return renewed();
        }));
    expect(await auth.getValidToken(), 'renewed');
    final stored = await auth.getAuth();
    expect(stored?.refreshToken, 'rotated');
    expect(stored?.athleteId, 42);
    expect(stored?.scopes, ['activity:read_all']);
  });
  test('concurrent refreshes share a request and sign-out discards its result',
      () async {
    await StravaTokenStorage.saveAuth(expired, userId: 'user');
    final response = Completer<http.Response>();
    var calls = 0;
    final auth = StravaAuthService(
        userId: () => 'user',
        client: MockClient((_) {
          calls++;
          return response.future;
        }));
    final first = auth.refreshToken(expired);
    final second = auth.refreshToken(expired);
    await Future<void>.delayed(Duration.zero);
    expect(calls, 1);
    await auth.clearAuth();
    response.complete(renewed());
    expect(await first, isNull);
    expect(await second, isNull);
    expect(await auth.getAuth(), isNull);
  });
  test('switching app users isolates credentials and sync timestamps',
      () async {
    var owner = 'a';
    final repository = PlatformStravaRepository(userId: () => owner);
    await StravaTokenStorage.saveAuth(expired, userId: owner);
    await repository.markSynced();
    owner = 'b';
    expect(await repository.getAuth(), isNull);
    expect(await repository.getLastSyncTime(), isNull);
    await StravaTokenStorage.saveAuth(expired, userId: owner);
    await repository.clearAuth();
    expect(await repository.getAuth(), isNull);
    owner = 'a';
    expect(await repository.getAuth(), isNotNull);
    expect(await repository.getLastSyncTime(), isNotNull);
    await repository.clearAuth();
    expect(await repository.getAuth(), isNull);
    expect(await repository.getLastSyncTime(), isNull);
  });
  test('sign-out deletion follows an already queued credential write',
      () async {
    final save = StravaTokenStorage.saveAuth(expired, userId: 'user');
    final clear = StravaTokenStorage.clearAuth(userId: 'user');
    await Future.wait([save, clear]);
    expect(await StravaTokenStorage.getAuth(userId: 'user'), isNull);
  });
  test('a rejected refresh leaves credentials intact and allows a later retry',
      () async {
    await StravaTokenStorage.saveAuth(expired, userId: 'user');
    var calls = 0;
    final auth = StravaAuthService(
        userId: () => 'user',
        client: MockClient(
            (_) async => ++calls == 1 ? http.Response('{}', 502) : renewed()));
    await expectLater(
        auth.getValidToken(),
        throwsA(isA<AppFailure>()
            .having((e) => e.code, 'code', FailureCode.connectionExpired)));
    expect((await auth.getAuth())?.refreshToken, 'refresh');
    expect(await auth.getValidToken(), 'renewed');
    expect(calls, 2);
  });
  test('credentials without an owner are not adopted by a user', () async {
    FlutterSecureStorage.setMockInitialValues(
        {'strava_auth': jsonEncode(expired.toJson())});
    expect(await StravaTokenStorage.getAuth(userId: 'user'), isNull);
  });
  test('refresh cannot save credentials under a different signed-in user',
      () async {
    String? owner = 'a';
    final response = Completer<http.Response>();
    final auth = StravaAuthService(
        userId: () => owner, client: MockClient((_) => response.future));
    final refresh = auth.refreshToken(expired);
    owner = 'b';
    response.complete(renewed());
    expect(await refresh, isNull);
    expect(await StravaTokenStorage.getAuth(userId: 'a'), isNull);
    expect(await StravaTokenStorage.getAuth(userId: 'b'), isNull);
  });
  test(
      'historical mileage rejects incomplete or unknown scopes before requesting activities',
      () async {
    var calls = 0;
    final repository = PlatformStravaRepository(
        userId: () => 'user',
        api: StravaApiService(client: MockClient((_) async {
          calls++;
          return http.Response('[]', 200);
        })));
    for (final scopes in [
      <String>[],
      ['activity:read']
    ]) {
      await StravaTokenStorage.saveAuth(
          StravaAuth(
              accessToken: 'valid',
              refreshToken: 'refresh',
              expiresAt: 2000000000,
              athleteId: 42,
              scopes: scopes),
          userId: 'user');
      await expectLater(
          repository.fetchMileageAtDate(
              gearId: 'bike',
              date: DateTime.utc(2026, 1, 1),
              currentTotalKm: 1000),
          throwsA(isA<StravaInsufficientScopeException>()));
    }
    expect(calls, 0);
  });
  test('full-scope mileage subtracts private rides as well as public rides',
      () async {
    await StravaTokenStorage.saveAuth(
        const StravaAuth(
            accessToken: 'valid',
            refreshToken: 'refresh',
            expiresAt: 2000000000,
            athleteId: 42,
            scopes: ['activity:read_all']),
        userId: 'user');
    final repository = PlatformStravaRepository(
        userId: () => 'user',
        api: StravaApiService(
            client: MockClient((_) async => http.Response(
                jsonEncode([
                  {
                    'gear_id': 'bike',
                    'distance': 100000,
                    'visibility': 'only_me'
                  },
                  {'gear_id': 'bike', 'distance': 50000},
                  {'gear_id': 'other', 'distance': 80000},
                ]),
                200))));
    expect(
        await repository.fetchMileageAtDate(
            gearId: 'bike',
            date: DateTime.utc(2026, 1, 1),
            currentTotalKm: 1000),
        850);
  });

}
