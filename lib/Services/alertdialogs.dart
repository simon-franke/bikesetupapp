import 'package:bikesetupapp/Services/database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AlertDialogs {
  static Future<void> newKey(BuildContext context, User user, String bikename, String category, String setup) async {
    String key = "";
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: Text('New Category', style: Theme.of(context).textTheme.titleMedium),
          content: TextFormField(
            decoration: const InputDecoration(
              hintText: 'Category Name',
            ),
            onChanged: (value) {
              key = value;
            },
          ),
          actions: <Widget>[
            ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Cancel')),
            ElevatedButton(
              child: const Text('Enter'),
              onPressed: () {
                if (key == "") {
                  return;
                }
                else {
                  Navigator.of(context).pop();
                  newValue(context, key, user, bikename, category, setup);
                }
              },
            ),
          ],
        );
      },
    );
  }

  static Future<void> newValue(BuildContext context, String key, User user, String bikename, String category, String setup) async {
    String value = "";
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: Text(key, style: Theme.of(context).textTheme.titleMedium),
          content: TextFormField(
              decoration: const InputDecoration(
                
                hintText: 'Value',
              ),
              onChanged: (val) {
                value = val;
              },
            ),
          actions: <Widget>[
            ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Cancel')),
            ElevatedButton(
              child: const Text('Enter'),
              onPressed: () {
                Navigator.of(context).pop();
                  DatabaseService(user.uid).setSetting(key, value, bikename, category, setup);
              },
            ),
          ],
        );
      },
    );
  }

  static Future<void> editValue (BuildContext context, User user, String key, String value, String bikename, String category, String setup) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: Text(key, style: Theme.of(context).textTheme.titleMedium,),
          content: TextFormField(
              style: Theme.of(context).textTheme.titleMedium,
              initialValue: value,
              decoration: const InputDecoration(
              ),
              onChanged: (val) {
                value = val;
              },
            ),
          actions: <Widget>[
            ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Cancel')),
            ElevatedButton(
              child: const Text('Enter'),
              onPressed: () {
                Navigator.of(context).pop();
                DatabaseService(user.uid).editSetting(key, value, bikename, category, setup);
              },
            ),
          ],
        );
      },
    );
  }

  static Future<void> deleteCategory (BuildContext context, User user, String key, String bikename, String category, String setup) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: Text('Delete Category', style: Theme.of(context).textTheme.titleLarge,),
          content: Text('Are you sure you want to delete this category?', style: Theme.of(context).textTheme.titleMedium,),
          actions: <Widget>[
            ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Cancel')),
            ElevatedButton(
              child: const Text('Delete'),
              onPressed: () {
                Navigator.of(context).pop();
                DatabaseService(user.uid).deleteSetting(key, bikename, category, setup);
              },
            ),
          ],
        );
      },
    );
  }

static Future<void> deleteBike (BuildContext context, User user, String bikename) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: Text('Deleting Bike', style: Theme.of(context).textTheme.titleLarge,),
          content: Text('Are you sure you want to delete this Bike?', style: Theme.of(context).textTheme.titleMedium,),
          actionsAlignment: MainAxisAlignment.spaceAround,
          actions: <Widget>[
            ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Cancel')),
            ElevatedButton(
              child: const Text('Delete'),
              onPressed: () {
                Navigator.of(context).pop();
                DatabaseService(user.uid).deleteBike(bikename);
              },
            ),
          ],
        );
      },
    );
  }
}
