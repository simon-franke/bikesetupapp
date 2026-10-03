import 'package:bikesetupapp/app/app_dependencies.dart';
import 'package:bikesetupapp/features/workspace/ui/home_page.dart';
import 'package:bikesetupapp/features/auth/ui/google_sign_in.dart';
import 'package:bikesetupapp/common/theme/theme_data.dart';
import 'package:bikesetupapp/features/settings/controllers/app_state_notifier.dart';
import 'package:bikesetupapp/features/bikes/models/bike_type.dart';
import 'package:bikesetupapp/features/strava/platform/strava_web_callback_stub.dart'
    if (dart.library.js_interop) 'package:bikesetupapp/features/strava/platform/strava_web_callback.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env").catchError((_) {});
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // On web: check if we landed here via the Strava OAuth redirect. If so,
  // save the tokens from the URL and strip the param from the address bar.
  // This must run before the auth state check below so the Settings page
  // immediately reflects the new connection on first render.
  final bool newStravaAuth = await handleStravaWebCallback();

  final dependencies = AppDependencies.instance;
  final user = dependencies.auth.currentUser;
  final selection = user == null
      ? null
      : await dependencies.forUser(user.uid).startup.loadSelection();
  if (newStravaAuth && user != null) {
    await dependencies.forUser(user.uid).strava.sync();
  }

  final savedTheme = await dependencies.themePreferences.readTheme();

  runApp(Provider<AppDependencies>.value(
      value: AppDependencies.instance,
      child: ChangeNotifierProvider<AppStateNotifier>(
          create: (context) => AppStateNotifier(
              AppStateNotifier.fromSaved(savedTheme),
              preferences: dependencies.themePreferences),
          child: MyApp(
            isSignedIn: selection != null,
            user: AppDependencies.instance.auth.currentUser,
            defaultBikeID: selection?.bikeId ?? '',
            defaultBike: selection?.bikeName ?? '',
            defaultSetupID: selection?.setupId ?? '',
            defaultSetup: selection?.setupName ?? '',
            bikeType: selection?.bikeType ?? BikeType.error,
          ))));
}

class MyApp extends StatelessWidget {
  final bool isSignedIn;
  final User? user;
  final String defaultBikeID;
  final String defaultBike;
  final String defaultSetupID;
  final String defaultSetup;
  final BikeType bikeType;
  const MyApp(
      {super.key,
      required this.isSignedIn,
      required this.user,
      required this.defaultBikeID,
      required this.defaultBike,
      required this.defaultSetupID,
      required this.defaultSetup,
      required this.bikeType});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppStateNotifier>(
      builder: (context, appState, child) {
        return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: "Bike Setup",
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: appState.themeMode,
            themeAnimationDuration: const Duration(milliseconds: 240),
            themeAnimationCurve: Curves.easeOutCubic,
            home: isSignedIn
                ? MyHomePage(
                    user: user,
                    bikeName: defaultBike,
                    uBikeID: defaultBikeID,
                    bikeType: bikeType,
                    setupName: defaultSetup,
                    uSetupID: defaultSetupID,
                  )
                : const LoginPage());
      },
    );
  }
}
