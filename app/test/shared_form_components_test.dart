import 'dart:io';
import 'package:bikesetupapp/common/theme/theme_data.dart';
import 'package:bikesetupapp/common/ui/app_components.dart';
import 'package:bikesetupapp/common/ui/app_loading.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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

  for (final variant in ['primary', 'outlined', 'destructive']) {
    testWidgets('$variant action blocks duplicate submission while loading',
        (tester) async {
      var calls = 0;
      Widget screen(bool loading) => MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
                body: AppActionButton(
              label: 'Save',
              isLoading: loading,
              outlined: variant == 'outlined',
              destructive: variant == 'destructive',
              onPressed: () => calls++,
            )),
          );
      await tester.pumpWidget(screen(true));
      await tester.tap(find.text('Saving…'));
      await tester.pump(const Duration(milliseconds: 200));
      expect(calls, 0);
      expect(find.byType(AppLoadingIndicator), findsOneWidget);
      await tester.pumpWidget(screen(false));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(calls, 1);
    });
  }

  testWidgets(
      'shared password field retains autofill, masking and disabled state',
      (tester) async {
    final password = TextEditingController(text: 'secret');
    addTearDown(password.dispose);
    await tester.pumpWidget(MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
            body: AppFormField(
          label: 'Password',
          child: AppTextField(
              controller: password,
              enabled: false,
              obscureText: true,
              autocorrect: false,
              autofillHints: const [AutofillHints.password]),
        ))));
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.enabled, false);
    expect(field.obscureText, true);
    expect(field.autocorrect, false);
    expect(field.autofillHints, [AutofillHints.password]);
    expect(password.text, 'secret');
  });

  testWidgets('detail header respects explicit cancellation and busy state',
      (tester) async {
    var cancelled = 0;
    Widget screen(bool busy) => MaterialApp(
        theme: AppTheme.lightTheme,
        home: Builder(
            builder: (context) => Scaffold(
                  appBar: buildDetailAppBar(context,
                      title: 'Delete account',
                      backEnabled: !busy,
                      onBack: () => cancelled++),
                )));
    await tester.pumpWidget(screen(true));
    await tester.tap(find.byTooltip('Back'));
    expect(cancelled, 0);
    await tester.pumpWidget(screen(false));
    await tester.tap(find.byTooltip('Back'));
    expect(cancelled, 1);
  });

  for (final dark in [false, true]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('form feedback fits dark=$dark scale=$scale', (tester) async {
        tester.view.physicalSize = const Size(320, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final note = TextEditingController(text: 'Fork service');
        addTearDown(note.dispose);
        await tester.pumpWidget(MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: dark ? AppTheme.darkTheme : AppTheme.lightTheme,
          home: MediaQuery(
            data: MediaQueryData(
                textScaler: TextScaler.linear(scale), disableAnimations: true),
            child: RepaintBoundary(
                key: const ValueKey('form-review'),
                child: Scaffold(
                  body: ListView(padding: const EdgeInsets.all(20), children: [
                    const AppSectionLabel('Service details'),
                    AppFormField(
                        label: 'Note (optional)',
                        child: AppTextField(
                            controller: note,
                            hint: 'What was done?',
                            maxLines: 3)),
                    const SizedBox(height: 24),
                    AppFormFooter(
                        label: 'Log service',
                        error: 'Could not save service. Try again.',
                        onPressed: () {}),
                    const SizedBox(height: 24),
                    AppActionButton(
                        label: 'Save', isLoading: true, onPressed: () {}),
                    const SizedBox(height: 16),
                    AppActionButton(
                        label: 'Delete account',
                        destructive: true,
                        isLoading: true,
                        loadingLabel: 'Deleting account…',
                        onPressed: () {}),
                  ]),
                )),
          ),
        ));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final output = Platform.environment['FORM_REVIEW_OUTPUT'];
        if (output != null) {
          await expectLater(find.byKey(const ValueKey('form-review')),
              matchesGoldenFile(Uri.file('$output/form-$dark-$scale.png')));
        }
      });
    }
  }
}
