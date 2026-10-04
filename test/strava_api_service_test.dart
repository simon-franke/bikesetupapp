import 'package:bikesetupapp/common/ui/failure_message.dart';
import 'dart:convert';
import 'package:bikesetupapp/features/strava/repositories/strava_api_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  StravaApiService service(int status, Object body) => StravaApiService(
        client: MockClient((request) async {
          expect(request.url.path, '/api/v3/athlete');
          expect(request.headers['Authorization'], 'Bearer test-token');
          return http.Response(jsonEncode(body), status);
        }),
      );

  test(
      'inactive application is actionable and not mistaken for an empty bike list',
      () async {
    final api = service(403, {
      'message': 'Forbidden',
      'errors': [
        {'resource': 'Application', 'field': 'Status', 'code': 'Inactive'},
      ]
    });
    await expectLater(
        api.fetchAthleteBikes('test-token'),
        throwsA(
          isA<StravaApiException>().having(
              (e) => failureMessage(e),
              'message',
              allOf(
                contains('subscription'),
                contains('reactivate'),
                contains('strava.com/settings/api'),
              )),
        ));
  });

  test('successful bike sync preserves IDs and distance', () async {
    final bikes = await service(200, {
      'bikes': [
        {'id': 'b123', 'name': 'Trail bike', 'distance': 12500},
      ]
    }).fetchAthleteBikes('test-token');
    expect(bikes.single.stravaGearId, 'b123');
    expect(bikes.single.distanceKm, 12.5);
  });

  test('missing full-profile permission differs from an empty gear list',
      () async {
    await expectLater(
        service(200, {'id': 123}).fetchAthleteBikes('test-token'),
        throwsA(isA<StravaApiException>().having(
            (e) => failureMessage(e), 'message', contains('full profile'))));
    expect(await service(200, {'bikes': []}).fetchAthleteBikes('test-token'),
        isEmpty);
  });

  for (final entry in {
    401: 'Reconnect',
    403: 'denied access',
    429: 'request limit'
  }.entries) {
    test('HTTP ${entry.key} does not masquerade as no bikes', () async {
      await expectLater(
          service(entry.key, {}).fetchAthleteBikes('test-token'),
          throwsA(isA<StravaApiException>().having(
              (e) => failureMessage(e), 'message', contains(entry.value))));
    });
  }

  test('non-JSON server error remains an HTTP error without exposing the body',
      () async {
    final api = StravaApiService(
        client: MockClient(
            (_) async => http.Response('private server diagnostic', 503)));
    await expectLater(
        api.fetchAthleteBikes('test-token'),
        throwsA(
          isA<StravaApiException>()
              .having((e) => e.statusCode, 'status', 503)
              .having((e) => failureMessage(e), 'safe message',
                  isNot(contains('private'))),
        ));
  });
}
