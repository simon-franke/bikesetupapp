import 'package:bikesetupapp/common/data/firestore_codec.dart';
import 'package:bikesetupapp/features/maintenance/models/component_type.dart';
import 'package:bikesetupapp/features/maintenance/models/service_component.dart';
import 'package:bikesetupapp/features/maintenance/models/service_entry.dart';
import 'package:bikesetupapp/features/settings/controllers/app_state_notifier.dart';
import 'package:bikesetupapp/features/settings/repositories/theme_preferences_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class MemoryThemePreferences implements ThemePreferencesRepository {
  String? saved;
  @override
  Future<String?> readTheme() async => saved;
  @override
  Future<void> saveTheme(String mode) async {
    saved = mode;
  }
}

void main() {
  test(
      'repository codec round-trips service dates without Firebase model types',
      () {
    final date = DateTime.utc(2026, 1, 2, 3, 4);
    final entry = ServiceEntry(
        id: 'entry',
        componentId: 'component',
        date: date,
        mileageAtServiceKm: 123.5,
        note: 'Service');
    final plain = entry.toMap();
    expect(plain['service_date'], isA<DateTime>());
    final stored = encodeFirestoreMap(plain);
    expect(stored['service_date'], isA<Timestamp>());
    final restored = ServiceEntry.fromMap(entry.id, decodeFirestoreMap(stored));
    expect(restored.date.isAtSameMomentAs(date), isTrue);
    expect(restored.mileageAtServiceKm, 123.5);
    expect(restored.note, 'Service');
  });

  test('repository codec preserves component type and creation date', () {
    final component = ServiceComponent(
        id: 'component',
        bikeId: 'bike',
        type: ComponentType.values.first,
        name: 'Part',
        serviceIntervalKm: 1000,
        createdAt: DateTime.utc(2026, 1, 2));
    final restored = ServiceComponent.fromMap(component.id,
        decodeFirestoreMap(encodeFirestoreMap(component.toMap())));
    expect(restored.createdAt.isAtSameMomentAs(component.createdAt), isTrue);
    expect(restored.type, component.type);
    expect(restored.serviceIntervalKm, 1000);
  });

  test(
      'theme controller reads defaults and persists choices through its repository',
      () async {
    final repository = MemoryThemePreferences();
    expect(AppStateNotifier.fromSaved(null), ThemeMode.dark);
    expect(AppStateNotifier.fromSaved('invalid'), ThemeMode.dark);
    expect(AppStateNotifier.fromSaved('system'), ThemeMode.system);
    final controller =
        AppStateNotifier(ThemeMode.dark, preferences: repository);
    await controller.updateTheme(ThemeMode.light);
    expect(await repository.readTheme(), 'light');
    expect(controller.themeMode, ThemeMode.light);
    controller.dispose();
  });
}
