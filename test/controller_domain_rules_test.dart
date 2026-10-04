import 'package:bikesetupapp/features/bikes/models/bike.dart';
import 'package:bikesetupapp/features/strava/models/strava_bike.dart';
import 'package:bikesetupapp/features/strava/models/bike_link_suggestions.dart';
import 'package:bikesetupapp/features/setups/models/setup_defaults.dart';
import 'package:bikesetupapp/features/setups/models/category.dart';
import 'package:bikesetupapp/features/maintenance/models/deferred_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('bike suggestions preserve valid links and match case-insensitive names',
      () {
    final bikes = [
      Bike(id: 'a', name: 'Trail bike', bikeType: 'Enduro'),
      Bike(id: 'b', name: 'Road', bikeType: 'Road')
    ];
    final result = suggestBikeLinks([
      const StravaBike(
          stravaGearId: '1',
          name: 'Trail',
          distanceMeters: 0,
          linkedBikeId: 'b'),
      const StravaBike(stravaGearId: '2', name: 'TRAIL', distanceMeters: 0),
      const StravaBike(
          stravaGearId: '3',
          name: 'Road',
          distanceMeters: 0,
          linkedBikeId: 'deleted'),
      const StravaBike(stravaGearId: '4', name: '', distanceMeters: 0),
      const StravaBike(stravaGearId: '5', name: 'Unmatched', distanceMeters: 0),
    ], bikes);
    expect(result, {'1': 'b', '2': 'a', '3': 'b'});
    expect(() => result['1'] = 'a', throwsUnsupportedError);
  });
  test('setup defaults retain air and coil settings and all categories', () {
    final air = SetupDefaults.forShock('Air');
    final coil = SetupDefaults.forShock('Coil');
    expect(air.keys.toSet(), Category.values.toSet());
    expect(air[Category.shock],
        {'Pressure': '180', 'Tokens': '0', 'Rebound': '5', 'Compression': '8'});
    expect(coil[Category.shock], {
      'Preload': '0',
      'Spring Rate': '450',
      'Rebound': '5',
      'Compression': '8'
    });
    expect(coil[Category.generalSettings]!['Reach'], '450mm');
  });
  test(
      'deferred service baseline produces requested remaining mileage and clamps at zero',
      () {
    expect(
        deferredServiceMileage(
            currentMileageKm: 1200, extendKm: 50, serviceIntervalKm: 1000),
        250);
    expect(
        deferredServiceMileage(
            currentMileageKm: 10, extendKm: 50, serviceIntervalKm: 1000),
        0);
  });
}
