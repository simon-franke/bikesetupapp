import 'package:bikesetupapp/common/ui/app_components.dart';
import 'package:bikesetupapp/common/ui/dialog_helpers.dart';
import 'package:bikesetupapp/app/routing/app_routes.dart';
import 'google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthAlerts {
  static Future<bool?> signOutAnonymous(BuildContext context, User user) async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return WorkshopDialog(
          title: 'Leave without saving?',
          content: const Text(
            'Your guest bikes cannot be recovered after you sign out. Save them to an account before leaving.',
          ),
          actions: [
            AppActionButton(
                label: 'Save to an account',
                onPressed: () {
                  Navigator.of(ctx).pop(false);
                  Navigator.of(context, rootNavigator: true).push(
                      AppRoutes.fadeSlide(const LoginPage(upgrade: true)));
                }),
            TextButton(
              child: const Text('Stay here'),
              onPressed: () => Navigator.of(ctx).pop(false),
            ),
            TextButton(
              child: const Text('Leave guest session'),
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
            AppActionButton(
              label: 'OK',
              onPressed: () => Navigator.of(ctx).pop(),
            ),
          ],
        );
      },
    );
  }
}
