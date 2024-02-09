import 'package:bikesetupapp/app_pages/home_page.dart';
import 'package:bikesetupapp/app_pages/google_sign_in.dart';
import 'package:bikesetupapp/app_services/themedata.dart';
import 'package:bikesetupapp/app_services/app_state_notifier.dart';
import 'package:bikesetupapp/bike_enums/biketype.dart';
import 'package:bikesetupapp/database_service/database.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  bool isSignedIn = false;
  String defaultBikebuid = "";
  String defaultBike = "";
  String defaultSetupusid = "";
  String defaultSetup = "";
  BikeType biketype = BikeType.error;

  User? user = FirebaseAuth.instance.currentUser;

  if (user != null) {
    isSignedIn = true;
    defaultBikebuid = await DatabaseService(user.uid).getDefaultBike();
    biketype = BikeType.fromString(
        await DatabaseService(user.uid).getBikeType(defaultBikebuid));
    defaultBike = await DatabaseService(user.uid).getBikeNameFromID(defaultBikebuid);
    defaultSetupusid = await DatabaseService(user.uid).getDefaultSetup(defaultBikebuid);
    defaultSetup = await DatabaseService(user.uid).getSetupNameFromID(defaultBikebuid, defaultSetupusid);

    if (defaultBikebuid == "" || biketype == BikeType.error || defaultBike == "") {
      isSignedIn = false;
    }
  }

  WidgetsFlutterBinding.ensureInitialized();
  SharedPreferences prefs = await SharedPreferences.getInstance();

  runApp(ChangeNotifierProvider<AppStateNotifier>(
      create: (context) => AppStateNotifier(prefs.getBool('isDarkModeOn') ?? false),
      child: MyApp(
        isSignedIn: isSignedIn,
        user: FirebaseAuth.instance.currentUser,
        defaultBikebuid: defaultBikebuid,
        defaultBike: defaultBike,
        defaultSetupusid: defaultSetupusid,
        defaultSetup: defaultSetup,
        biketype: biketype,
      )));
}

class MyApp extends StatelessWidget {
  final bool isSignedIn;
  final User? user;
  final String defaultBikebuid;
  final String defaultBike;
  final String defaultSetupusid;
  final String defaultSetup;
  final BikeType biketype;
  const MyApp(
      {Key? key,
      required this.isSignedIn,
      required this.user,
      required this.defaultBikebuid,
      required this.defaultBike,
      required this.defaultSetupusid,
      required this.defaultSetup,
      required this.biketype})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AppStateNotifier>(
      builder: (context, appState, child) {
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
        ]);
        return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: "Bike Setup",
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: appState.isDarkModeOn ? ThemeMode.dark : ThemeMode.light,
            home: isSignedIn
                ? MyHomePage(
                    user: user,
                    bikename: defaultBike,
                    ubid: defaultBikebuid,
                    biketype: biketype,
                    chosensetup: defaultSetup,
                    usid: defaultSetupusid,
                  )
                : const LoginPage());
      },
    );
  }
}
