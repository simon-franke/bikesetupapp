import 'package:bikesetupapp/alert_dialogs/dialog_helpers.dart';
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
      showNewBikeSheet(context, user, NewBikeMode.newBike,
          onBikeSelected: (bikeName, uBikeID, bikeType, setupName, uSetupID) {
        Navigator.of(context).push(AppRoutes.fadeSlide(MyHomePage(
          user: user,
          bikeName: bikeName,
          uBikeID: uBikeID,
          bikeType: bikeType,
          setupName: setupName,
          uSetupID: uSetupID,
        )));
      });
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
      showNewBikeSheet(context, user, NewBikeMode.newBike,
          onBikeSelected: (bikeName, uBikeID, bikeType, setupName, uSetupID) {
        Navigator.of(context).push(AppRoutes.fadeSlide(MyHomePage(
          user: user,
          bikeName: bikeName,
          uBikeID: uBikeID,
          bikeType: bikeType,
          setupName: setupName,
          uSetupID: uSetupID,
        )));
      });
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
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return WorkshopDialog(
          title: 'Sign out',
          content: const Text(
            'Are you sure you want to sign out of your anonymous account? This may result in a loss of data.',
          ),
          actions: [
            DialogSecondaryButton(
              label: 'No',
              onPressed: () => Navigator.of(ctx).pop(false),
            ),
            DialogPrimaryButton(
              label: 'Sign out',
              onPressed: () {
                AuthService().signOut();
                Navigator.of(ctx).pop(true);
              },
            ),
          ],
        );
      },
    );
  }

  static Future<void> generalError(BuildContext context, String message) {
    return showDialog<void>(
      context: context,
      builder: (ctx) {
        return WorkshopDialog(
          title: 'Error',
          content: Text(message),
          actions: [
            DialogPrimaryButton(
              label: 'OK',
              onPressed: () => Navigator.of(ctx).pop(),
            ),
          ],
        );
      },
    );
  }
}
