import 'package:bikesetupapp/database_service/database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SettingsAlerts {

  static Future<void> newKey(BuildContext context, User user, String bikeName,
      String category, String setup) async {
    String key = "";
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).cardTheme.color,
          title: Text('New Category',
              style: Theme.of(context).textTheme.labelLarge),
          content: TextFormField(
            cursorColor: Theme.of(context).textTheme.labelMedium!.color,
            autofocus: true,
            decoration: InputDecoration(
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                    width: 2,
                    color: Theme.of(context).textTheme.labelMedium!.color!),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(
                    width: 2,
                    color: Theme.of(context).textTheme.labelMedium!.color!),
                borderRadius: BorderRadius.circular(10),
              ),
              hintStyle: Theme.of(context).textTheme.labelSmall,
              hintText: 'Category Name',
            ),
            onChanged: (value) {
              key = value;
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
                  style: Theme.of(context).textTheme.labelMedium,
                )),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    Theme.of(context).floatingActionButtonTheme.backgroundColor,
              ),
              child: Text(
                'Enter',
                style: Theme.of(context).textTheme.labelMedium,
              ),
              onPressed: () {
                if (key.trim().isEmpty) {
                  generalError(context, 'Please enter a name!');
                  return;
                } else {
                  Navigator.of(context).pop();
                  newValue(context, key, user, bikeName, category, setup);
                }
              },
            ),
          ],
        );
      },
    );
  }

  static Future<void> newValue(BuildContext context, String key, User user,
      String bikeName, String category, String setup) async {
    String value = "";
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).cardTheme.color,
          title: Text(key, style: Theme.of(context).textTheme.labelLarge),
          content: TextFormField(
            cursorColor: Theme.of(context).textTheme.labelMedium!.color,
            autofocus: true,
            decoration: InputDecoration(
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                    width: 2,
                    color: Theme.of(context).textTheme.labelMedium!.color!),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(
                    width: 2,
                    color: Theme.of(context).textTheme.labelMedium!.color!),
                borderRadius: BorderRadius.circular(10),
              ),
              hintStyle: Theme.of(context).textTheme.labelSmall,
              hintText: 'Value',
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
                child: Text('Cancel',
                    style: Theme.of(context).textTheme.labelLarge)),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    Theme.of(context).floatingActionButtonTheme.backgroundColor,
              ),
              child:
                  Text('Enter', style: Theme.of(context).textTheme.labelLarge),
              onPressed: () {
                Navigator.of(context).pop();
                try {
                  DatabaseService(user.uid)
                    .setSetting(key, value, bikeName, category, setup);
                } catch(e) {
                  generalError(context, 'Error creating setting');
                }
                
              },
            ),
          ],
        );
      },
    );
  }

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
            style: Theme.of(context).textTheme.titleMedium,
          ),
          content: TextFormField(
            cursorColor: Theme.of(context).textTheme.labelMedium!.color,
            autofocus: true,
            style: Theme.of(context).textTheme.titleMedium,
            initialValue: value,
            decoration: InputDecoration(
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                    width: 2,
                    color: Theme.of(context).textTheme.labelMedium!.color!),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(
                    width: 2,
                    color: Theme.of(context).textTheme.labelMedium!.color!),
                borderRadius: BorderRadius.circular(10),
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
            style: Theme.of(context).textTheme.labelLarge,
          ),
          content: Text(
            'Are you sure you want to delete this category?',
            style: Theme.of(context).textTheme.labelMedium,
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
                    style: Theme.of(context).textTheme.labelMedium)),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    Theme.of(context).floatingActionButtonTheme.backgroundColor,
              ),
              child: Text(
                'Delete',
                style: Theme.of(context).textTheme.labelMedium,
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
