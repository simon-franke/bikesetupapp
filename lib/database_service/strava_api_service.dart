import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:http/http.dart' as http;
import 'package:bikesetupapp/models/strava_bike.dart';

/// Thrown when the stored token lacks the `activity:read` scope (HTTP 403).
/// The user needs to re-connect Strava to grant the new permission.
class StravaInsufficientScopeException implements Exception {
  const StravaInsufficientScopeException();
}

/// A safe, actionable error that can be shown without logging credentials.
class StravaApiException implements Exception {
  final String message;
  final int? statusCode;
  const StravaApiException(this.message, {this.statusCode});

  factory StravaApiException.fromResponse(http.Response response) {
    var inactive = false;
    try {
      final body = jsonDecode(response.body);
      if (body is Map && body['errors'] is List) {
        inactive = (body['errors'] as List).any((error) =>
            error is Map &&
            error['resource'].toString().toLowerCase() == 'application' &&
            error['code'].toString().toLowerCase() == 'inactive');
      }
    } catch (_) {/* Non-JSON failures still have an HTTP status. */}
    final String message;
    if (inactive) {
      message =
          'Strava has disabled this API application. Its owner must check their Strava subscription and reactivate the app at strava.com/settings/api.';
    } else if (response.statusCode == 401) {
      message =
          'Strava authorization is no longer valid. Reconnect Strava in Settings.';
    } else if (response.statusCode == 403) {
      message =
          'Strava denied access. Check the API application status and granted permissions.';
    } else if (response.statusCode == 429) {
      message = 'Strava’s request limit has been reached. Try again later.';
    } else {
      message =
          'Strava returned an error (${response.statusCode}). Try again later.';
    }
    return StravaApiException(message, statusCode: response.statusCode);
  }

  @override
  String toString() => message;
}

class StravaApiService {
  final http.Client? _client;
  StravaApiService({http.Client? client}) : _client = client;

  Future<http.Response> _get(Uri uri, String accessToken) {
    final headers = {'Authorization': 'Bearer $accessToken'};
    return _client?.get(uri, headers: headers) ??
        http.get(uri, headers: headers);
  }

  static const _athleteUrl = 'https://www.strava.com/api/v3/athlete';
  static const _activitiesUrl =
      'https://www.strava.com/api/v3/athlete/activities';

  Future<List<StravaBike>> fetchAthleteBikes(String accessToken) async {
    try {
      final response = await _get(Uri.parse(_athleteUrl), accessToken);
      if (response.statusCode != 200) {
        throw StravaApiException.fromResponse(response);
      }
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final bikesJson = json['bikes'];
      if (bikesJson == null) {
        throw const StravaApiException(
            'Strava did not provide bike data. Reconnect Strava and grant permission to read your full profile.');
      }
      return (bikesJson as List<dynamic>)
          .map((b) => StravaBike.fromStravaJson(b as Map<String, dynamic>))
          .toList();
    } on StravaApiException {
      rethrow;
    } on http.ClientException {
      throw const StravaApiException(
          'Could not reach Strava. Check your connection and try again.');
    } catch (_) {
      throw const StravaApiException(
          'Could not read Strava’s bike data. Try again later.');
    }
  }

  /// Returns the estimated mileage (km) for [gearId] as of [date].
  ///
  /// Strategy: fetch all activities on this gear that started **on or after**
  /// [date], sum their distances, then subtract from [currentTotalKm].
  /// This only needs to page through recent rides — far cheaper than
  /// paginating the full history from the beginning.
  ///
  /// Throws [StravaInsufficientScopeException] when the token lacks
  /// `activity:read` (the user needs to re-connect Strava).
  /// Returns null on rate-limit or network error.
  Future<double?> fetchMileageAtDate({
    required String accessToken,
    required String gearId,
    required DateTime date,
    required double currentTotalKm,
  }) async {
    // Use start-of-day UTC so we exclude all rides from `date` onwards —
    // conservative and avoids needing a time-of-day from the user.
    final afterTimestamp =
        DateTime.utc(date.year, date.month, date.day).millisecondsSinceEpoch ~/
            1000;

    double distanceAfterMeters = 0.0;
    int page = 1;

    while (true) {
      final activities = await _fetchActivitiesPage(
        accessToken,
        afterTimestamp: afterTimestamp,
        page: page,
      );
      if (activities == null) return null;

      for (final act in activities) {
        if ((act['gear_id'] as String?) == gearId) {
          distanceAfterMeters += (act['distance'] as num?)?.toDouble() ?? 0;
        }
      }

      if (activities.length < 200) break;
      page++;
    }

    final estimatedMeters = (currentTotalKm * 1000) - distanceAfterMeters;
    return estimatedMeters.clamp(0, double.infinity) / 1000;
  }

  /// Fetches one page of activities started after [afterTimestamp] (Unix s).
  /// Returns null on rate-limit or network error.
  /// Throws [StravaInsufficientScopeException] on HTTP 403.
  Future<List<Map<String, dynamic>>?> _fetchActivitiesPage(
    String accessToken, {
    required int afterTimestamp,
    required int page,
  }) async {
    try {
      final uri = Uri.parse(_activitiesUrl).replace(queryParameters: {
        'after': afterTimestamp.toString(),
        'per_page': '200',
        'page': page.toString(),
      });

      final response = await _get(uri, accessToken);

      if (response.statusCode == 403) {
        debugPrint('Strava: insufficient scope for activities');
        throw const StravaInsufficientScopeException();
      }
      if (response.statusCode == 429) {
        debugPrint('Strava: rate limit reached');
        return null;
      }
      if (response.statusCode != 200) {
        debugPrint('Strava activities error: ${response.statusCode}');
        return null;
      }

      return (jsonDecode(response.body) as List<dynamic>)
          .cast<Map<String, dynamic>>();
    } on StravaInsufficientScopeException {
      rethrow;
    } catch (e) {
      debugPrint('Strava fetch activities error: $e');
      return null;
    }
  }
}
