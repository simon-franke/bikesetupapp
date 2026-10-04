import 'package:bikesetupapp/app/app_dependencies.dart';
import 'package:bikesetupapp/common/ui/dialog_helpers.dart';
import 'package:bikesetupapp/features/workspace/ui/home_page.dart';
import 'package:bikesetupapp/app/routing/app_routes.dart';
import 'package:bikesetupapp/features/bikes/models/new_bike_mode.dart';
import 'package:bikesetupapp/features/bikes/ui/new_bike_bottom_sheet.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthAlerts {
  static Future<void> handleAuthentication(
      UserCredential userCredential, BuildContext context) async {
    User? user = AppDependencies.of(context).auth.currentUser;

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
    final selection = await AppDependencies.of(context)
        .forUser(user.uid)
        .startup
        .loadSelection();
    if (selection == null) {
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
    if (!context.mounted) return;
    Navigator.of(context).push(AppRoutes.fadeSlide(MyHomePage(
      user: user,
      bikeName: selection.bikeName,
      uBikeID: selection.bikeId,
      bikeType: selection.bikeType,
      setupName: selection.setupName,
      uSetupID: selection.setupId,
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
