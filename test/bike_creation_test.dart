import 'package:bikesetupapp/common/ui/app_select.dart';
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

BikeCreationDraft coilDraft() => BikeCreationDraft(name: 'Coil bike', specifications: {'fork': 'Coil', 'shock': 'None', 'fork_model': 'Example'},
    configuration: SetupConfiguration({
      'FrontTire': ['Pressure'], 'RearTire': ['Pressure'],
      'Fork': suspensionFields('Coil', ['Rebound']),
      'Cockpit': cockpitFields, 'Saddle': saddleFields,
    }));

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  test('reviewed configuration creates only selected parts and no invented values', () async {
    final bikes = FakeBikesRepository();
    final setups = FakeSetupsRepository();
    final controller = BikesController(bikes, setups);
    final created = (await controller.createFromDraft(coilDraft())).requireValue();
    final fields = await setups.getSettings(created.bikeId, 'Fork', created.setupId).first;
    expect(fields.keys, containsAll(['Spring Rate', 'Preload', 'Rebound']));
    expect(fields.containsKey('Pressure'), isFalse);
    expect(fields.containsKey('Compression'), isFalse);
    expect(await setups.getSettings(created.bikeId, 'Shock', created.setupId).first, isEmpty);
    expect(setups.settings.values.every((value) => value.isEmpty), isTrue);
    final restored = SetupConfiguration.fromInformation(setups.information[created.setupId]!);
    expect(restored!.fields, coilDraft().configuration.fields);
    expect(setups.defaults[created.bikeId], created.setupId);
    controller.dispose();
  });
  test('a bike without suspension does not seed hidden fork or shock records', () async {
    final setups = FakeSetupsRepository();
    final draft = BikeCreationDraft(name: 'City bike', configuration: SetupConfiguration({'FrontTire': ['Pressure'], 'RearTire': ['Pressure']}));
    await SetupCreationService(setups).create('bike', 'setup', 'Default', draft.toSetupInformation());
    expect(setups.settings.keys.toSet(), {'bike/setup/FrontTire/Pressure', 'bike/setup/RearTire/Pressure'});
  });
  test('frame settings persist as positions without invented pressures', () async {
    expect(SettingValue.parse('27.5', fallbackFamily: UnitFamily.freeText).displayNumber(), '27.5');
    final setups = FakeSetupsRepository();
    final bikes = BikesController(FakeBikesRepository(), setups);
    final draft = BikeCreationDraft(name: 'Adjustable frame',
        configuration: SetupConfiguration({'FrontTire': ['Pressure'], 'RearTire': ['Pressure'], 'Frame': frameFields}),
        values: {'Frame': {'Flip chip': 'Low', 'Headset cups': '-1 degree'}});
    final created = (await bikes.createFromDraft(draft)).requireValue();
    expect(await setups.getSettings(created.bikeId, 'Frame', created.setupId).first,
        {'Flip chip': 'Low', 'Headset cups': '-1 degree'});
    expect(setups.settings['${created.bikeId}/${created.setupId}/FrontTire/Pressure'], '');
    bikes.dispose();
  });
  test('invalid configuration is rejected before writing any values', () async {
    final setups = FakeSetupsRepository();
    await expectLater(SetupCreationService(setups).create('bike', 'setup', 'Default',
        {SetupConfiguration.metadataKey: '{"Invalid": ["Pressure"]}'}), throwsFormatException);
    expect(setups.settings, isEmpty);
    expect(setups.names, isEmpty);
  });
  test('editing setup information cannot overwrite measured settings', () async {
    final setups = FakeSetupsRepository();
    setups.settings['bike/setup/FrontTire/Pressure'] = '23 psi';
    final controller = SetupsController(setups);
    await controller.updateSetupInformation('bike', 'setup', 'Renamed', {'fork_model': 'Updated'});
    expect(setups.settings, {'bike/setup/FrontTire/Pressure': '23 psi'});
    expect(setups.names['setup'], 'Renamed');
    controller.dispose();
  });

  for (final scale in [1.0, 2.0]) {
    testWidgets('onboarding saves entered values for selected parts at text scale $scale', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final bikes = FakeBikesRepository();
      final setups = FakeSetupsRepository();
      final dependencies = AppDependencies(bikesRepository: (_) => bikes, setupsRepository: (_) => setups);
      addTearDown(dependencies.dispose);
      var created = false;
      await tester.pumpWidget(Provider.value(value: dependencies, child: MaterialApp(
        theme: AppTheme.darkTheme,
        builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)), child: child!),
        home: Scaffold(body: Builder(builder: (context) => TextButton(
            onPressed: () => showModalBottomSheet<void>(context: context, isScrollControlled: true,
              builder: (_) => CreateBikeFlow(user: CreationUser(), initialDraft: coilDraft(),
                onCreated: (_, __, ___, ____) => created = true)),
            child: const Text('Open')))),
      )));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.text('Bike type'), findsNothing);
      expect(find.byTooltip('Close'), findsNothing);
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(find.text('Choose what to track'), findsOneWidget);
      final partProgress = tester.widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator)).value;
      await tester.ensureVisible(find.text('Rear shock'));
      final collapsed = tester.getTopLeft(find.text('Cockpit')).dy;
      await tester.tap(find.text('Rear shock'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 120));
      final midway = tester.getTopLeft(find.text('Cockpit')).dy;
      await tester.pumpAndSettle();
      final expanded = tester.getTopLeft(find.text('Cockpit')).dy;
      expect(midway, greaterThan(collapsed));
      expect(midway, lessThan(expanded));
      expect(tester.widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator)).value, partProgress);
      await tester.tap(find.text('Rear shock'));
      await tester.pumpAndSettle();
      expect(tester.widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator)).value, partProgress);
      if (scale == 1) {
        await tester.tap(find.text('Rear shock'));
        await tester.pumpAndSettle();
      }
      await tester.ensureVisible(find.text('Frame'));
      await tester.tap(find.text('Frame'));
      await tester.pumpAndSettle();
      expect(find.text('Coil'), findsNWidgets(2));
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      expect(find.text('Coil bike'), findsOneWidget);
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('25').first);
      await tester.tap(find.text('25').first);
      await tester.pumpAndSettle();
      await tester.enterText(find.descendant(of: find.byKey(const ValueKey('FrontTire/Pressure')), matching: find.byType(TextField)), '24');
      await tester.ensureVisible(find.text('Apply'));
      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();
      expect(bikes.bikes, isEmpty);
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(find.text('Set your rear tire pressure'), findsOneWidget);
      expect(find.byKey(const ValueKey('RearTire/Pressure')), findsOneWidget);
      expect(find.text('24'), findsOneWidget);
      await tester.ensureVisible(find.byType(AppSelect<String>));
      await tester.tap(find.byType(AppSelect<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('27.5″'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      expect(find.text('24'), findsOneWidget);
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(find.text('Match your fork’s adjusters'), findsOneWidget);
      await tester.ensureVisible(find.byTooltip('Increase Travel'));
      await tester.tap(find.byTooltip('Increase Travel'));
      await tester.pumpAndSettle();
      expect(find.text('155'), findsOneWidget);
      await tester.tap(find.byTooltip('Decrease Travel'));
      await tester.pumpAndSettle();
      expect(find.text('150'), findsOneWidget);
      final controlsProgress = tester.widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator)).value;
      await tester.ensureVisible(find.text('None').first);
      await tester.tap(find.text('None').first);
      await tester.pumpAndSettle();
      expect(tester.widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator)).value, controlsProgress);
      final rebound = find.text('Low + high').first;
      await tester.ensureVisible(rebound);
      await tester.tap(rebound);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(find.text('Set your fork'), findsOneWidget);
      expect(find.byKey(const ValueKey('Fork/Spring Rate')), findsOneWidget);
      expect(find.byKey(const ValueKey('Fork/Sag')), findsNothing);
      final preload = find.byTooltip('Increase Preload');
      await tester.ensureVisible(preload);
      await tester.tap(preload);
      await tester.pumpAndSettle();

      final reboundPlus = find.byTooltip('Increase Low Speed Rebound');
      await tester.ensureVisible(reboundPlus);
      await tester.tap(reboundPlus);
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      expect(find.text('Match your fork’s adjusters'), findsOneWidget);
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(find.text('1'), findsNWidgets(2));
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      if (scale == 1) {
        expect(find.text('Match your shock’s adjusters'), findsOneWidget);
        await tester.ensureVisible(find.byTooltip('Increase Travel'));
        expect(find.text('150'), findsOneWidget);
        await tester.tap(find.byTooltip('Increase Travel'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('Shock/Pressure')), findsOneWidget);
        expect(find.byTooltip('Increase Low Speed Rebound'), findsOneWidget);
        expect(find.text('1'), findsOneWidget);
        await tester.ensureVisible(find.byTooltip('Increase Low Speed Rebound'));
        await tester.tap(find.byTooltip('Increase Low Speed Rebound'));
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('Back'));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.byTooltip('Increase Travel'));
        expect(find.text('155'), findsOneWidget);
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();
        expect(find.text('2'), findsOneWidget);
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();
      }
      expect(find.text('Set your cockpit'), findsOneWidget);
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(find.text('Set your saddle'), findsOneWidget);
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(find.text('Set your frame'), findsOneWidget);
      await tester.ensureVisible(find.text('Low'));
      await tester.tap(find.text('Low'));
      await tester.pumpAndSettle();
      expect(find.byType(AppSelect<String>), findsNothing);
      await tester.ensureVisible(find.text('Steeper'));
      await tester.tap(find.text('Steeper'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Create bike'));
      await tester.pumpAndSettle();
      expect(setups.settings.values, containsAll(['Low', 'Steeper']));
      expect(setups.information.values.single['rear_wheel_size'], '27.5');
      expect(setups.settings.keys.any((key) => key.endsWith('/Frame/Rear wheel size')), isFalse);
      expect(setups.settings.values, contains('1 turns'));
      expect(setups.settings.values, contains('1 clicks'));
      expect(setups.settings.keys.any((key) => key.endsWith('/Fork/Sag')), isFalse);
      expect(setups.settings.values, contains('24 psi'));
      expect(setups.settings.keys.any((key) => key.endsWith('/Fork/Low Speed Rebound')), isTrue);
      expect(setups.settings.keys.any((key) => key.endsWith('/Fork/Rebound')), isFalse);
      expect(created, isTrue);
      expect(bikes.bikes.single.name, 'Coil bike');
      expect(setups.settings.keys.any((key) => key.contains('/Fork/Pressure')), isFalse);
      expect(tester.takeException(), isNull);
    });
  }
}
