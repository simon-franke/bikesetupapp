import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../features/settings/controllers/app_state_notifier.dart';
import '../firebase_options.dart';
import 'app.dart';
import 'app_dependencies.dart';

/// Initializes Firebase and loads the saved theme before mounting the app.
///
/// Startup failures propagate; the app is not mounted with partial initialization.
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final dependencies = AppDependencies.instance;
  final savedTheme = await dependencies.themePreferences.readTheme();

  runApp(Provider<AppDependencies>.value(
      value: dependencies,
      child: ChangeNotifierProvider<AppStateNotifier>(
          create: (context) => AppStateNotifier(
              AppStateNotifier.fromSaved(savedTheme),
              preferences: dependencies.themePreferences),
          child: const MyApp())));
}
