import 'package:bikesetupapp/alert_dialogs/dialog_helpers.dart';
import 'package:bikesetupapp/app_services/theme_data.dart';
import 'package:bikesetupapp/database_service/database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class BikeAlerts {
  static Future<void> deleteBike(
      BuildContext context, User user, String uBikeID) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return WorkshopDialog(
          title: 'Delete bike',
          content: const Text('Are you sure you want to delete this bike?'),
          actions: [
            DialogSecondaryButton(
              label: 'Cancel',
              onPressed: () => Navigator.of(ctx).pop(),
            ),
            DialogPrimaryButton(
              label: 'Delete',
              color: ctx.palette.red,
              onPressed: () {
                Navigator.of(ctx).pop();
                try {
                  DatabaseService(user.uid).deleteBike(uBikeID);
                } catch (_) {
                  generalError(context, 'Error deleting bike');
                }
              },
            ),
          ],
        );
      },
    );
  }

  static Future<void> deleteSetup(
      BuildContext context, User user, String uBikeID, String uSetupID) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return WorkshopDialog(
          title: 'Delete setup',
          content: const Text('Are you sure you want to delete this setup?'),
          actions: [
            DialogSecondaryButton(
              label: 'Cancel',
              onPressed: () => Navigator.of(ctx).pop(),
            ),
            DialogPrimaryButton(
              label: 'Delete',
              color: ctx.palette.red,
              onPressed: () {
                Navigator.of(ctx).pop();
                try {
                  DatabaseService(user.uid).deleteSetup(uBikeID, uSetupID);
                } catch (_) {
                  generalError(context, 'Error deleting setup');
                }
              },
            ),
          ],
        );
      },
    );
  }

  static Future<void> renameBike(
      BuildContext context, String uBikeID, String bikeNameOld) async {
    final controller = TextEditingController(text: bikeNameOld);
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return WorkshopDialog(
          title: 'Rename bike',
          content: DialogTextField(controller: controller, hint: 'Enter new name'),
          actions: [
            DialogSecondaryButton(
              label: 'Cancel',
              onPressed: () => Navigator.of(ctx).pop(),
            ),
            DialogPrimaryButton(
              label: 'Save',
              onPressed: () {
                Navigator.of(ctx).pop();
                try {
                  DatabaseService(FirebaseAuth.instance.currentUser!.uid)
                      .renameBike(uBikeID, controller.text);
                } catch (_) {
                  generalError(context, 'Error renaming bike');
                }
              },
            ),
          ],
        );
      },
    );
  }

  static Future<void> deleteError(BuildContext context, String type) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return WorkshopDialog(
          title: 'Cannot delete',
          content: Text('You must have at least one $type.'),
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
