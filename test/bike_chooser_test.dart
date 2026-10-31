import 'dart:async';
import 'package:bikesetupapp/app/app_dependencies.dart';
import 'package:bikesetupapp/features/bikes/models/bike.dart';
import 'package:bikesetupapp/features/bikes/repositories/bikes_repository.dart';
import 'package:bikesetupapp/features/bikes/ui/bike_list.dart';
import 'package:bikesetupapp/features/setups/models/bike_setup.dart';
import 'package:bikesetupapp/features/setups/repositories/setups_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter/cupertino.dart';
import 'dart:ui' show Tristate;

import 'package:bikesetupapp/common/theme/theme_data.dart';
import 'package:bikesetupapp/features/bikes/ui/bike_chooser_sheet.dart';
import 'package:bikesetupapp/features/bikes/ui/setup_choice_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget harness(Widget child, {double scale = 1}) => MaterialApp(
      theme: ThemeData(extensions: const [AppPalette.dark]),
      home: Scaffold(
          body: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(scale)),
        child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(width: 320, height: 500, child: child)),
      )),
    );

class ChooserUser extends Fake implements User {
  @override
  String get uid => 'user';
}

class ChooserBikes extends Fake implements BikesRepository {
  String? selectedBike = 'current';
  String? deletedBike;
  Completer<void>? deletion;
  @override
  Future<String> getDefaultBike() async => selectedBike!;
  @override
  Future<String> getBikeNameFromID(String id) async => 'Other bike';
  @override
  Future<void> deleteBike(String id) async {
    await deletion?.future;
    deletedBike = id;
    if (selectedBike == id) selectedBike = 'other';
  }

  @override
  Future<void> setDefaultBike(String id) async {
    selectedBike = id;
  }

  @override
  Stream<List<Bike>> getBikes() => Stream.value(const [
        Bike(id: 'other', name: 'Other bike'),
        Bike(id: 'current', name: 'Current bike'),
      ]);
}

class ChooserSetups extends Fake implements SetupsRepository {
  final subscriptions = <String, int>{};
  @override
  Future<String> getDefaultSetup(String bike) async => 'saved-setup';
  @override
  Future<String> getSetupNameFromID(String bike, String setup) async => 'Trail';

