import 'package:bikesetupapp/bike_enums/bike_type.dart';
import 'package:bikesetupapp/database_service/database.dart';
import 'package:bikesetupapp/widgets/default_bike_selector_widget.dart';
import 'package:bikesetupapp/widgets/setup_information_alert_content.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BikeAlerts {
  static Future<void> deleteBike(
      BuildContext context, User user, String uBikeID) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).cardTheme.color,
          title: Text(
            'Deleting Bike',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          content: Text(
            'Are you sure you want to delete this Bike?',
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
              child:
                  Text('Delete', style: Theme.of(context).textTheme.labelLarge),
              onPressed: () {
                Navigator.of(context).pop();
                try {
                  DatabaseService(user.uid).deleteBike(uBikeID);
                } catch (e) {
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
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).cardTheme.color,
          title: Text(
            'Deleting Setup',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          content: Text(
            'Are you sure you want to delete this Setup?',
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
              child:
                  Text('Delete', style: Theme.of(context).textTheme.labelLarge),
              onPressed: () {
                Navigator.of(context).pop();
                try {
                  DatabaseService(user.uid).deleteSetup(uBikeID, uSetupID);
                } catch (e) {
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
    TextEditingController controller = TextEditingController(text: bikeNameOld);
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).cardTheme.color,
          title: Text(
            'Rename Bike',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          content: TextField(
            autofocus: true,
            cursorColor: Theme.of(context).textTheme.labelMedium!.color,
            controller: controller,
            style: Theme.of(context).textTheme.titleMedium,
            decoration: InputDecoration.collapsed(
              hintText: 'Enter new name',
              hintStyle: Theme.of(context).textTheme.titleMedium,
            ),
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
                  Text('Edit', style: Theme.of(context).textTheme.labelLarge),
              onPressed: () {
                Navigator.of(context).pop();
                try {
                  DatabaseService(FirebaseAuth.instance.currentUser!.uid)
                      .renameBike(uBikeID, controller.text);
                } catch (e) {
                  generalError(context, 'Error renaming bike');
                }
              },
            ),
          ],
        );
      },
    );
  }

  static Future<void> selectDefaultBike(
      BuildContext context, User user, Size size) async {
    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            backgroundColor: Theme.of(context).cardTheme.color,
            title: Text(
              'Select Default Bike',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            content: DefaultBikeSelector(
              user: user,
              size: size,
            ),
            actionsAlignment: MainAxisAlignment.spaceAround,
            actions: [
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
            ],
          );
        });
  }

  static Future<void> showSetupInformation(
      BuildContext context,
      Size size,
      String userID,
      String uBikeID,
      String uSetupID,
      String setupName,
      BikeType bikeType) async {
    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            backgroundColor: Theme.of(context).cardTheme.color,
            title: Text(
              setupName,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            content: SetupInformation(
              userID: userID,
              uBikeID: uBikeID,
              uSetupID: uSetupID,
              bikeType: bikeType,
            ),
            actionsAlignment: MainAxisAlignment.spaceAround,
            actions: [
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
                    'Ok',
                    style: Theme.of(context).textTheme.labelLarge,
                  ))
            ],
          );
        });
  }

  static Future<void> deleteError(BuildContext context, String type) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).cardTheme.color,
          title: Text('Deleting $type',
              style: Theme.of(context).textTheme.titleLarge),
          content: Text(
            'You must have at least one $type',
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
                child:
                    Text('Ok', style: Theme.of(context).textTheme.labelLarge)),
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
