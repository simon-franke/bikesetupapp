import 'dart:io';
// ignore: depend_on_referenced_packages
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:bikesetupapp/app/app_dependencies.dart';
import 'package:bikesetupapp/common/models/command_result.dart';
import 'package:bikesetupapp/common/theme/theme_data.dart';
import 'package:bikesetupapp/common/ui/app_error_banner.dart';
import 'package:bikesetupapp/features/maintenance/models/service_component.dart';
import 'package:bikesetupapp/features/maintenance/models/service_entry.dart';
import 'package:bikesetupapp/features/maintenance/repositories/maintenance_repository.dart';
import 'package:bikesetupapp/features/maintenance/ui/add_component_flow.dart';
import 'package:bikesetupapp/features/maintenance/ui/service_components_list.dart';

class _PreviewPaths extends PathProviderPlatform {
  _PreviewPaths(this.path);
  final String path;
  @override
  Future<String> getApplicationSupportPath() async => path;
}

class _Repository extends Fake implements MaintenanceRepository {
  bool failLoads = false;
  int saves = 0, loads = 0;
  @override
  Future<void> createComponentWithBaseline(
      ServiceComponent component, ServiceEntry baseline) async {
    saves++;
    throw const AppFailure(FailureCode.saveFailed);
  }

  @override
  Stream<List<ServiceComponent>> getComponentsForBike(String bikeId) {
    loads++;
    if (!failLoads) return Stream.value([]);
    return Stream.error(const AppFailure(FailureCode.loadFailed));
  }
}

const _screen = ValueKey('error-preview');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    // Optional local fonts and output directory make review captures reproducible
    // without adding machine-specific assets or golden files to ordinary tests.
    final fontDir = Platform.environment['ERROR_PREVIEW_FONT_DIR'];
    if (fontDir == null) return;
    PathProviderPlatform.instance = _PreviewPaths(fontDir);
    for (final file in Directory(fontDir).listSync().whereType<File>()) {
      final name = file.uri.pathSegments.last;
      if (!name.startsWith('Inter_') || !name.endsWith('.ttf')) continue;
      final parts = name.split('_');
      await (FontLoader('${parts[0]}_${parts[1]}')
            ..addFont(
                Future.value(ByteData.sublistView(file.readAsBytesSync()))))
          .load();
    }
    await (FontLoader('MaterialIcons')
          ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
        .load();
    await (FontLoader('packages/cupertino_icons/CupertinoIcons')
          ..addFont(rootBundle
              .load('packages/cupertino_icons/assets/CupertinoIcons.ttf')))
        .load();
  });

  Future<void> capture(WidgetTester tester, String name) async {
    final directory = Platform.environment['ERROR_PREVIEW_OUTPUT'];
    if (directory != null) {
      await expectLater(find.byKey(_screen),
          matchesGoldenFile(Uri.file('$directory/$name.png')));
    }
  }

  Future<void> mount(WidgetTester tester, _Repository repo, Widget page) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final deps = AppDependencies(maintenanceRepository: (_) => repo);
    addTearDown(deps.dispose);
    await tester.pumpWidget(Provider.value(
        value: deps,
        child: MaterialApp(
            theme: AppTheme.darkTheme,
            builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                    padding: const EdgeInsets.only(top: 44, bottom: 24)),
                child: RepaintBoundary(key: _screen, child: child!)),
            home: page)));
    await tester.pumpAndSettle();
  }

  testWidgets('field validation stays by its input and clears after correction',
      (tester) async {
    final repo = _Repository();
    await mount(
        tester,
        repo,
        const AddServiceComponentFlow(
            uid: 'user', bikeId: 'bike', currentMileageKm: null));
    await tester.tap(find.text('Chain'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add component'));
    await tester.pumpAndSettle();
    expect(find.text('Enter the distance between services.'), findsOneWidget);
    expect(find.byType(AppErrorBanner), findsNothing);
    expect(repo.saves, 0);
    await capture(tester, '01-field-validation');
    await tester.enterText(
        find.byKey(const ValueKey('service-interval')), '1000');
    await tester.pumpAndSettle();
    expect(find.text('Enter the distance between services.'), findsNothing);
  });

  testWidgets(
      'save banner preserves inputs, persists and retries without a toast',
      (tester) async {
    final repo = _Repository();
    await mount(
        tester,
        repo,
        const AddServiceComponentFlow(
            uid: 'user', bikeId: 'bike', currentMileageKm: null));
    await tester.tap(find.text('Chain'));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const ValueKey('service-interval')), '1000');
    await tester.tap(find.text('Add component'));
    await tester.pumpAndSettle();
    expect(find.byType(AppErrorBanner), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);
    expect(find.text('1000'), findsOneWidget);
    await tester.pump(const Duration(seconds: 10));
    expect(find.byType(AppErrorBanner), findsOneWidget);
    await capture(tester, '02-save-error');
    await tester.tap(find.text('Add component'));
    await tester.pumpAndSettle();
    expect(repo.saves, 2);
    await tester.tap(find.byTooltip('Dismiss error'));
    await tester.pumpAndSettle();
    expect(find.byType(AppErrorBanner), findsNothing);
  });

  testWidgets('section load error offers a working retry', (tester) async {
    final repo = _Repository()..failLoads = true;
    await mount(
        tester,
        repo,
        Scaffold(
            body: SafeArea(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
              const Padding(
                  padding: EdgeInsets.fromLTRB(20, 24, 20, 4),
                  child: Text('Service', style: AppTextStyles.body)),
              Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  child: Text('My bike', style: AppTextStyles.heading)),
              const ServiceComponentsList(
                  userID: 'user',
                  bikeId: 'bike',
                  currentMileageKm: 0,
                  mileageAvailable: false),
            ]))));
    expect(find.text('Your components couldn’t load. Give it another try.'),
        findsOneWidget);
    await capture(tester, '03-loading-error');
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(repo.loads, 2);
  });
}
