import 'dart:async';
import 'package:bikesetupapp/common/models/command_result.dart';
import '../models/strava_exception.dart';
export '../models/strava_exception.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:http/http.dart' as http;
import 'package:bikesetupapp/features/strava/models/strava_bike.dart';

StravaApiException _exceptionFromResponse(http.Response response) {
  var inactive = false;
  try {
    final body = jsonDecode(response.body);
    if (body is Map && body['errors'] is List) {
      inactive = (body['errors'] as List).any((error) =>
          error is Map &&
          error['resource'].toString().toLowerCase() == 'application' &&
          error['code'].toString().toLowerCase() == 'inactive');
    }
  } on FormatException {/* Non-JSON failures still have an HTTP status. */}
  final code = inactive
      ? FailureCode.stravaInactive
      : switch (response.statusCode) {
          401 => FailureCode.connectionExpired,
          403 => FailureCode.stravaDenied,
          429 => FailureCode.rateLimited,
          _ => FailureCode.stravaError,
        };
  return StravaApiException(code, statusCode: response.statusCode);
}

class StravaApiService {
  final http.Client? _client;
  StravaApiService({http.Client? client}) : _client = client;

  Future<http.Response> _get(Uri uri, String accessToken) {
    final headers = {'Authorization': 'Bearer $accessToken'};
    return (_client?.get(uri, headers: headers) ??
            http.get(uri, headers: headers))
        .timeout(const Duration(seconds: 15));
  }

  static const _athleteUrl = 'https://www.strava.com/api/v3/athlete';
  static const _activitiesUrl =
      'https://www.strava.com/api/v3/athlete/activities';

  Future<List<StravaBike>> fetchAthleteBikes(String accessToken) async {
    try {
      final response = await _get(Uri.parse(_athleteUrl), accessToken);
      if (response.statusCode != 200) {
        throw _exceptionFromResponse(response);
      }
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final bikesJson = json['bikes'];
      if (bikesJson == null) {
        throw const StravaApiException(FailureCode.missingProfileScope);
      }
      return (bikesJson as List<dynamic>)
          .map((b) => StravaBike.fromStravaJson(b as Map<String, dynamic>))
          .toList();
    } on StravaApiException {
      rethrow;
    } on TimeoutException catch (error, stack) {
      throw StravaApiException(FailureCode.network,
          cause: error, stackTrace: stack);
    } on http.ClientException catch (error, stack) {
      throw StravaApiException(FailureCode.network,
          cause: error, stackTrace: stack);
    } on FormatException catch (error, stack) {
      throw StravaApiException(FailureCode.invalidResponse,
          cause: error, stackTrace: stack);
    } on TypeError catch (error, stack) {
      throw StravaApiException(FailureCode.invalidResponse,
          cause: error, stackTrace: stack);
    } on RangeError catch (error, stack) {
      throw StravaApiException(FailureCode.invalidResponse,
          cause: error, stackTrace: stack);
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
  /// `activity:read_all` (the user needs to re-connect Strava).
  /// Network, rate-limit and response failures throw typed [AppFailure] values.
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
  /// Network, rate-limit and response failures throw typed [AppFailure] values.
  /// Throws [StravaInsufficientScopeException] on HTTP 403.
  Future<List<Map<String, dynamic>>> _fetchActivitiesPage(
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
        throw _exceptionFromResponse(response);
      }
      if (response.statusCode != 200) {
        throw _exceptionFromResponse(response);
      }

      return (jsonDecode(response.body) as List<dynamic>)
          .cast<Map<String, dynamic>>();
    } on StravaInsufficientScopeException {
      rethrow;
    } on AppFailure {
      rethrow;
    } on TimeoutException catch (error, stack) {
      throw StravaApiException(FailureCode.network,
          cause: error, stackTrace: stack);
    } on http.ClientException catch (error, stack) {
      throw StravaApiException(FailureCode.network,
          cause: error, stackTrace: stack);
    } on FormatException catch (error, stack) {
      throw StravaApiException(FailureCode.invalidResponse,
          cause: error, stackTrace: stack);
    } on TypeError catch (error, stack) {
      throw StravaApiException(FailureCode.invalidResponse,
          cause: error, stackTrace: stack);
    }
  }
}
