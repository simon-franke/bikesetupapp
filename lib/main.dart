import 'package:bikesetupapp/common/layout/phone_viewport.dart';
import 'package:bikesetupapp/app/app_dependencies.dart';
import 'package:bikesetupapp/features/auth/ui/session_landing.dart';
import 'package:bikesetupapp/features/auth/controllers/auth_controller.dart';
import 'package:bikesetupapp/common/theme/theme_data.dart';
import 'package:bikesetupapp/features/settings/controllers/app_state_notifier.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final dependencies = AppDependencies.instance;
  final savedTheme = await dependencies.themePreferences.readTheme();

  runApp(Provider<AppDependencies>.value(
      value: AppDependencies.instance,
      child: ChangeNotifierProvider<AppStateNotifier>(
          create: (context) => AppStateNotifier(
              AppStateNotifier.fromSaved(savedTheme),
              preferences: dependencies.themePreferences),
          child: const MyApp())));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final AuthController auth = AppDependencies.of(context).auth;
  GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  String? _session;
  bool _deleteAccount = Uri.base.queryParameters['action'] == 'delete-account';

  String get session =>
      '${auth.currentUser?.uid}/${auth.currentUser?.isAnonymous}';

  @override
  void initState() {
    super.initState();
    _session = session;
    auth.addListener(_changed);
  }

  void _changed() {
    if (session == _session || !mounted) return;
    setState(() {
      if (auth.currentUser == null) _deleteAccount = false;
      _session = session;
      // Replace every route, including root sheets and workspace navigators.
      _navigatorKey = GlobalKey<NavigatorState>();
    });
  }

  @override
  void dispose() {
    auth.removeListener(_changed);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Consumer<AppStateNotifier>(
        builder: (context, appState, child) => MaterialApp(
          navigatorKey: _navigatorKey,
          debugShowCheckedModeBanner: false,
          builder: (context, child) => PhoneViewport(child: child!),
          title: 'Clickwise',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: appState.themeMode,
          themeAnimationDuration: const Duration(milliseconds: 240),
          themeAnimationCurve: Curves.easeOutCubic,
          home: SessionLanding(
              key: ValueKey(_session),
              user: auth.currentUser,
              deleteAccount: _deleteAccount,
              onCancelDeletion: () => setState(() => _deleteAccount = false)),
        ),
      );
}
