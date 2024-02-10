import 'package:bikesetupapp/app_pages/new_bike_page.dart';
import 'package:bikesetupapp/bike_enums/biketype.dart';
import 'package:bikesetupapp/bike_enums/new_bike_mode.dart';
import 'package:bikesetupapp/database_service/database.dart';
import 'package:bikesetupapp/widgets/copy_from_other_setup_widget.dart';
import 'package:bikesetupapp/widgets/default_bike_selector_widget.dart';
import 'package:bikesetupapp/widgets/setup_information_alert_content.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BikeAlerts {
  static Future<void> deleteBike(
      BuildContext context, User user, String ubid) async {
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
                DatabaseService(user.uid).deleteBike(ubid);
              },
            ),
          ],
        );
      },
    );
  }

  static Future<void> deleteSetup(
      BuildContext context, User user, String ubid, String usid) async {
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
                DatabaseService(user.uid).deleteSetup(ubid, usid);
              },
            ),
          ],
        );
      },
    );
  }

  static Future<void> renameBike(
      BuildContext context, String ubid, String bikeNameOld) async {
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
                DatabaseService(FirebaseAuth.instance.currentUser!.uid)
                    .renameBike(ubid, controller.text);
              },
            ),
          ],
        );
      },
    );
  }

  static Future<void> deleteBikeError(BuildContext context, String type) async {
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
      String bikename,
      String ubid,
      String setupname,
      BikeType biketype) async {
    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            backgroundColor: Theme.of(context).cardTheme.color,
            title: Text(
              setupname,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            content: SetupInformation(
              userID: userID,
              ubid: bikename,
              usid: ubid,
              biketype: biketype,
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
                    style: Theme.of(context).textTheme.titleMedium,
                  ))
            ],
          );
        });
  }

  static Future<void> copyFromOtherSetup(BuildContext context, String bikename,
      User user, String ubid, BikeType biketype) async {
    Size size = MediaQuery.of(context).size;
    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            backgroundColor: Theme.of(context).cardTheme.color,
            title: Text(
              'Copy from other setup',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            content: CopyFromOtherSetup(user: user, size: size, ubid: ubid),
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
                    'Cancel',
                    style: Theme.of(context).textTheme.titleMedium,
                  )),
              ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context)
                        .floatingActionButtonTheme
                        .backgroundColor,
                  ),
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => NewBike(
                          user: user,
                          newbikemode: NewBikeMode.newSetup,
                          isdefaultbike: false,
                          bikename: bikename,
                          ubid: ubid,
                          setupname: "",
                          usid: "",
                          biketype: biketype),
                    ));
                  },
                  child: Text(
                    'Ok',
                    style: Theme.of(context).textTheme.titleMedium,
                  ))
            ],
          );
        });
  }
}
