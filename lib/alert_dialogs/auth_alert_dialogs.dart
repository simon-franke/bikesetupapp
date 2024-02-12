import 'package:bikesetupapp/app_pages/bike_selector_page.dart';
import 'package:bikesetupapp/app_pages/home_page.dart';
import 'package:bikesetupapp/bike_enums/biketype.dart';
import 'package:bikesetupapp/database_service/auth_service.dart';
import 'package:bikesetupapp/database_service/database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthAlerts {

  static void handleAuthentication(
      UserCredential userCredential, BuildContext context) async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null &&
        userCredential.additionalUserInfo != null &&
        userCredential.additionalUserInfo!.isNewUser) {
      if (!context.mounted) return;
      Navigator.of(context).push(MaterialPageRoute(
          builder: (BuildContext context) => BikeTypeSelector(
                user: user,
              )));
      return;
    }
    if (user == null) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: No User',
              style: Theme.of(context).textTheme.titleMedium)));
      return;
    }
    String defaultBikeUbid = await DatabaseService(user.uid).getDefaultBike();
    String defaultSetupUsid =
        await DatabaseService(user.uid).getDefaultSetup(defaultBikeUbid);
    BikeType biketype = BikeType.fromString(
        await DatabaseService(user.uid).getBikeType(defaultBikeUbid));
    if (defaultBikeUbid == "" ||
        defaultSetupUsid == "" ||
        biketype == BikeType.error) {
      if (!context.mounted) return;
      Navigator.of(context).push(MaterialPageRoute(
          builder: (BuildContext context) => BikeTypeSelector(
                user: user,
              )));
      return;
    }
    String defaultBikeName =
        await DatabaseService(user.uid).getBikeNameFromID(defaultBikeUbid);
    String defaultSetup = await DatabaseService(user.uid)
        .getSetupNameFromID(defaultBikeUbid, defaultSetupUsid);
    if (!context.mounted) return;
    Navigator.of(context).push(MaterialPageRoute(
        builder: (BuildContext context) => MyHomePage(
              user: user,
              bikename: defaultBikeName,
              ubid: defaultBikeUbid,
              biketype: biketype,
              setupname: defaultSetup,
              usid: defaultSetupUsid,
            )));
  }

  static Future<bool?> signOutAnonymus(BuildContext context, User user) async {
    bool? result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).cardTheme.color,
          title: Text(
            'Signing Out',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          content: Text(
            'Are you sure you want to sign out of your anonymous account? \nThis may result in a loss of data.',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          actionsAlignment: MainAxisAlignment.spaceAround,
          actions: <Widget>[
            ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context)
                      .floatingActionButtonTheme
                      .backgroundColor,
                ),
                onPressed: () {
                  Navigator.of(context).pop(false);
                },
                child:
                    Text('No', style: Theme.of(context).textTheme.labelLarge)),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    Theme.of(context).floatingActionButtonTheme.backgroundColor,
              ),
              child: Text('Yes', style: Theme.of(context).textTheme.labelLarge),
              onPressed: () {
                AuthService().signOut();
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );
    return result;
  }

  static ScaffoldFeatureController<SnackBar, SnackBarClosedReason> generalError(
      BuildContext context, String message) {
    return ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
        message,
        style: Theme.of(context).textTheme.titleMedium,
      ),
    ));
  }
}
