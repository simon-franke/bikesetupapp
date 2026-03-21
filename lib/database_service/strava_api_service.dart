import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:http/http.dart' as http;
import 'package:bikesetupapp/models/strava_bike.dart';

class StravaApiService {
  static const _athleteUrl = 'https://www.strava.com/api/v3/athlete';

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
}
