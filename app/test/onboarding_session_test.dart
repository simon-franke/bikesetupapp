import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:bikesetupapp/features/setups/models/bike_setup.dart';
import 'package:bikesetupapp/main.dart';
import 'package:bikesetupapp/app/app_dependencies.dart';
import 'package:bikesetupapp/common/models/command_result.dart';
import 'package:bikesetupapp/common/theme/theme_data.dart';
import 'package:bikesetupapp/common/ui/app_sheet.dart';
import 'package:bikesetupapp/features/auth/ui/google_sign_in.dart';
import 'package:bikesetupapp/features/settings/controllers/app_state_notifier.dart';
import 'package:bikesetupapp/features/settings/controllers/settings_controller.dart';
import 'package:bikesetupapp/features/settings/ui/settings_page.dart';
import 'package:bikesetupapp/features/workspace/ui/home_page.dart';
import 'package:bikesetupapp/features/workspace/ui/view_toggle.dart';
import 'package:bikesetupapp/features/bikes/ui/quick_bike_sheet.dart';
import 'package:bikesetupapp/features/bikes/ui/bike_chooser_sheet.dart';
import 'package:bikesetupapp/features/bikes/models/bike.dart';
import 'package:bikesetupapp/features/rides/repositories/rides_repository.dart';
import 'package:bikesetupapp/features/rides/models/ride.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'support/fake_auth_repository.dart';
import 'support/fake_repositories.dart';

class EmptyRides extends Fake implements RidesRepository {
  @override
  Stream<List<Ride>> watch(String bikeId) => Stream.value([]);
}

class EmptyStravaBikes extends FakeStravaBikesRepository {
  @override
  Future<double?> getMileageForBike(String id) async => null;
}

class DeletableBikes extends FakeBikesRepository {
  final changes = StreamController<List<Bike>>.broadcast();
  Completer<void>? afterRemoval;
  @override
  Stream<List<Bike>> getBikes() async* {
    yield List.of(bikes);
    yield* changes.stream;
  }

  bool failDeletion = false;
  Completer<void>? deletion;
  @override
  Future<void> deleteBike(String id) async {
    await deletion?.future;
    if (failDeletion) throw const AppFailure(FailureCode.saveFailed);
    bikes.removeWhere((bike) => bike.id == id);
    changes.add(List.of(bikes));
    await afterRemoval?.future;
    if (defaultBike == id) defaultBike = bikes.firstOrNull?.id ?? '';
  }
}

class ChoosableSetups extends FakeSetupsRepository {
  int informationReads = 0;
  @override
  Future<Map<String, dynamic>> getSetupInformation(String bike, String setup) {
    informationReads++;
    return super.getSetupInformation(bike, setup);
  }

  @override
  Stream<List<BikeSetup>> getSetups(String bike) => Stream.value([
        for (final entry in names.entries)
          BikeSetup(id: entry.key, name: entry.value),
      ]);
}

