class Ride {
  const Ride(
      {required this.id,
      required this.bikeId,
      required this.startedAt,
      required this.durationSeconds,
      required this.source,
      this.name = '',
      this.distanceKm,
      this.distanceInStrava = false,
      this.indoor = false});
  final String id, bikeId, source, name;
  final DateTime startedAt;
  final int durationSeconds;
  final bool indoor;
  final double? distanceKm;
  final bool distanceInStrava;
  double get hours => durationSeconds / 3600;
  Ride forBike(String bike) => Ride(
      id: id,
      bikeId: bike,
      startedAt: startedAt,
      durationSeconds: durationSeconds,
      source: source,
      name: name,
      distanceKm: distanceKm,
      distanceInStrava: distanceInStrava,
      indoor: indoor);
  Map<String, dynamic> toMap() => {
        'bikeId': bikeId,
        'startedAt': startedAt,
        'durationSeconds': durationSeconds,
        'source': source,
        'name': name,
        if (distanceKm != null) 'distanceKm': distanceKm,
        'distanceInStrava': distanceInStrava,
        'indoor': indoor
      };
  factory Ride.fromMap(String id, Map<String, dynamic> map) => Ride(
      id: id,
      bikeId: map['bikeId'] as String,
      startedAt: map['startedAt'] as DateTime,
      durationSeconds: (map['durationSeconds'] as num).toInt(),
      source: map['source'] as String,
      distanceKm: (map['distanceKm'] as num?)?.toDouble(),
      distanceInStrava: map['distanceInStrava'] as bool? ?? false,
      name: map['name'] as String? ?? '',
      indoor: map['indoor'] as bool? ?? false);
}

/// A service at a timestamp starts a new usage window. Late imports before that
/// timestamp cannot increase the new window. Indoor rides are excluded unless the component opts in.
double hoursSince(List<Ride> rides, DateTime since,
        {bool includeIndoor = false}) =>
    rides
        .where(
            (r) => !r.startedAt.isBefore(since) && (includeIndoor || !r.indoor))
        .fold<double>(0, (sum, r) => sum + r.hours);

/// Only add distances outside the odometer when Strava already supplies mileage.
double distanceSince(List<Ride> rides, DateTime since,
        {bool hasStravaBaseline = false, bool includeIndoor = false}) =>
    rides
        .where((ride) =>
            !ride.startedAt.isBefore(since) &&
            (includeIndoor || !ride.indoor) &&
            !(hasStravaBaseline && ride.distanceInStrava))
        .fold(0.0, (sum, ride) => sum + (ride.distanceKm ?? 0));
