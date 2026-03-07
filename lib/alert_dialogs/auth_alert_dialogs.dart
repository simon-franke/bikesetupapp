import 'package:bikesetupapp/app_pages/home_page.dart';
import 'package:bikesetupapp/app_services/app_routes.dart';
import 'package:bikesetupapp/bike_enums/bike_type.dart';
import 'package:bikesetupapp/bike_enums/new_bike_mode.dart';
import 'package:bikesetupapp/database_service/auth_service.dart';
import 'package:bikesetupapp/database_service/database.dart';
import 'package:bikesetupapp/widgets/new_bike_bottom_sheet.dart';
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
      showNewBikeSheet(context, user, NewBikeMode.newBike);
      return;
    }
    if (user == null) {
      if (!context.mounted) return;
      generalError(context, 'Error: No User');
      return;
    }
    String defaultBikeID = await DatabaseService(user.uid).getDefaultBike();
    String defaultSetupID =
        await DatabaseService(user.uid).getDefaultSetup(defaultBikeID);
    BikeType bikeType = BikeType.fromString(
        await DatabaseService(user.uid).getBikeType(defaultBikeID));
    if (defaultBikeID.isEmpty ||
        defaultSetupID.isEmpty ||
        bikeType == BikeType.error) {
      if (!context.mounted) return;
      showNewBikeSheet(context, user, NewBikeMode.newBike);
      return;
    }
    String defaultBikeName =
        await DatabaseService(user.uid).getBikeNameFromID(defaultBikeID);
    String defaultSetup = await DatabaseService(user.uid)
        .getSetupNameFromID(defaultBikeID, defaultSetupID);
    if (!context.mounted) return;
    Navigator.of(context).push(AppRoutes.fadeSlide(MyHomePage(
          user: user,
          bikeName: defaultBikeName,
          uBikeID: defaultBikeID,
          bikeType: bikeType,
          setupName: defaultSetup,
          uSetupID: defaultSetupID,
        )));
  }

  static Future<bool?> signOutAnonymous(BuildContext context, User user) async {
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

  static Future<void> generalError(BuildContext context, String message) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).cardTheme.color,
          title: Text('Error', style: Theme.of(context).textTheme.titleLarge),
          content: Text(message, style: Theme.of(context).textTheme.titleMedium),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).floatingActionButtonTheme.backgroundColor,
              ),
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK', style: Theme.of(context).textTheme.labelLarge),
            ),
          ],
        );
      },
    );
  }
}
