import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../common/layout/phone_viewport.dart';
import '../common/theme/theme_data.dart';
import '../features/auth/controllers/auth_controller.dart';
import '../features/auth/ui/session_landing.dart';
import '../features/settings/controllers/app_state_notifier.dart';
import 'app_dependencies.dart';

/// Configures the app theme and replaces navigation when the session changes.
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
