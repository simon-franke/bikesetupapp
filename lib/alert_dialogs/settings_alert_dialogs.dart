import 'package:bikesetupapp/alert_dialogs/dialog_helpers.dart';
import 'package:bikesetupapp/database_service/database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SettingsAlerts {
  static Future<void> editValue(BuildContext context, User user, String key,
      String value, String bikeName, String category, String setup) async {
    final controller = TextEditingController(text: value);
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return WorkshopDialog(
          title: key,
          content: DialogTextField(controller: controller, hint: 'Enter value'),
          actions: [
            DialogSecondaryButton(
              label: 'Cancel',
              onPressed: () => Navigator.of(ctx).pop(),
            ),
            DialogPrimaryButton(
              label: 'Save',
              onPressed: () {
                final newValue = controller.text;
                if (key == 'Pressure' &&
                    newValue.trim().replaceAll(',', '').length > 3) {
                  generalError(context, 'Pressure must be 3 digits or less');
                  return;
                }
                Navigator.of(ctx).pop();
                try {
                  DatabaseService(user.uid).editSetting(
                      key.trim(), newValue.trim(), bikeName, category, setup);
                } catch (_) {
                  generalError(context, 'Error creating setting');
                }
              },
            ),
          ],
        );
      },
    );
  }

  static Future<void> deleteCategory(BuildContext context, User user,
      String key, String bikeName, String category, String setup) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return WorkshopDialog(
          title: 'Delete category',
          content: const Text('Are you sure you want to delete this category?'),
          actions: [
            DialogSecondaryButton(
              label: 'Cancel',
              onPressed: () => Navigator.of(ctx).pop(),
            ),
            Builder(builder: (ctx2) {
              return DialogPrimaryButton(
                label: 'Delete',
                color: Theme.of(ctx2).colorScheme.error,
                onPressed: () {
                  Navigator.of(ctx).pop();
                  try {
                    DatabaseService(user.uid)
                        .deleteSetting(key, bikeName, category, setup);
                  } catch (_) {
                    generalError(context, 'Error deleting category');
                  }
                },
              );
            }),
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
