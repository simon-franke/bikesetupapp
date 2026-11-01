import 'package:bikesetupapp/features/setups/models/setup_configuration.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:bikesetupapp/app/app_dependencies.dart';
import 'package:bikesetupapp/common/theme/theme_data.dart';
import 'package:bikesetupapp/features/tests/controllers/tests_controller.dart';
import 'package:bikesetupapp/features/tests/models/setup_test.dart';
import 'support/fake_tests_repository.dart';
import 'package:bikesetupapp/features/tests/ui/track_time_sheet.dart';
import 'package:bikesetupapp/features/tests/ui/tests_view.dart';
import 'support/fake_repositories.dart';

SetupTest sample({TestStage stage = TestStage.draft}) => testExperiment(
        id: 'test',
        name: 'Roots and braking',
        stage: stage,
        before: {
          'FrontTire': {'Pressure': '22 psi'},
          'Fork': {'Compression': '6 clicks'}
        },
        values: {
          'FrontTire': {'Pressure': '21 psi'},
          'Fork': {'Compression': '4 clicks'}
        });

void main() {
  test('editing an experiment preserves baseline and protects logged rides',
      () async {
    final repo = MemoryTests()..records['test'] = sample(stage: TestStage.ride);
    final controller = TestsController(repo, FakeSetupsRepository());
    expect((await controller.editExperiment('bike', 'setup', 'test')).isSuccess,
        isTrue);
    expect(repo.records['test']!.stage, TestStage.draft);
    expect(repo.records['test']!.before, sample().before);
    expect(repo.records['test']!.values, sample().values);
    repo.records['test'] = sample(stage: TestStage.ride)
        .copyWith(rides: [const RideFeedback(feeling: 'Better')]);
    expect((await controller.editExperiment('bike', 'setup', 'test')).isSuccess,
        isFalse);
    expect(repo.records['test']!.stage, TestStage.ride);
    expect(repo.records['test']!.rides, hasLength(1));
    controller.dispose();
    await repo.updates.close();
  });

  testWidgets('detail menu edits, renames and discards an experiment',
      (tester) async {
    final repo = MemoryTests()..records['test'] = sample(stage: TestStage.ride);
    final deps = AppDependencies(
        testsRepository: (_) => repo,
        setupsRepository: (_) => FakeSetupsRepository());
    await tester.pumpWidget(Provider.value(
        value: deps,
        child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: TestsView(
                uid: 'user',
                bike: 'bike',
                setup: 'setup',
                setupName: 'Default',
                initialTest: repo.records['test']))));
    await tester.pumpAndSettle();
    expect(find.text('Discard experiment'), findsNothing);
    await tester.tap(find.byTooltip('Experiment options'));
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsOneWidget);
    await tester.tap(find.text('Edit settings'));
    await tester.pumpAndSettle();
    expect(repo.records['test']!.stage, TestStage.draft);
    expect(find.text('Front pressure'), findsOneWidget);
    await tester.tap(find.byTooltip('Close experiment'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Experiment options').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rename'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'More grip');
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(repo.records['test']!.name, 'More grip');
    expect(find.text('More grip'), findsWidgets);
    await tester.tap(find.byTooltip('Experiment options').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Discard experiment'));
    await tester.pumpAndSettle();
    expect(repo.records.containsKey('test'), isFalse);
    await tester.pumpWidget(const SizedBox());
    deps.dispose();
    await repo.updates.close();
  });

  test('track times accept seconds and exact milliseconds', () {
    for (final time in ['03:42', '03:42.156', '00:00.000', '999:59.999']) {
      final feedback = RideFeedback(feeling: 'Same', time: time);
      expect(feedback.validationError, isNull);
      expect(RideFeedback.fromMap(feedback.toMap()).time, time);
    }
    for (final time in ['03:60.000', '03:42.1', '03:42.1234']) {
      expect(
          RideFeedback(feeling: 'Same', time: time).validationError, isNotNull);
    }
  });

  testWidgets(
      'duration segments preserve long times with enlarged text and keyboard',
      (tester) async {
    tester.view.physicalSize = const Size(320, 850);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.darkTheme,
      home: const MediaQuery(
        data: MediaQueryData(
            textScaler: TextScaler.linear(2),
            viewInsets: EdgeInsets.only(bottom: 300)),
        child: Scaffold(
            body: SingleChildScrollView(
                child: TrackTimeSheet(initial: '120:59.987'))),
      ),
    ));
    await tester.pumpAndSettle();
    final fields =
        tester.widgetList<TextField>(find.byType(TextField)).toList();
    expect(fields[0].controller!.text, '120');
    expect(fields[1].controller!.text, '59');
    expect(fields[2].controller!.text, '987');
    await tester.ensureVisible(find.byKey(const ValueKey('ms')));
    await tester.enterText(find.byKey(const ValueKey('ms')), '');
    await tester.enterText(find.byKey(const ValueKey('ms')), 'a1234');
    expect(fields[2].controller!.text, '123');
    await tester.ensureVisible(find.text('Done'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  test('all five feedback ratings validate and round trip', () {
    for (final feeling in RideFeedback.feelings) {
      final feedback = RideFeedback(feeling: feeling);
      expect(feedback.validationError, isNull);
      expect(RideFeedback.fromMap(feedback.toMap()).feeling, feeling);
    }
  });

  test(
      'configured tests preserve selected parts without adding air fields to a coil fork',
      () async {
    final repo = MemoryTests();
    final setups = FakeSetupsRepository();
    final configuration = SetupConfiguration({
      'FrontTire': ['Pressure'],
      'RearTire': ['Pressure'],
      'Fork': ['Spring Rate', 'Preload', 'Sag', 'Rebound'],
      'GeneralSettings': ['Stem length', 'Seat Height'],
    });
    setups.information['setup'] = {
      SetupConfiguration.metadataKey: configuration.encode()
    };
    setups.settings['bike/setup/Fork/Spring Rate'] = '65 N/mm';
    setups.metadata['bike/setup/Fork/Serial'] = 'freeText';
    final controller = TestsController(repo, setups);
    final result = await controller.create('bike', 'setup', 'Coil');
    expect(result.isSuccess, isTrue);
    final draft = repo.records.values.single;
    final restored = SetupTest.fromMap(draft.copyWith(name: 'Renamed').toMap());
    expect(restored.setupInformation[SetupConfiguration.metadataKey],
        configuration.encode());
    expect(restored.fieldMetadata['Fork']!['Serial'], 'freeText');
    expect(draft.values.keys.toSet(), configuration.fields.keys.toSet());
    expect(draft.values['Fork']!['Spring Rate'], '65 N/mm');
    expect(draft.values['Fork']!.containsKey('Pressure'), isFalse);
    expect(draft.values['GeneralSettings']!.containsKey('Reach'), isFalse);
    controller.dispose();
    await repo.updates.close();
  });

  test('test snapshots preserve baseline and round-trip multi-setting changes',
      () async {
    final repo = MemoryTests();
    final setups = FakeSetupsRepository();
    setups.settings['bike/setup/FrontTire/Pressure'] = '22 psi';
    setups.settings['bike/setup/Fork/Compression'] = '6 clicks';
    final controller = TestsController(repo, setups);
    expect((await controller.create('bike', 'setup', 'Dry trails')).isSuccess,
        isTrue);
    final draft = repo.records.values.single;
    await Future.wait([
      controller.updateField(
          'bike', 'setup', draft.id, 'FrontTire', 'Pressure', '21 psi'),
      controller.updateField(
          'bike', 'setup', draft.id, 'Fork', 'Compression', '4 clicks'),
    ]);
    final restored = SetupTest.fromMap(repo.records.values.single.toMap());
    expect(restored.changes, hasLength(2));
    expect(restored.before['FrontTire']!['Pressure'], '22 psi');
    expect(setups.settings['bike/setup/FrontTire/Pressure'], '22 psi');
    await controller.create('bike', 'setup', 'Duplicate');
    expect(repo.records, hasLength(2));
    await controller.startTest('bike', 'setup', restored.id, restored.name);
    await controller.logRide(
        'bike', 'setup', restored.id, const RideFeedback(feeling: 'Better'));
    repo.fail = true;
    expect(
        (await controller.finish('bike', 'setup', restored.id, apply: true))
            .isSuccess,
        isFalse);
    expect(repo.records[restored.id]!.stage, TestStage.review);
    repo.fail = false;
    expect((await controller.finish('bike', 'setup', restored.id)).isSuccess,
        isTrue);
    expect(repo.applied, isFalse);
    controller.dispose();
    await repo.updates.close();
  });

  test('test commands enforce transitions and preserve queued changes',
      () async {
    final repo = MemoryTests();
    repo.records['test'] = sample();
    final controller = TestsController(repo, FakeSetupsRepository());
    addTearDown(controller.dispose);
    addTearDown(repo.updates.close);
    expect((await controller.resumeTest('bike', 'setup', 'test')).isSuccess,
        isFalse);
    await Future.wait([
      controller.renameExperiment(
          'bike', 'setup', 'test', TestStage.draft, 'Renamed'),
      controller.updateField(
          'bike', 'setup', 'test', 'Fork', 'Compression', '3 clicks'),
      controller.startTest('bike', 'setup', 'test', 'Renamed'),
    ]);
    expect(repo.records['test']!.values['Fork']!['Compression'], '3 clicks');
    expect(repo.records['test']!.stage, TestStage.ride);
    expect(
        (await controller.updateField(
                'bike', 'setup', 'test', 'Fork', 'Compression', '9 clicks'))
            .isSuccess,
        isFalse);
    expect(
        (await controller.logRide('bike', 'setup', 'test',
                const RideFeedback(feeling: 'Better', time: '03:99')))
            .isSuccess,
        isFalse);
    expect(repo.records['test']!.rides, isEmpty);
    expect(
        (await controller.logRide(
                'bike',
                'setup',
                'test',
                const RideFeedback(
                    feeling: 'Better', note: ' Grip ', time: '03:42')))
            .isSuccess,
        isTrue);
    expect(repo.records['test']!.rides.single.note, 'Grip');
    expect(
        (await controller.logRide(
                'bike', 'setup', 'test', const RideFeedback(feeling: 'Same')))
            .isSuccess,
        isFalse);
    await controller.resumeTest('bike', 'setup', 'test');
    await controller.logRide(
        'bike', 'setup', 'test', const RideFeedback(feeling: 'Same'));
    expect(repo.records['test']!.rides, hasLength(2));
    await controller.finish('bike', 'setup', 'test');
    expect((await controller.resumeTest('bike', 'setup', 'test')).isSuccess,
        isFalse);
  });

  test('typed feedback preserves the stored map format', () {
    final data = sample(stage: TestStage.review).copyWith(rides: [
      const RideFeedback(feeling: 'Better', note: 'Grip', time: '03:42')
    ]).toMap();
    expect(data['stage'], 'review');
    expect((data['rides'] as List).single,
        {'feeling': 'Better', 'note': 'Grip', 'time': '03:42'});
    final restored = SetupTest.fromMap(data);
    expect(restored.stage, TestStage.review);
    expect(restored.rides.single.validationError, isNull);
    expect(restored.toMap(), data);
  });

  testWidgets(
      'ride feedback picks, cancels and clears duration, records rides and finishes safely',
      (tester) async {
    tester.view.physicalSize = const Size(404, 1300);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repo = MemoryTests();
    repo.records['test'] = sample(stage: TestStage.ride);
    final deps = AppDependencies(
        testsRepository: (_) => repo,
        setupsRepository: (_) => FakeSetupsRepository());
    await tester.pumpWidget(Provider.value(
        value: deps,
        child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const Scaffold(
                body: TestsView(
              uid: 'user',
              bike: 'bike',
              setup: 'setup',
              setupName: 'Dry trails',
            )))));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Roots and braking'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Log ride'));
    await tester.pumpAndSettle();
    expect(find.text('Choose how the ride felt.'), findsOneWidget);
    final haptics = <String>[];
    tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'HapticFeedback.vibrate') {
        haptics.add(call.arguments as String);
      }
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null));
    for (var step = 0; step < 5; step++) {
      final slider = tester.widget<Slider>(find.byType(Slider));
      expect(slider.divisions, 4);
      slider.onChanged!(step.toDouble());
      slider.onChanged!(step.toDouble());
      slider.onChangeEnd!(step.toDouble());
      await tester.pumpAndSettle();
      expect(
          repo.records['test']!.feedback.feeling, RideFeedback.feelings[step]);
    }
    expect(haptics, List.filled(5, 'HapticFeedbackType.selectionClick'));

    tester.widget<Slider>(find.byType(Slider)).onChanged!(3);
    tester.widget<Slider>(find.byType(Slider)).onChangeEnd!(3);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'More grip on roots.');
    await tester.tap(find.text('Add time (optional)'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('min')), '03');
    await tester.enterText(find.byKey(const ValueKey('sec')), '99');
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(find.text('Seconds must be between 00 and 59.'), findsOneWidget);
    await tester.enterText(find.byKey(const ValueKey('sec')), '42');
    await tester.pump();
    expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('ms')))
            .focusNode!
            .hasFocus,
        isTrue);
    await tester.enterText(find.byKey(const ValueKey('ms')), '156');
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(repo.records['test']!.feedback.time, '03:42.156');
    await tester.tap(find.text('03:42.156'));
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('min')))
            .controller!
            .text,
        '03');
    await tester.enterText(find.byKey(const ValueKey('min')), '09');
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    expect(repo.records['test']!.feedback.time, '03:42.156');
    await tester.tap(find.text('03:42.156'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Clear'));
    await tester.pumpAndSettle();
    expect(repo.records['test']!.feedback.time, '');
    await tester.tap(find.text('Add time (optional)'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('min')), '03');
    await tester.enterText(find.byKey(const ValueKey('sec')), '42');
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Log ride'));
    await tester.pumpAndSettle();
    expect(repo.records['test']!.stage, TestStage.review);
    expect(find.text('More grip on roots.'), findsOneWidget);
    expect(repo.records['test']!.rides.single.time, '03:42.000');
    await tester.tap(find.text('Log another ride'));
    await tester.pumpAndSettle();
    tester.widget<Slider>(find.byType(Slider)).onChangeEnd!(2);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Log ride'));
    await tester.pumpAndSettle();
    expect(repo.records['test']!.rides, hasLength(2));
    await tester.ensureVisible(find.text('Finish experiment'));
    await tester.tap(find.text('Finish experiment'));
    await tester.pumpAndSettle();
    expect(repo.records['test']!.stage, TestStage.review);
    await tester.tap(find.text('Save as new setup'));
    await tester.pumpAndSettle();
    expect(find.text('Create setup'), findsOneWidget);
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    expect(repo.records['test']!.stage, TestStage.review);
    await tester.tap(find.text('Finish experiment'));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    expect(repo.records['test']!.stage, TestStage.review);
    await tester.tap(find.text('Finish experiment'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Keep current settings'));
    await tester.pumpAndSettle();
    expect(repo.records['test']!.stage, TestStage.finished);
    expect(repo.applied, isFalse);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    deps.dispose();
    await repo.updates.close();
  });

  testWidgets('new test opens directly and untouched exit removes draft',
      (tester) async {
    final repo = MemoryTests();
    final deps = AppDependencies(
        testsRepository: (_) => repo,
        setupsRepository: (_) => FakeSetupsRepository());
    await tester.pumpWidget(Provider.value(
        value: deps,
        child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const Scaffold(
                body: TestsView(
                    uid: 'user',
                    bike: 'bike',
                    setup: 'setup',
                    setupName: 'Dry trails')))));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create experiment'));
    for (var frame = 0; frame < 30; frame++) {
      await tester.pump(const Duration(milliseconds: 16));
      expect(
          find.text('Continue experiment', skipOffstage: false), findsNothing);
    }
    expect(find.byTooltip('Close experiment'), findsOneWidget);
    expect(repo.records, hasLength(1));
    await tester.tap(find.byTooltip('Close experiment'));
    await tester.pumpAndSettle();
    expect(repo.records, isEmpty);
    expect(find.text('Create experiment'), findsOneWidget);
    expect(find.text('Continue experiment'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    deps.dispose();
    await repo.updates.close();
  });

  test('draft cleanup waits for queued edits and preserves changed drafts',
      () async {
    final repo = MemoryTests();
    final draft = sample().copyWith(values: sample().before);
    repo.records['test'] = draft;
    final controller = TestsController(repo, FakeSetupsRepository());
    final edit = controller.updateField(
        'bike', 'setup', 'test', 'Fork', 'Compression', '8 clicks');
    final cleanup = controller.discardUnchangedDraft('bike', 'setup', 'test');
    await edit;
    await cleanup;
    expect(repo.records['test']!.values['Fork']!['Compression'], '8 clicks');
    repo.records['test'] = draft;
    await controller.discardUnchangedDraft('bike', 'setup', 'test');
    expect(repo.records, isEmpty);
    controller.dispose();
    await repo.updates.close();
  });

  testWidgets('ongoing tests keep feedback separate and return to the overview',
      (tester) async {
    tester.view.physicalSize = const Size(390, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repo = MemoryTests();
    repo.records['test'] = sample(stage: TestStage.ride);
    repo.records['second'] = testExperiment(
        id: 'second',
        name: 'Softer tires',
        stage: TestStage.ride,
        before: sample().before,
        values: sample().values);
    final deps = AppDependencies(
        testsRepository: (_) => repo,
        setupsRepository: (_) => FakeSetupsRepository());
    await tester.pumpWidget(Provider.value(
        value: deps,
        child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const Scaffold(
                body: TestsView(
                    uid: 'user',
                    bike: 'bike',
                    setup: 'setup',
                    setupName: 'Default')))));
    await tester.pumpAndSettle();
    expect(find.text('Ongoing experiments'), findsOneWidget);
    await tester.tap(find.text('Roots and braking'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'First test feedback');
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Softer tires'));
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text,
        isEmpty);
    await tester.enterText(find.byType(TextField), 'Second test feedback');
    final slider = tester.widget<Slider>(find.byType(Slider));
    slider.onChanged!(3);
    slider.onChangeEnd!(3);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Log ride'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Log ride'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Finish experiment'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Finish experiment'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Keep current settings'));
    await tester.pumpAndSettle();
    expect(find.text('Ongoing experiments'), findsOneWidget);
    expect(find.text('Previous experiments'), findsOneWidget);
    expect(repo.records['test']!.stage, TestStage.ride);
    expect(repo.records['second']!.stage, TestStage.finished);
    expect(repo.records['second']!.rides.single.note, 'Second test feedback');
    await tester.tap(find.text('Roots and braking'));
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'First test feedback');
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create experiment'));
    await tester.pumpAndSettle();
    expect(repo.records, hasLength(3));
    await tester.tap(find.byTooltip('Close experiment'));
    await tester.pumpAndSettle();
    expect(repo.records, hasLength(2));
    expect(repo.records['test']!.feedback.note, 'First test feedback');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    deps.dispose();
    await repo.updates.close();
  });

  testWidgets('previous tests reveal details without changing saved history',
      (tester) async {
    final repo = MemoryTests();
    final saved = sample(stage: TestStage.finished).copyWith(
        result: 'Applied to baseline',
        rides: [const RideFeedback(feeling: 'Better', note: 'More grip')]);
    repo.records['test'] = saved;
    final deps = AppDependencies(
        testsRepository: (_) => repo,
        setupsRepository: (_) => FakeSetupsRepository());
    await tester.pumpWidget(Provider.value(
        value: deps,
        child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const Scaffold(
                body: TestsView(
                    uid: 'user',
                    bike: 'bike',
                    setup: 'setup',
                    setupName: 'Dry trails')))));
    await tester.pumpAndSettle();
    expect(find.text('Applied to baseline'), findsOneWidget);
    expect(find.text('21 psi'), findsNothing);
    expect(find.text('More grip'), findsNothing);
    await tester.tap(find.text('Roots and braking'));
    await tester.pumpAndSettle();
    expect(find.text('21 psi'), findsOneWidget);
    await tester.ensureVisible(find.text('More grip'));
    expect(find.text('More grip'), findsOneWidget);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text('21 psi'), findsNothing);
    expect(repo.records['test'], same(saved));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    deps.dispose();
    await repo.updates.close();
  });

  for (final stage in [TestStage.draft, TestStage.ride, TestStage.review]) {
    testWidgets('$stage fits narrow screens with enlarged text',
        (tester) async {
      tester.view.physicalSize = const Size(320, 850);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repo = MemoryTests();
      repo.records['test'] = sample(stage: stage);
      final deps = AppDependencies(
          testsRepository: (_) => repo,
          setupsRepository: (_) => FakeSetupsRepository());
      await tester.pumpWidget(Provider.value(
          value: deps,
          child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: MediaQuery(
                  data: const MediaQueryData(textScaler: TextScaler.linear(2)),
                  child: const Scaffold(
                      body: TestsView(
                    uid: 'user',
                    bike: 'bike',
                    setup: 'setup',
                    setupName: 'Dry trails',
                  ))))));
      await tester.pumpAndSettle();
      if (stage != TestStage.draft) {
        await tester.scrollUntilVisible(find.text('Roots and braking'), 300);
        await tester.tap(find.text('Roots and braking'));
        await tester.pumpAndSettle();
      }
      await tester.drag(find.byType(ListView), const Offset(0, -600));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      deps.dispose();
      await repo.updates.close();
    });
  }
}