  @override
  Stream<List<BikeSetup>> getSetups(String id) => Stream.multi((controller) {
        subscriptions.update(id, (count) => count + 1, ifAbsent: () => 1);
        controller.add([BikeSetup(id: 'default', name: '$id setup')]);
        controller.close();
      });
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  testWidgets(
      'deleting the selected bike uses a sheet and selects its replacement',
      (tester) async {
    final bikes = ChooserBikes();
    final dependencies = AppDependencies(
        bikesRepository: (_) => bikes,
        setupsRepository: (_) => ChooserSetups());
    addTearDown(dependencies.dispose);
    List<String>? selected;
    await tester.pumpWidget(Provider.value(
        value: dependencies,
        child: harness(BikeList(
            user: ChooserUser(),
            selectedBikeId: 'current',
            selectedSetupId: 'default',
            onSetupDetails: (_, __, ___, ____) {},
            onBikeSelected: (name, bike, setupName, setup) =>
                selected = [name, bike, setupName, setup]))));
    await tester.pumpAndSettle();
    Future<void> openConfirmation() async {
      await tester.tap(find.byTooltip('Bike options'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete bike'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.byType(BottomSheet), findsOneWidget);
      expect(find.text('Delete Current bike?'), findsOneWidget);
    }

    await openConfirmation();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(bikes.deletedBike, isNull);
    expect(selected, isNull);
    await openConfirmation();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(bikes.deletedBike, 'current');
    expect(selected, ['Other bike', 'other', 'Trail', 'saved-setup']);
    expect(tester.takeException(), isNull);
  });
  testWidgets('deletion still updates workspace after chooser is dismissed',
      (tester) async {
    final bikes = ChooserBikes()..deletion = Completer<void>();
    final dependencies = AppDependencies(
        bikesRepository: (_) => bikes,
        setupsRepository: (_) => ChooserSetups());
    addTearDown(dependencies.dispose);
    List<String>? selected;
    await tester.pumpWidget(Provider.value(
      value: dependencies,
      child: MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(
            body: Builder(
                builder: (context) => TextButton(
                      child: const Text('Choose bike'),
                      onPressed: () => showBikeChooserSheet(
                          context: context,
                          user: ChooserUser(),
                          selectedBikeId: 'current',
                          selectedSetupId: 'default',
                          onBikeSelected: (name, bike, setupName, setup) =>
                              selected = [name, bike, setupName, setup]),
                    ))),
      ),
    ));
    await tester.tap(find.text('Choose bike'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Bike options'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete bike'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    expect(find.byType(BikeList), findsNothing);
    bikes.deletion!.complete();
    await tester.pumpAndSettle();
    expect(selected, ['Other bike', 'other', 'Trail', 'saved-setup']);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Service selects a bike directly and keeps its saved setup',
      (tester) async {
    final bikes = ChooserBikes();
    final setups = ChooserSetups();
    final dependencies = AppDependencies(
        bikesRepository: (_) => bikes, setupsRepository: (_) => setups);
    addTearDown(dependencies.dispose);
    List<String>? selected;
    await tester.pumpWidget(Provider.value(
        value: dependencies,
        child: harness(BikeList(
            user: ChooserUser(),
            bikesOnly: true,
            selectedBikeId: 'current',
            selectedSetupId: 'default',
            onSetupDetails: (_, __, ___, ____) {},
            onBikeSelected: (name, bike, setupName, setup) =>
                selected = [name, bike, setupName, setup]))));
    await tester.pumpAndSettle();
    expect(find.text('Add setup'), findsNothing);
    expect(setups.subscriptions, isEmpty);
    await tester.tap(find.text('Other bike'));
    await tester.pumpAndSettle();
    expect(selected, ['Other bike', 'other', 'Trail', 'saved-setup']);
    expect(bikes.selectedBike, 'other');
    expect(tester.takeException(), isNull);
  });
  testWidgets('bike accordion animates height without reloading setup streams',
      (tester) async {
    final setups = ChooserSetups();
    final dependencies = AppDependencies(
        bikesRepository: (_) => ChooserBikes(),
        setupsRepository: (_) => setups);
    addTearDown(dependencies.dispose);
    await tester.pumpWidget(Provider.value(
      value: dependencies,
      child: harness(BikeList(
          user: ChooserUser(),
          selectedBikeId: 'current',
          selectedSetupId: 'default',
          onSetupDetails: (_, __, ___, ____) {},
          onBikeSelected: (_, __, ___, ____) {})),
    ));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.text('Current bike')).dy,
        lessThan(tester.getTopLeft(find.text('Other bike')).dy));
    final card = find.byKey(const Key('current'));
    final expanded = tester.getSize(card).height;
    await tester.tap(find.text('Current bike'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
    final middle = tester.getSize(card).height;
    await tester.pumpAndSettle();
    final collapsed = tester.getSize(card).height;
    expect(middle, lessThan(expanded));
    expect(middle, greaterThan(collapsed));
    await tester.tap(find.text('Current bike'));
    await tester.pumpAndSettle();
    expect(find.text('current setup'), findsOneWidget);
    expect(setups.subscriptions, {'current': 1, 'other': 1});
    expect(tester.takeException(), isNull);
  });
  testWidgets('setup details and editing do not trigger selection',
      (tester) async {
    var selected = 0;
    var edited = 0;
    var details = 0;
    await tester.pumpWidget(harness(SetupChoiceTile(
      name: 'Default',
      isSelected: true,
      onSelect: () => selected++,
      onEdit: () => edited++,
      onDetails: () => details++,
    )));
    await tester.longPress(find.text('Default'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Setup details'));
    await tester.pumpAndSettle();
    await tester.longPress(find.text('Default'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit setup'));
    await tester.pumpAndSettle();
    expect(details, 1);
    expect(edited, 1);
    expect(selected, 0);
    await tester.tap(find.text('Default'));
    expect(selected, 1);
    expect(find.byIcon(CupertinoIcons.check_mark), findsOneWidget);
  });

  testWidgets('only the selected setup announces selection and shows details',
      (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(harness(Column(children: [
      SetupChoiceTile(
          name: 'Default',
          isSelected: false,
          onSelect: () {},
          onEdit: () {},
          onDetails: () {}),
      SetupChoiceTile(
          name: 'Race day',
          isSelected: true,
          onSelect: () {},
          onEdit: () {},
          onDetails: () {}),
    ])));
    expect(find.byIcon(CupertinoIcons.check_mark), findsOneWidget);
    expect(find.text('Current setup'), findsNothing);
    expect(
        tester
            .getSemantics(find.text('Race day'))
            .getSemanticsData()
            .flagsCollection
            .isSelected,
        Tristate.isTrue);
    semantics.dispose();
  });

  testWidgets(
      'chooser keeps Add bike visible while a long list scrolls at enlarged text',
      (tester) async {
    var added = 0;
    await tester.pumpWidget(harness(
        BikeChooserContent(
          onAddBike: () => added++,
          bikeList: ListView(
              children: List.generate(
                  20,
                  (index) => SetupChoiceTile(
                        name: 'Bike $index trail setup',
                        isSelected: index == 0,
                        onSelect: () {},
                        onEdit: () {},
                        onDetails: () {},
                      ))),
        ),
        scale: 2));
    expect(tester.takeException(), isNull);
    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add bike'));
    expect(added, 1);
    expect(tester.takeException(), isNull);
  });
  for (final count in [2, 20]) {
    testWidgets('phone chooser fits $count bikes and keeps actions visible',
        (tester) async {
      var added = 0;
      await tester.pumpWidget(MaterialApp(
        theme: ThemeData(extensions: const [AppPalette.dark]),
        home: Scaffold(
            body: Center(
                child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480, maxHeight: 480),
          child: BikeChooserContent(
            onAddBike: () => added++,
            bikeList: ListView(
                shrinkWrap: true,
                children: List.generate(count,
                    (i) => SizedBox(height: 72, child: Text('Bike $i')))),
          ),
        ))),
      ));
      await tester.pumpAndSettle();
      expect(tester.getSize(find.byType(BikeChooserContent)).height,
          count == 2 ? lessThan(400) : lessThanOrEqualTo(480));
      expect(find.byTooltip('Close bike chooser'), findsNothing);
      if (count == 20) {
        await tester.drag(find.byType(ListView), const Offset(0, -1000));
        await tester.pumpAndSettle();
      }
      await tester.tap(find.text('Add bike'));
      expect(added, 1);
      expect(tester.takeException(), isNull);
    });
  }
}