void main() {
  setUpAll(() async {
    if (Platform.environment['MOTION_REVIEW_OUTPUT'] != null) {
      for (final font in {
        'Sora': 'assets/fonts/Sora.ttf',
        'MaterialIcons': 'fonts/MaterialIcons-Regular.otf',
        'packages/cupertino_icons/CupertinoIcons':
            'packages/cupertino_icons/assets/CupertinoIcons.ttf',
      }.entries) {
        await (FontLoader(font.key)..addFont(rootBundle.load(font.value)))
            .load();
      }
    }
  });
  late FakeAuthRepository auth;
  late DeletableBikes bikes;
  late FakeSetupsRepository setups;
  late AppDependencies dependencies;
  final reviewBoundary = GlobalKey();
  setUp(() {
    auth = FakeAuthRepository();
    bikes = DeletableBikes();
    setups = ChoosableSetups();
    dependencies = AppDependencies(
        authRepository: auth,
        bikesRepository: (_) => bikes,
        setupsRepository: (_) => setups,
        stravaRepository: FakeStravaRepository(),
        stravaBikesRepository: (_) => EmptyStravaBikes(),
        ridesRepository: (_) => EmptyRides());
  });
  tearDown(() async {
    dependencies.dispose();
    await bikes.changes.close();
    await auth.events.close();
  });
  Future<void> mount(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(Provider.value(
        value: dependencies,
        child: ChangeNotifierProvider(
            create: (_) => AppStateNotifier(ThemeMode.dark),
            child:
                RepaintBoundary(key: reviewBoundary, child: const MyApp()))));
    await tester.pumpAndSettle();
  }

  void existingBike() {
    bikes.defaultBike = 'bike';
    bikes.bikes = [const Bike(id: 'bike', name: 'Trail bike')];
    setups.defaults['bike'] = 'setup';
    setups.names['setup'] = 'Baseline';
  }

  testWidgets('creation transition retains form and opens a ready workspace',
      (tester) async {
    auth.user = SessionUser();
    await mount(tester);
    expect(find.byTooltip('Settings'), findsOneWidget);
    expect(find.text('Account'), findsNothing);
    await tester.enterText(find.byType(TextField), 'Trail bike');
    await tester.tap(find.text('Add bike'));
    await tester.pump();
    for (var frame = 0; frame < 20; frame++) {
      await tester.pump(const Duration(milliseconds: 16));
      expect(find.byType(CircularProgressIndicator), findsNothing);
      if (find.byType(QuickBikeSheet).evaluate().isNotEmpty) {
        expect(find.text('Trail bike'), findsWidgets);
      }
      final output = Platform.environment['MOTION_REVIEW_OUTPUT'];
      if (output != null && [0, 5, 10, 19].contains(frame)) {
        await tester.runAsync(() async {
          final image = await (reviewBoundary.currentContext!.findRenderObject()
                  as RenderRepaintBoundary)
              .toImage();
          final data = await image.toByteData(format: ui.ImageByteFormat.png);
          await Directory(output).create(recursive: true);
          await File('$output/create-$frame.png')
              .writeAsBytes(data!.buffer.asUint8List());
          image.dispose();
        });
      }
    }
    await tester.pumpAndSettle();
    expect(find.byType(MyHomePage), findsOneWidget);
    expect((setups as ChoosableSetups).informationReads, 0);
    expect(tester.takeException(), isNull);
  });

  for (final dismissChooser in [false, true]) {
    testWidgets(
        'last-bike deletion keeps confirmation until ready, outside tap=$dismissChooser',
        (tester) async {
      auth.user = SessionUser();
      existingBike();
      await mount(tester);
      Future<void> confirmSheet() async {
        await tester.tap(find.text('Trail bike'));
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('Bike options'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Delete bike'));
        await tester.pumpAndSettle();
        expect(find.text('Delete Trail bike?'), findsOneWidget);
      }

      await confirmSheet();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(bikes.bikes, hasLength(1));
      // The chooser remains open after cancelling confirmation.
      await tester.tap(find.byTooltip('Bike options'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete bike'));
      await tester.pumpAndSettle();
      bikes.failDeletion = true;
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      expect(find.byType(MyHomePage), findsOneWidget);
      expect(bikes.bikes, hasLength(1));
      expect(find.text('Delete Trail bike?'), findsOneWidget);
      expect(find.byType(BikeChooserContent), findsNothing);
      bikes.failDeletion = false;
      bikes.deletion = Completer<void>();
      bikes.afterRemoval = Completer<void>();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      if (dismissChooser) {
        await tester.tapAt(const Offset(10, 10));
        await tester.pumpAndSettle();
      }
      bikes.deletion!.complete();
      await tester.pumpAndSettle();
      expect(bikes.bikes, isEmpty);
      expect(find.text('Deleting…'), findsOneWidget);
      expect(find.text('Delete Trail bike?'), findsOneWidget);
      expect(find.byType(BottomSheet), findsOneWidget);
      expect(find.byType(BikeChooserContent), findsNothing);
      bikes.afterRemoval!.complete();
      if (!dismissChooser &&
          Platform.environment['MOTION_REVIEW_OUTPUT'] != null) {
        for (var frame = 0; frame < 40; frame++) {
          await tester.pump(const Duration(milliseconds: 16));
          if ([0, 4, 8, 12, 15, 22, 30, 39].contains(frame)) {
            await tester.runAsync(() async {
              final image = await (reviewBoundary.currentContext!
                      .findRenderObject() as RenderRepaintBoundary)
                  .toImage();
              final data =
                  await image.toByteData(format: ui.ImageByteFormat.png);
              final output = Platform.environment['MOTION_REVIEW_OUTPUT']!;
              await Directory(output).create(recursive: true);
              await File('$output/delete-$frame.png')
                  .writeAsBytes(data!.buffer.asUint8List());
              image.dispose();
            });
          }
        }
      }
      await tester.pumpAndSettle();
      expect(find.byType(MyHomePage), findsNothing);
      expect(find.byType(BottomSheet), findsNothing);
      expect(find.text('What do you ride?'), findsOneWidget);
      expect(find.byType(QuickBikeSheet), findsOneWidget);
      expect(bikes.defaultBike, isEmpty);
      expect(auth.currentUser, isNotNull);
      await tester.enterText(find.byType(TextField), 'Replacement bike');
      await tester.tap(find.text('Add bike'));
      await tester.pumpAndSettle();
      expect(find.byType(MyHomePage), findsOneWidget);
      expect(bikes.bikes.single.name, 'Replacement bike');
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
      'email signup creates a bike and opens the workspace without onboarding prompts',
      (tester) async {
    await mount(tester);
    expect(find.byType(ViewToggle), findsNothing);
    await tester.tap(find.text('Continue with email'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('New here? Create an account'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), 'rider@example.com');
    await tester.enterText(find.byType(TextField).at(1), 'password');
    await tester.tap(find.text('Create account').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Weekend bike');
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Add bike'));
    await tester.tap(find.text('Add bike'));
    await tester.pumpAndSettle();
    expect(find.byType(MyHomePage), findsOneWidget);
    expect(find.text('Start with your tire pressures'), findsNothing);
    expect(find.text('Save your bikes to an account'), findsNothing);
    expect(setups.names.values, ['Baseline']);
    expect(setups.settings.values.every((value) => value.isEmpty), isTrue);
    expect(setups.settings.keys.any((key) => key.contains('/Fork/')), isFalse);
    expect(auth.currentUser!.isAnonymous, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('sign-out removes settings, workspace, sheets and back history',
      (tester) async {
    auth.user = SessionUser();
    existingBike();
    await mount(tester);
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    // Settings is outside the workspace, with no tab bar underneath.
    expect(find.byType(ViewToggle), findsNothing);
    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();
    expect(find.byType(LoginPage), findsOneWidget);
    expect(find.byType(SettingsPage), findsNothing);
    expect(find.byType(MyHomePage), findsNothing);
    expect(
        Navigator.of(tester.element(find.byType(LoginPage))).canPop(), isFalse);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(LoginPage), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('failed sign-out retains settings and account', (tester) async {
    auth.user = SessionUser();
    auth.failSignOut = true;
    existingBike();
    await mount(tester);
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();
    expect(find.byType(SettingsPage), findsOneWidget);
    expect(auth.currentUser, isNotNull);
    expect(find.text('Check your connection and try again.'), findsOneWidget);
  });

  testWidgets(
      'failed email sign-in keeps sheet and input; success restores existing bike',
      (tester) async {
    existingBike();
    await mount(tester);
    await tester.tap(find.text('Continue with email'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), 'rider@example.com');
    await tester.enterText(find.byType(TextField).at(1), 'password');
    auth.failSignIn = true;
    await tester.tap(find.text('Sign in').last);
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsOneWidget);
    expect(find.text('rider@example.com'), findsOneWidget);
    auth.failSignIn = false;
    await tester.tap(find.text('Sign in').last);
    await tester.pumpAndSettle();
    expect(find.byType(MyHomePage), findsOneWidget);
    expect(find.byType(BottomSheet), findsNothing);
    expect(find.byType(LoginPage), findsNothing);
    expect(find.text('Start with your tire pressures'), findsNothing);
  });

  testWidgets('password reset keeps the entered email and returns to sign in',
      (tester) async {
    await mount(tester);
    await tester.tap(find.text('Continue with email'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'rider@example.com');
    await tester.tap(find.text('Forgot password?'));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsOneWidget);
    await tester.tap(find.text('Send reset link'));
    await tester.pumpAndSettle();
    expect(auth.resetEmail, 'rider@example.com');
    expect(
        find.text('If an account uses this email, a reset link has been sent.'),
        findsOneWidget);
    await tester.tap(find.text('Back to sign in'));
    await tester.pumpAndSettle();
    expect(find.text('rider@example.com'), findsOneWidget);
    expect(auth.currentUser, isNull);
  });

  testWidgets(
      'account deletion can retry without leaving the confirmation screen',
      (tester) async {
    auth.user = SessionUser();
    existingBike();
    await mount(tester);
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Delete account'));
    await tester.tap(find.text('Delete account'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'password');
    auth.failDeletion = true;
    await tester.tap(find.widgetWithText(FilledButton, 'Delete account'));
    await tester.pumpAndSettle();
    expect(find.text('Could not finish deleting your account. Please retry.'),
        findsOneWidget);
    expect(auth.currentUser, isNotNull);
    auth.failDeletion = false;
    await tester.tap(find.widgetWithText(FilledButton, 'Delete account'));
    await tester.pumpAndSettle();
    expect(find.byType(LoginPage), findsOneWidget);
    expect(find.byType(MyHomePage), findsNothing);
    expect(auth.currentUser, isNull);
  });

  testWidgets('saving a guest account returns to the same bike and settings',
      (tester) async {
    auth.user = SessionUser(guest: true);
    existingBike();
    setups.settings['bike/setup/FrontTire/Pressure'] = '24 psi';
    await mount(tester);
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save account'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue with email'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), 'rider@example.com');
    await tester.enterText(find.byType(TextField).at(1), 'password');
    await tester.tap(find.text('Create account').last);
    await tester.pumpAndSettle();
    expect(find.byType(MyHomePage), findsOneWidget);
    expect(auth.currentUser!.uid, 'user');
    expect(auth.currentUser!.isAnonymous, isFalse);
    expect(setups.settings['bike/setup/FrontTire/Pressure'], '24 psi');
    expect(bikes.bikes.length, 1);
    expect(find.byType(LoginPage), findsNothing);
    expect(find.byType(BottomSheet), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('external session loss removes a root sheet', (tester) async {
    auth.user = SessionUser();
    await mount(tester);
    showAppSheet<void>(
        context: tester.element(find.byType(QuickBikeSheet)),
        builder: (_) => const Text('Open form'));
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsOneWidget);
    auth.setUser(null);
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsNothing);
    expect(find.byType(LoginPage), findsOneWidget);
  });

  test('guests cannot start Strava authorization', () async {
    auth.user = SessionUser(guest: true);
    final settings = SettingsController(
        dependencies.auth,
        dependencies.stravaConnection,
        (uid) => dependencies.forUser(uid).strava);
    expect((await settings.connect()).failure?.code,
        FailureCode.authenticationFailed);
    settings.dispose();
  });

  for (final scale in [1.0, 2.0]) {
    testWidgets(
        'sign-in and bike creation fit a small phone at text scale $scale',
        (tester) async {
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(Provider.value(
          value: dependencies,
          child: MaterialApp(
              theme: AppTheme.darkTheme,
              builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(context)
                      .copyWith(textScaler: TextScaler.linear(scale)),
                  child: child!),
              home: const LoginPage())));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(Provider.value(
          value: dependencies,
          child: MaterialApp(
              theme: AppTheme.darkTheme,
              home: Scaffold(
                  body: SingleChildScrollView(
                      child: MediaQuery(
                          data: MediaQueryData(
                              size: const Size(320, 700),
                              textScaler: TextScaler.linear(scale)),
                          child: QuickBikeSheet(
                              user: SessionUser(),
                              onCreated:
                                  (_, __, ___, ____, configuration) {})))))));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
