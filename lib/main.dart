import 'package:bikesetupapp/app_pages/home_page.dart';
import 'package:bikesetupapp/app_pages/google_sign_in.dart';
import 'package:bikesetupapp/app_services/theme_data.dart';
import 'package:bikesetupapp/app_services/app_state_notifier.dart';
import 'package:bikesetupapp/bike_enums/bike_type.dart';
import 'package:bikesetupapp/database_service/database.dart';

import 'package:flutter/material.dart';
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
  String defaultBikeID = "";
  String defaultBikeName = "";
  String defaultSetupID = "";
  String defaultSetupName = "";
  BikeType bikeType = BikeType.error;

  User? user = FirebaseAuth.instance.currentUser;

  if (user != null) {
    defaultBikeID = await DatabaseService(user.uid).getDefaultBike();
    defaultBikeName =
        await DatabaseService(user.uid).getBikeNameFromID(defaultBikeID);
    defaultSetupID =
        await DatabaseService(user.uid).getDefaultSetup(defaultBikeID);
    defaultSetupName = await DatabaseService(user.uid)
        .getSetupNameFromID(defaultBikeID, defaultSetupID);
    bikeType = BikeType.fromString(
        await DatabaseService(user.uid).getBikeType(defaultBikeID));

    if (defaultSetupID.isNotEmpty &&
        defaultSetupName.isNotEmpty &&
        bikeType != BikeType.error) {
      isSignedIn = true;
    }
  }

  WidgetsFlutterBinding.ensureInitialized();
  SharedPreferences prefs = await SharedPreferences.getInstance();

  runApp(ChangeNotifierProvider<AppStateNotifier>(
      create: (context) =>
          AppStateNotifier(prefs.getBool('isDarkModeOn') ?? false),
      child: MyApp(
        isSignedIn: isSignedIn,
        user: FirebaseAuth.instance.currentUser,
        defaultBikeID: defaultBikeID,
        defaultBike: defaultBikeName,
        defaultSetupID: defaultSetupID,
        defaultSetup: defaultSetupName,
        bikeType: bikeType,
      )));
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
            themeMode: appState.isDarkModeOn ? ThemeMode.dark : ThemeMode.light,
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
