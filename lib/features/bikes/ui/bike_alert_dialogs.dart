import 'package:bikesetupapp/common/ui/command_feedback.dart';
import 'package:bikesetupapp/app/app_dependencies.dart';
import 'package:bikesetupapp/common/ui/dialog_helpers.dart';
import 'package:flutter/material.dart';

class BikeAlerts {
  static Future<void> renameBike(
      BuildContext context, String uBikeID, String bikeNameOld) async {
    final controller = TextEditingController(text: bikeNameOld);
    var saving = false;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(builder: (ctx, update) {
        return WorkshopDialog(
          title: 'Rename bike',
          content:
              DialogTextField(controller: controller, hint: 'Enter new name'),
          actions: [
            DialogSecondaryButton(
              label: 'Cancel',
              onPressed: () => Navigator.of(ctx).pop(),
            ),
            DialogPrimaryButton(
              label: 'Save',
              onPressed: saving
                  ? null
                  : () async {
                      update(() => saving = true);
                      final saved = await presentCommand(
                          ctx,
                          () => AppDependencies.of(context)
                              .forUser(AppDependencies.of(context)
                                  .auth
                                  .currentUser!
                                  .uid)
                              .bikes
                              .renameBike(uBikeID, controller.text));
                      if (!ctx.mounted) return;
                      if (saved) {
                        Navigator.of(ctx).pop();
                      } else {
                        update(() => saving = false);
                      }
                    },
            ),
          ],
        );
      }),
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
