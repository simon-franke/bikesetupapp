import 'package:bikesetupapp/common/models/command_result.dart';
import 'dart:async';
import 'package:bikesetupapp/app/app_dependencies.dart';
import 'package:bikesetupapp/common/theme/theme_data.dart';
import 'package:bikesetupapp/features/maintenance/models/component_type.dart';
import 'package:bikesetupapp/features/maintenance/models/service_component.dart';
import 'package:bikesetupapp/features/maintenance/models/service_entry.dart';
import 'package:bikesetupapp/features/maintenance/repositories/maintenance_repository.dart';
import 'package:bikesetupapp/features/maintenance/ui/log_service_sheet.dart';
import 'package:bikesetupapp/features/maintenance/ui/defer_service_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

class SaveRepository extends Fake implements MaintenanceRepository {
  Completer<void> result = Completer<void>();
  final List<ServiceEntry> entries = [];
  @override
  Future<void> addServiceEntry(String componentId, ServiceEntry entry) {
    entries.add(entry);
    return result.future;
  }
}

void main() {
  for (final defer in [false, true]) {
    testWidgets(
        '${defer ? 'defer' : 'log'} waits for persistence and retains form on failure',
        (tester) async {
      final repository = SaveRepository();
      final dependencies =
          AppDependencies(maintenanceRepository: (_) => repository);
      final component = ServiceComponent(
          id: 'component',
          bikeId: 'bike',
          type: ComponentType.values.first,
          name: 'Chain',
          serviceIntervalKm: 1000,
          createdAt: DateTime.utc(2026, 1, 1));
      await tester.pumpWidget(Provider<AppDependencies>.value(
          value: dependencies,
          child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: Scaffold(
                  body: Builder(
                builder: (context) => TextButton(
                    onPressed: () {
                      if (defer) {
                        showDeferServiceSheet(
                            context: context,
                            userID: 'user',
                            component: component,
                            currentMileageKm: 1200);
                      } else {
                        showLogServiceSheet(
                            context: context,
                            userID: 'user',
                            component: component,
                            currentMileageKm: 1200);
                      }
                    },
                    child: const Text('Open')),
              )))));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      if (!defer) {
        await tester.enterText(find.byType(TextField), 'Keep this note');
      }
      final buttonLabel = defer ? 'Save' : 'Log service';
      await tester.tap(find.text(buttonLabel));
      await tester.pump();
      expect(find.text('Saving…'), findsOneWidget);
      expect(repository.entries, hasLength(1));
      await tester.tap(find.text('Saving…'));
      expect(repository.entries, hasLength(1));
      repository.result.completeError(const AppFailure(FailureCode.saveFailed));
      await tester.pumpAndSettle();
      expect(find.text('Could not save service. Try again.'), findsOneWidget);
      if (!defer) expect(find.text('Keep this note'), findsOneWidget);
      repository.result = Completer<void>();
      await tester.tap(find.text(buttonLabel));
      await tester.pump();
      expect(repository.entries, hasLength(2));
      if (!defer) expect(repository.entries.last.note, 'Keep this note');
      repository.result.complete();
      await tester.pumpAndSettle();
      expect(find.text(buttonLabel), findsNothing);
      expect(find.text('Open'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      dependencies.dispose();
    });
  }
}
