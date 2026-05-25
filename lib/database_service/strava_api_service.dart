import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:http/http.dart' as http;
import 'package:bikesetupapp/models/strava_bike.dart';

/// Thrown when the stored token lacks the `activity:read` scope (HTTP 403).
/// The user needs to re-connect Strava to grant the new permission.
class StravaInsufficientScopeException implements Exception {
  const StravaInsufficientScopeException();
}

class StravaApiService {
  static const _athleteUrl = 'https://www.strava.com/api/v3/athlete';
  static const _activitiesUrl =
      'https://www.strava.com/api/v3/athlete/activities';

  Future<List<StravaBike>> fetchAthleteBikes(String accessToken) async {
    try {
      final response = await http.get(
        Uri.parse(_athleteUrl),
        headers: {'Authorization': 'Bearer $accessToken'},
      );

      if (response.statusCode == 429) {
        debugPrint('Strava rate limit reached');
        return [];
      }

      if (response.statusCode != 200) {
        debugPrint('Strava API error: ${response.statusCode}');
        return [];
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      debugPrint('Strava athlete response keys: ${json.keys.toList()}');
      debugPrint('Strava bikes field: ${json['bikes']}');
      final bikesJson = json['bikes'] as List<dynamic>? ?? [];
      return bikesJson
          .map((b) => StravaBike.fromStravaJson(b as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Strava fetch athlete error: $e');
      return [];
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

    final estimatedMeters =
        (currentTotalKm * 1000) - distanceAfterMeters;
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

      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $accessToken'},
      );

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
