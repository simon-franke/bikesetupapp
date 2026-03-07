import 'package:bikesetupapp/database_service/database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SettingsAlerts {

  static Future<void> editValue(BuildContext context, User user, String key,
      String value, String bikeName, String category, String setup) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).cardTheme.color,
          title: Text(
            key,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          content: TextFormField(
            cursorColor: Theme.of(context).textTheme.labelMedium!.color,
            autofocus: true,
            style: Theme.of(context).textTheme.titleMedium,
            initialValue: value,
            decoration: InputDecoration(
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                    width: 2,
                    color: Theme.of(context).textTheme.labelMedium!.color!),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(
                    width: 2,
                    color: Theme.of(context).textTheme.labelMedium!.color!),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: (val) {
              value = val;
            },
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
                  Navigator.of(context).pop();
                },
                child: Text(
                  'Cancel',
                  style: Theme.of(context).textTheme.labelLarge,
                )),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    Theme.of(context).floatingActionButtonTheme.backgroundColor,
              ),
              child: Text(
                'Enter',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              onPressed: () {
                if (key == "Pressure" &&
                    value.trim().replaceAll(',', '').length > 3) {
                  generalError(context, 'Pressure must be 3 digits or less');
                  return;
                } else {
                  Navigator.of(context).pop();
                  try {
                    DatabaseService(user.uid).editSetting(
                      key.trim(), value.trim(), bikeName, category, setup);
                  } catch (e) {
                    generalError(context, 'Error creating setting');
                  }
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
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).cardTheme.color,
          title: Text(
            'Delete Category',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          content: Text(
            'Are you sure you want to delete this category?',
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
                  Navigator.of(context).pop();
                },
                child: Text('Cancel',
                    style: Theme.of(context).textTheme.labelLarge)),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    Theme.of(context).floatingActionButtonTheme.backgroundColor,
              ),
              child: Text(
                'Delete',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              onPressed: () {
                Navigator.of(context).pop();
                try {
                  DatabaseService(user.uid)
                    .deleteSetting(key, bikeName, category, setup);
                } catch (e) {
                  generalError(context, 'Error deleting category');
                }
                
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
