import 'package:bikesetupapp/common/ui/app_sheet.dart';
import 'package:bikesetupapp/common/ui/app_components.dart';
import 'package:bikesetupapp/common/ui/command_feedback.dart';
import 'package:bikesetupapp/app/app_dependencies.dart';
import 'package:bikesetupapp/common/ui/dialog_helpers.dart';
import 'package:flutter/material.dart';

class BikeAlerts {
  static Future<void> renameBike(
      BuildContext context, String uBikeID, String bikeNameOld) async {
    final controller = TextEditingController(text: bikeNameOld);
    var saving = false;
    ModalRoute<dynamic>? route;
    await showAppSheet<void>(
      context: context,
      builder: (ctx) {
        route = ModalRoute.of(ctx);
        return StatefulBuilder(builder: (ctx, update) {
          return SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                  24, 12, 24, 24 + MediaQuery.viewInsetsOf(ctx).bottom),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const AppSheetHandle(),
                  const SizedBox(height: 24),
                  Text('Rename bike',
                      style: Theme.of(ctx).textTheme.titleLarge),
                  const SizedBox(height: 20),
                  AppTextField(
                      controller: controller,
                      hint: 'Bike name',
                      autofocus: true),
                  const SizedBox(height: 24),
                  AppActionButton(
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
              ),
            ),
          );
        });
      },
    );
    await route?.completed;
    controller.dispose();
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
