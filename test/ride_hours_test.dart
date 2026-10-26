import 'dart:typed_data';
import 'package:bikesetupapp/features/rides/controllers/rides_controller.dart';
import 'package:bikesetupapp/features/rides/repositories/rides_repository.dart';
import 'package:bikesetupapp/features/maintenance/models/service_schedule.dart';
import 'package:bikesetupapp/features/maintenance/models/service_component.dart';
import 'package:bikesetupapp/features/maintenance/models/service_entry.dart';
import 'package:bikesetupapp/features/maintenance/models/component_type.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bikesetupapp/features/rides/models/fit_activity_decoder.dart';
import 'package:bikesetupapp/features/rides/models/ride.dart';

Uint8List fit(
    {int sport = 2,
    int timer = 3600000,
    int subSport = 0,
    bool bigEndian = false,
    bool developer = false,
    bool duplicate = false}) {
  final endian = bigEndian ? Endian.big : Endian.little;
  List<int> uint32(int value) =>
      (ByteData(4)..setUint32(0, value, endian)).buffer.asUint8List();
  final definition = [
    developer ? 0x61 : 0x41,
    0,
    bigEndian ? 1 : 0,
    if (bigEndian) ...[0, 18] else ...[18, 0],
    5,
    2,
    4,
    0x86,
    5,
    1,
    0,
    6,
    1,
    0,
    7,
    4,
    0x86,
    8,
    4,
    0x86,
    if (developer) ...[1, 0, 2, 0]
  ];
  final session = [
    1,
    ...uint32(1100000000),
    sport,
    subSport,
    ...uint32(7200000),
    ...uint32(timer),
    if (developer) ...[4, 5]
  ];
  final body = [
    0x40,
    0,
    0,
    0,
    0,
    1,
    0,
    1,
    0,
    0,
    4,
    ...definition,
    ...session,
    if (duplicate) ...session
  ];
  final bytes = Uint8List(14 + body.length + 2);
  final data = ByteData.sublistView(bytes);
  bytes[0] = 14;
  bytes[1] = 0x20;
  data.setUint32(4, body.length, Endian.little);
  bytes.setRange(8, 12, '.FIT'.codeUnits);
  data.setUint16(12, FitActivityDecoder.crc(bytes, 0, 12), Endian.little);
  bytes.setRange(14, 14 + body.length, body);
  data.setUint16(bytes.length - 2,
      FitActivityDecoder.crc(bytes, 0, bytes.length - 2), Endian.little);
  return bytes;
}

class MemoryRides implements RidesRepository {
  final data = <String, Ride>{};
  @override
  Stream<List<Ride>> watch(String bikeId) =>
      Stream.value(data.values.where((r) => r.bikeId == bikeId).toList());
  @override
  Future<int> insert(List<Ride> rides) async {
    var inserted = 0;
    for (final ride in rides) {
      if (!data.containsKey(ride.id)) {
        data[ride.id] = ride;
        inserted++;
      }
    }
    return inserted;
  }

  @override
  Future<void> remove(String id) async {
    data.remove(id);
  }
}

void main() {
  test('ride imports are idempotent and invalid durations never write',
      () async {
    final repository = MemoryRides();
    final controller = RidesController(repository);
    final ride = FitActivityDecoder.decode(fit()).single.forBike('bike');
    expect((await controller.save([ride])).requireValue(), 1);
    expect((await controller.save([ride, ride])).requireValue(), 0);
    await controller.save([
      Ride(
          id: 'invalid',
          bikeId: 'bike',
          startedAt: DateTime(2026),
          durationSeconds: -1,
          source: 'manual')
    ]);
    expect(repository.data, hasLength(1));
    expect(await controller.watch('other').first, isEmpty);
    controller.dispose();
  });
  test(
      'hour maintenance uses initial hours, resets after service, and survives old maps',
      () {
    final date = DateTime(2026, 10, 1);
    final component = ServiceComponent(
        id: 'fork',
        bikeId: 'bike',
        type: ComponentType.forkServiceLower,
        name: 'Fork',
        serviceIntervalKm: 0,
        serviceIntervalHours: 50,
        createdAt: date);
    final ride = Ride(
        id: 'ride',
        bikeId: 'bike',
        startedAt: date.add(const Duration(days: 1)),
        durationSeconds: 7200,
        source: 'manual');
    final baseline = ServiceEntry(
        id: 'initial', componentId: 'fork', date: date, initialRideHours: 35);
    final usage = annotateService(
        component: component,
        currentMileageKm: 10000,
        latestEntry: baseline,
        rides: [ride]);
    expect(usage.usage, 37);
    expect(usage.remaining, 13);
    expect(usage.status, ServiceStatus.amber);
    final service = ServiceEntry(
        id: 'reset',
        componentId: 'fork',
        date: date.add(const Duration(days: 2)),
        initialRideHours: 0);
    expect(
        annotateService(
            component: component,
            currentMileageKm: 10000,
            latestEntry: service,
            rides: [ride]).usage,
        0);
    expect(
        annotateService(
                component: component,
                currentMileageKm: 10000,
                latestEntry: baseline)
            .status,
        ServiceStatus.unknown);
    expect(
        ServiceComponent.fromMap('fork', component.toMap())
            .serviceIntervalHours,
        50);
    final legacy = Map<String, dynamic>.from(component.toMap())
      ..remove('serviceIntervalHours');
    expect(ServiceComponent.fromMap('old', legacy).usesHours, isFalse);
  });
  test(
      'FIT uses active timer rather than elapsed time, without duplicate sessions',
      () {
    final rides = FitActivityDecoder.decode(fit(duplicate: true));
    expect(rides, hasLength(1));
    expect(rides.single.hours, 1);
    expect(rides.single.id, FitActivityDecoder.decode(fit()).single.id);
    expect(rides.single.source, 'fit');
  });
  test('FIT reads big endian sessions and skips developer data', () {
    expect(
        FitActivityDecoder.decode(fit(bigEndian: true, developer: true))
            .single
            .hours,
        1);
    expect(FitActivityDecoder.decode(fit(subSport: 6)).single.indoor, isTrue);
    expect(FitActivityDecoder.decode(fit(subSport: 58)).single.indoor, isTrue);
  });
  test('FIT rejects corruption, noncycling, and missing active timer', () {
    final corrupt = fit();
    corrupt[30] ^= 1;
    for (final bytes in [
      corrupt,
      fit(sport: 1),
      fit(timer: 0xffffffff),
      Uint8List(4)
    ]) {
      expect(() => FitActivityDecoder.decode(bytes), throwsFormatException);
    }
  });
  test('hours reset at service date and indoor rides are opt-in', () {
    final service = DateTime(2026, 10, 20);
    Ride ride(String id, DateTime date, {bool indoor = false}) => Ride(
        id: id,
        bikeId: 'bike',
        startedAt: date,
        durationSeconds: 5400,
        source: 'manual',
        indoor: indoor);
    final rides = [
      ride('before', service.subtract(const Duration(seconds: 1))),
      ride('at', service),
      ride('after', service.add(const Duration(days: 1))),
      ride('indoor', service, indoor: true)
    ];
    expect(hoursSince(rides, service), 3);
    expect(hoursSince(rides, service, includeIndoor: true), 4.5);
    expect(hoursSince(rides, service.add(const Duration(days: 2))), 0);
  });
}
