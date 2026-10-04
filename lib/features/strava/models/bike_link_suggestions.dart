import 'package:bikesetupapp/features/bikes/models/bike.dart';
import 'strava_bike.dart';

/// Existing valid links win; otherwise suggest the first name match.
Map<String, String?> suggestBikeLinks(
    Iterable<StravaBike> stravaBikes, Iterable<Bike> appBikes) {
  final bikes = appBikes.toList();
  final ids = bikes.map((bike) => bike.id).toSet();
  final suggestions = <String, String?>{};
  for (final strava in stravaBikes) {
    if (strava.linkedBikeId != null && ids.contains(strava.linkedBikeId)) {
      suggestions[strava.stravaGearId] = strava.linkedBikeId;
      continue;
    }
    final name = strava.name.trim().toLowerCase();
    if (name.isEmpty) continue;
    for (final bike in bikes) {
      final candidate = bike.name.trim().toLowerCase();
      if (candidate.isNotEmpty &&
          (candidate.contains(name) || name.contains(candidate))) {
        suggestions[strava.stravaGearId] = bike.id;
        break;
      }
    }
  }
  return Map.unmodifiable(suggestions);
}
