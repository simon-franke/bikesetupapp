import 'package:bikesetupapp/features/setups/ui/setting_value_editor.dart';
import 'package:bikesetupapp/app/app_dependencies.dart';
import 'package:bikesetupapp/common/theme/theme_data.dart';
import 'package:bikesetupapp/features/bikes/controllers/bikes_controller.dart';
import 'package:bikesetupapp/features/bikes/models/bike_creation_draft.dart';
import 'package:bikesetupapp/features/bikes/ui/create_bike_flow.dart';
import 'package:bikesetupapp/features/setups/controllers/setup_creation_service.dart';
import 'package:bikesetupapp/features/setups/controllers/setups_controller.dart';
import 'package:bikesetupapp/features/setups/models/setup_configuration.dart';
import 'package:bikesetupapp/features/setups/ui/field_meta.dart';
import 'package:bikesetupapp/features/setups/models/unit_system.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'support/fake_repositories.dart';

class CreationUser extends Fake implements User {
  @override
  String get uid => 'user';
}

BikeCreationDraft coilDraft() => BikeCreationDraft(
    name: 'Coil bike',
    specifications: {'fork': 'Coil', 'shock': 'None', 'fork_model': 'Example'},
    configuration: SetupConfiguration({
      'FrontTire': ['Pressure'],
      'RearTire': ['Pressure'],
      'Fork': suspensionFields('Coil', ['Rebound']),
      'Cockpit': cockpitFields,
      'Saddle': saddleFields,
    }));

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  test(
      'reviewed configuration creates only selected parts and no invented values',
      () async {
    final bikes = FakeBikesRepository();
    final setups = FakeSetupsRepository();
    final controller = BikesController(bikes, setups);
    final created =
        (await controller.createFromDraft(coilDraft())).requireValue();
    final fields =
        await setups.getSettings(created.bikeId, 'Fork', created.setupId).first;
    expect(fields.keys, containsAll(['Spring Rate', 'Preload', 'Rebound']));
    expect(fields.containsKey('Pressure'), isFalse);
    expect(fields.containsKey('Compression'), isFalse);
    expect(
        await setups
            .getSettings(created.bikeId, 'Shock', created.setupId)
            .first,
        isEmpty);
    expect(setups.settings.values.every((value) => value.isEmpty), isTrue);
    final restored = SetupConfiguration.fromInformation(
        setups.information[created.setupId]!);
    expect(restored!.fields, coilDraft().configuration.fields);
    expect(setups.defaults[created.bikeId], created.setupId);
    controller.dispose();
  });
  test('a bike without suspension does not seed hidden fork or shock records',
      () async {
    final setups = FakeSetupsRepository();
    final draft = BikeCreationDraft(
        name: 'City bike',
        configuration: SetupConfiguration({
          'FrontTire': ['Pressure'],
          'RearTire': ['Pressure']
        }));
    await SetupCreationService(setups)
        .create('bike', 'setup', 'Default', draft.toSetupInformation());
    expect(setups.settings.keys.toSet(),
        {'bike/setup/FrontTire/Pressure', 'bike/setup/RearTire/Pressure'});
  });
  test('frame settings persist as positions without invented pressures',
      () async {
    expect(
        SettingValue.parse('27.5', fallbackFamily: UnitFamily.freeText)
            .displayNumber(),
        '27.5');
    final setups = FakeSetupsRepository();
    final bikes = BikesController(FakeBikesRepository(), setups);
    final draft = BikeCreationDraft(
        name: 'Adjustable frame',
        configuration: SetupConfiguration({
          'FrontTire': ['Pressure'],
          'RearTire': ['Pressure'],
          'Frame': frameFields
        }),
        values: {
          'Frame': {'Flip chip': 'Low', 'Headset cups': '-1 degree'}
        });
    final created = (await bikes.createFromDraft(draft)).requireValue();
    expect(
        await setups
            .getSettings(created.bikeId, 'Frame', created.setupId)
            .first,
        {'Flip chip': 'Low', 'Headset cups': '-1 degree'});
    expect(
        setups.settings[
            '${created.bikeId}/${created.setupId}/FrontTire/Pressure'],
        '');
    bikes.dispose();
  });
  test('invalid configuration is rejected before writing any values', () async {
    final setups = FakeSetupsRepository();
    await expectLater(
        SetupCreationService(setups).create('bike', 'setup', 'Default',
            {SetupConfiguration.metadataKey: '{"Invalid/path": ["Pressure"]}'}),
        throwsFormatException);
    expect(setups.settings, isEmpty);
    expect(setups.names, isEmpty);
  });
  test('editing setup information cannot overwrite measured settings',
      () async {
    final setups = FakeSetupsRepository();
    setups.settings['bike/setup/FrontTire/Pressure'] = '23 psi';
    final controller = SetupsController(setups);
    await controller.updateSetupInformation(
        'bike', 'setup', 'Renamed', {'fork_model': 'Updated'});
    expect(setups.settings, {'bike/setup/FrontTire/Pressure': '23 psi'});
    expect(setups.names['setup'], 'Renamed');
    controller.dispose();
  });

  for (final scale in [1.0, 2.0]) {
    testWidgets(
        'onboarding saves entered values for selected parts at text scale $scale',
        (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final bikes = FakeBikesRepository();
      final setups = FakeSetupsRepository();
      final dependencies = AppDependencies(
          bikesRepository: (_) => bikes, setupsRepository: (_) => setups);
      addTearDown(dependencies.dispose);
      var created = false;
      await tester.pumpWidget(Provider.value(
          value: dependencies,
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: TextScaler.linear(scale)),
                child: child!),
            home: Scaffold(
                body: Builder(
                    builder: (context) => TextButton(
                        onPressed: () => showModalBottomSheet<void>(
                            context: context,
                            isScrollControlled: true,
                            builder: (_) => CreateBikeFlow(
                                user: CreationUser(),
                                initialDraft: coilDraft(),
                                onCreated: (_, __, ___, ____) =>
                                    created = true)),
                        child: const Text('Open')))),
          )));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Close bike setup'), findsOneWidget);
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(find.text('Set your front tire pressure'), findsOneWidget);
      await tester.ensureVisible(find.text('Pressure').first);
      await tester.tap(find.text('Pressure').first);
      await tester.pumpAndSettle();
      tester
          .widget<SettingValueEditor>(find.byType(SettingValueEditor))
          .onChanged(24);
      await tester.ensureVisible(find.text('Use value'));
      await tester.tap(find.text('Use value'));
      await tester.pumpAndSettle();
      expect(find.text('24 psi'), findsOneWidget);
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(find.text('24 psi'), findsOneWidget);
      // Navigate without entering the remaining optional measurements.
      for (var steps = 0;
          steps < 12 && find.text('Create bike').evaluate().isEmpty;
          steps++) {
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();
      }
      expect(find.text('Review your bike'), findsNothing);
      expect(bikes.bikes, isEmpty);
      await tester.tap(find.text('Create bike'));
      await tester.pumpAndSettle();
      expect(created, isTrue);
      expect(bikes.bikes.single.name, 'Coil bike');
      expect(setups.settings.values, contains('24 psi'));
      expect(setups.settings.values.where((v) => v.toString().isNotEmpty),
          ['24 psi', '24 psi']);
      expect(tester.takeException(), isNull);
    });
  }
}
