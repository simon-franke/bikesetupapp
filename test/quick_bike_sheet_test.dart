import 'dart:io';
import 'dart:async';
import 'package:bikesetupapp/common/models/command_result.dart';
import 'package:bikesetupapp/common/ui/app_loading.dart';
import 'dart:ui' as ui;
import 'package:bikesetupapp/app/app_dependencies.dart';
import 'package:bikesetupapp/common/theme/theme_data.dart';
import 'package:bikesetupapp/features/bikes/ui/quick_bike_sheet.dart';
import 'package:bikesetupapp/features/setups/models/setup_configuration.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'support/fake_repositories.dart';
import 'support/fake_auth_repository.dart';

class PendingBikeRepository extends FakeBikesRepository {
  final finish = Completer<void>();
  @override
  Future<void> createBikeRecord(String id, String name) async {
    await finish.future;
    throw const AppFailure(FailureCode.saveFailed);
  }
}

void main() {
  testWidgets('saving covers the screen and failure restores the entered name',
      (tester) async {
    final bikes = PendingBikeRepository();
    final setups = FakeSetupsRepository();
    final deps = AppDependencies(
        bikesRepository: (_) => bikes, setupsRepository: (_) => setups);
    await tester.pumpWidget(Provider.value(
        value: deps,
        child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: Scaffold(
                body: QuickBikeSheet(
                    user: SessionUser(),
                    isSheet: false,
                    onCreated: (_, __, ___, ____, configuration) {})))));
    await tester.enterText(find.byType(TextField), 'Trail bike');
    await tester.tap(find.text('Add bike'));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 16));
    expect(find.byType(AppLoadingState), findsOneWidget);
    expect(find.byType(AppLoadingIndicator), findsOneWidget);
    expect(
        tester.getCenter(find.byType(AppLoadingState)), const Offset(400, 300));
    bikes.finish.complete();
    await tester.pumpAndSettle();
    expect(find.byType(AppLoadingState), findsNothing);
    expect(find.text('Trail bike'), findsOneWidget);
    expect(find.text('Add bike'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    deps.dispose();
  });
  setUpAll(() async {
    for (final font in {
      'Sora': 'assets/fonts/Sora.ttf',
      'MaterialIcons': 'fonts/MaterialIcons-Regular.otf',
      'packages/cupertino_icons/CupertinoIcons':
          'packages/cupertino_icons/assets/CupertinoIcons.ttf',
    }.entries) {
      await (FontLoader(font.key)..addFont(rootBundle.load(font.value))).load();
    }
  });
  for (final scale in [1.0, 2.0]) {
    testWidgets('name-only bike creation works with keyboard at scale $scale',
        (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);
      final bikes = FakeBikesRepository();
      final setups = FakeSetupsRepository();
      final deps = AppDependencies(
          bikesRepository: (_) => bikes, setupsRepository: (_) => setups);
      final boundary = GlobalKey();
      String? setupId;
      await tester.pumpWidget(Provider.value(
          value: deps,
          child: RepaintBoundary(
            key: boundary,
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: AppTheme.darkTheme,
              builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(context)
                      .copyWith(textScaler: TextScaler.linear(scale)),
                  child: child!),
              home: Scaffold(
                  appBar: AppBar(title: const Text('Clickwise')),
                  body: SafeArea(
                      child: QuickBikeSheet(
                          user: SessionUser(),
                          isSheet: false,
                          onCreated: (_, __, ___, id, configuration) =>
                              setupId = id))),
            ),
          )));
      await tester.pumpAndSettle();
      final output = Platform.environment['UI_REVIEW_OUTPUT'];
      if (output != null) {
        await tester.runAsync(() async {
          final image = await (boundary.currentContext!.findRenderObject()
                  as RenderRepaintBoundary)
              .toImage(pixelRatio: 2);
          final data = await image.toByteData(format: ui.ImageByteFormat.png);
          await Directory(output).create(recursive: true);
          await File('$output/first-bike-$scale.png')
              .writeAsBytes(data!.buffer.asUint8List());
          image.dispose();
        });
      }
      await tester.enterText(find.byType(TextField), 'Trail bike');
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Suspension'), findsNothing);
      await tester.tap(find.text('Add bike'));
      await tester.pumpAndSettle();
      expect(bikes.bikes.single.name, 'Trail bike');
      final config =
          SetupConfiguration.fromInformation(setups.information[setupId!]!);
      expect(config.fields.containsKey('Fork'), false);
      expect(setups.information[setupId!]!.containsKey('fork'), false);
      expect(setups.information[setupId!]!.containsKey('shock'), false);
      expect(config.fields.containsKey('Shock'), false);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      deps.dispose();
    });
  }
}
