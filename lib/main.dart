import 'package:bikesetupapp/Services/database.dart';
import 'package:flutter/material.dart';
import 'package:bikesetupapp/Pages/home_page.dart';
import 'Pages/google_sign_in.dart';
import 'package:bikesetupapp/Services/themedata.dart';
import 'package:bikesetupapp/Services/app_state_notifier.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  bool isSignedIn = false;
  String defaultBike = "";

  User? user = FirebaseAuth.instance.currentUser;

  if (user != null) {
    isSignedIn = true;
    defaultBike = await DatabaseService(user.uid).getDefaultBike();
    //TODO check if defaultBike for faults
  }

  runApp(ChangeNotifierProvider<AppStateNotifier>(
      create: (context) => AppStateNotifier(),
      child: MyApp(
        isSignedIn: isSignedIn,
        user: FirebaseAuth.instance.currentUser,
        defaultBike: defaultBike,
      )));
}

class MyApp extends StatelessWidget {
  final bool isSignedIn;
  final User? user;
  final String defaultBike;
  const MyApp(
      {Key? key,
      required this.isSignedIn,
      required this.user,
      required this.defaultBike})
      : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Consumer<AppStateNotifier>(
      builder: (context, appState, child) {
        return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Bike Setup',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: appState.isDarkModeOn ? ThemeMode.dark : ThemeMode.light,
            home: isSignedIn
                ? MyHomePage(
                    user: user,
                    bikename: defaultBike,
                  )
                : const LoginPage());
      },
    );
  }
}
