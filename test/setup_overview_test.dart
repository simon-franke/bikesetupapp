import 'package:bikesetupapp/app/app_dependencies.dart';
import 'package:bikesetupapp/common/theme/theme_data.dart';
import 'package:bikesetupapp/features/setups/ui/setup_overview.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'support/fake_repositories.dart';

class OverviewUser extends Fake implements User {
  @override
  String get uid => 'user';
}

void main() {
  testWidgets('summary cards navigate from values and padding', (tester) async {
    GoogleFonts.config.allowRuntimeFetching = false;
    final repository = FakeSetupsRepository()
      ..settings.addAll({
        'bike/setup/FrontTire/Pressure': '27 psi',
        'bike/setup/RearTire/Pressure': '38 psi',
        'bike/setup/Fork/Pressure': '92 psi',
        'bike/setup/Fork/Low Speed Compression': '4 clicks',
        'bike/setup/Fork/High Speed Rebound': '1 clicks',
      });
    final opened = <String>[];
    await tester.pumpWidget(Provider.value(
      value: AppDependencies(setupsRepository: (_) => repository),
      child: MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(
            body: SetupOverview(
          user: OverviewUser(),
          bike: 'bike',
          setup: 'setup',
          onCategory: opened.add,
        )),
      ),
    ));
    await tester.pumpAndSettle();
    for (final text in ['27 psi', '38 psi']) {
      await tester.tap(find.text(text, findRichText: true));
      await tester.pumpAndSettle();
    }
    final tires = tester.getRect(find.byType(SetupCard).first);
    await tester.tapAt(tires.topLeft + const Offset(8, 8));
    await tester.pumpAndSettle();
    await tester.tap(find.text('92 psi', findRichText: true));
    await tester.pumpAndSettle();
    expect(opened, ['Tires', 'Tires', 'Tires', 'Fork']);
    expect(find.byType(BottomSheet), findsNothing);
    expect(find.textContaining('LSC', findRichText: true), findsNothing);
    expect(find.textContaining('HSR', findRichText: true), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
