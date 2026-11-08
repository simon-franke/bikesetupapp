import 'dart:async';
import 'package:bikesetupapp/features/rides/repositories/rides_repository.dart';
import 'package:bikesetupapp/features/rides/models/ride.dart';

import 'package:bikesetupapp/app/app_dependencies.dart';
import 'package:bikesetupapp/common/data/firestore_keys.dart';
import 'package:bikesetupapp/common/theme/theme_data.dart';
import 'package:bikesetupapp/features/setups/models/setup_configuration.dart';
import 'package:bikesetupapp/features/setups/ui/setup_category_view.dart';
import 'package:bikesetupapp/features/workspace/ui/home_page.dart';
import 'package:bikesetupapp/features/workspace/ui/setup_workspace.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'support/fake_auth_repository.dart';
import 'support/fake_repositories.dart';

class _DelayedConfiguration extends FakeSetupsRepository {
  final reload = Completer<void>();
  bool saved = false;

  @override
  Future<void> createSetupList(String bike, String setup, String name,
      Map<String, dynamic> information) async {
    await super.createSetupList(bike, setup, name, information);
    saved = true;
  }

  @override
  Future<Map<String, dynamic>> getSetupInformation(
      String bike, String setup) async {
    if (saved) await reload.future;
    return super.getSetupInformation(bike, setup);
  }
}

class _NoRides extends Fake implements RidesRepository {
  @override
  Stream<List<Ride>> watch(String bikeId) => Stream.value([]);
}

class _NoMileage extends FakeStravaBikesRepository {
  @override
  Future<double?> getMileageForBike(String id) async => null;
}

void main() {
  testWidgets(
      'adding a category keeps the workspace alive until reload opens it',
      (tester) async {
    final configuration = SetupConfiguration({});
    final setups = _DelayedConfiguration()
      ..names['setup'] = 'Baseline'
      ..information['setup'] = {
        FirestoreKeys.setupConfiguration: configuration.encode(),
      };
    final dependencies = AppDependencies(
      setupsRepository: (_) => setups,
      ridesRepository: (_) => _NoRides(),
      stravaRepository: FakeStravaRepository(),
      stravaBikesRepository: (_) => _NoMileage(),
    );
    addTearDown(dependencies.dispose);
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(Provider.value(
      value: dependencies,
      child: MaterialApp(
        theme: AppTheme.darkTheme,
        home: MyHomePage(
            user: SessionUser(),
            bikeName: 'Trail bike',
            uBikeID: 'bike',
            setupName: 'Baseline',
            uSetupID: 'setup',
            initialConfiguration: configuration),
      ),
    ));
    await tester.pumpAndSettle();
    final workspace = tester.state(find.byType(SetupWorkspace));
    await tester.tap(find.text('Add category').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add new'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Luggage');
    await tester.tap(find.text('Add category').last);
    await tester.pumpAndSettle();
    expect(setups.saved, isTrue);
    expect(workspace.mounted, isTrue);
    setups.reload.complete();
    await tester.pumpAndSettle();
    expect(find.byType(SetupCategoryView), findsOneWidget);
    expect(find.text('Luggage'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Luggage'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
