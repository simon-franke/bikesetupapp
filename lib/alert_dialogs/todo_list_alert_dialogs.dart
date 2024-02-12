import 'package:bikesetupapp/database_service/database.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class TodoAlerts {
  static Future<void> newTodo(
      BuildContext context, String bikename, User user) async {
    String taskname = "";
    String taskdescription = "";
    String partsneeded = "";
    return showDialog(
        context: context,
        builder: ((BuildContext context) {
          return AlertDialog(
            backgroundColor: Theme.of(context).cardTheme.color,
            title: Text(
              'New Task',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            content: SizedBox(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Card(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: TextFormField(
                        cursorColor:
                            Theme.of(context).textTheme.labelMedium!.color,
                        autofocus: false,
                        initialValue: taskname,
                        decoration: InputDecoration.collapsed(
                          hintStyle: Theme.of(context).textTheme.labelSmall,
                          hintText: 'Task Name',
                        ),
                        onChanged: (value) {
                          taskname = value;
                        },
                      ),
                    ),
                  ),
                  Card(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: TextField(
                        cursorColor:
                            Theme.of(context).textTheme.labelMedium!.color,
                        autofocus: false,
                        controller:
                            TextEditingController(text: taskdescription),
                        minLines: 1,
                        maxLines: 4,
                        decoration: InputDecoration.collapsed(
                          hintStyle: Theme.of(context).textTheme.labelSmall,
                          hintText: 'Task Description',
                        ),
                        onChanged: (value) {
                          taskdescription = value;
                        },
                      ),
                    ),
                  ),
                  Card(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: TextFormField(
                          cursorColor:
                              Theme.of(context).textTheme.labelMedium!.color,
                          autofocus: false,
                          initialValue: partsneeded,
                          decoration: InputDecoration.collapsed(
                            hintStyle: Theme.of(context).textTheme.labelSmall,
                            hintText: 'Parts Needed',
                          ),
                          onChanged: (value) {
                            partsneeded = value;
                          },
                        ),
                      ))
                ],
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
                  child: Text(
                    'Cancel',
                    style: Theme.of(context).textTheme.labelLarge,
                  )),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context)
                      .floatingActionButtonTheme
                      .backgroundColor,
                ),
                child: Text(
                  'Enter',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  try {
                    DatabaseService(user.uid).setTodo(
                      bikename, taskname, taskdescription, partsneeded);
                  } catch (e) {
                    generalError(context, 'Error creating todo');
                  }
                  
                },
              ),
            ],
          );
        }));
  }

  static Future<void> editTodo(
      BuildContext context,
      String bikename,
      String docId,
      User user,
      String taskname,
      String taskdescription,
      String partsneeded,
      bool isdone) async {
    return showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: Theme.of(context).cardTheme.color,
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Edit Task',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                IconButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      try {
                        DatabaseService(user.uid).deleteTodo(bikename, docId);
                      } catch (e) {
                        generalError(context, 'Error deleting todo');
                      }
                    },
                    icon: const Icon(Icons.delete))
              ],
            ),
            content: SizedBox(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Card(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: TextFormField(
                        cursorColor:
                            Theme.of(context).textTheme.labelMedium!.color,
                        autofocus: false,
                        initialValue: taskname,
                        decoration: InputDecoration.collapsed(
                          hintStyle: Theme.of(context).textTheme.labelSmall,
                          hintText: 'Task Name',
                        ),
                        onChanged: (value) {
                          taskname = value;
                        },
                      ),
                    ),
                  ),
                  Card(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: TextField(
                        cursorColor:
                            Theme.of(context).textTheme.labelMedium!.color,
                        autofocus: false,
                        controller:
                            TextEditingController(text: taskdescription),
                        minLines: 1,
                        maxLines: 4,
                        decoration: InputDecoration.collapsed(
                          hintStyle: Theme.of(context).textTheme.labelSmall,
                          hintText: 'Task Description',
                        ),
                        onChanged: (value) {
                          taskdescription = value;
                        },
                      ),
                    ),
                  ),
                  Card(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: TextFormField(
                          cursorColor:
                              Theme.of(context).textTheme.labelMedium!.color,
                          autofocus: false,
                          initialValue: partsneeded,
                          decoration: InputDecoration.collapsed(
                            hintStyle: Theme.of(context).textTheme.labelSmall,
                            hintText: 'Parts Needed',
                          ),
                          onChanged: (value) {
                            partsneeded = value;
                          },
                        ),
                      ))
                ],
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
                      style: Theme.of(context).textTheme.labelMedium)),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context)
                      .floatingActionButtonTheme
                      .backgroundColor,
                ),
                child: Text(
                  'Edit',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  try {
                    DatabaseService(user.uid).editTodo(bikename, docId,
                        taskname, taskdescription, partsneeded, isdone);
                  } catch (e) {
                    generalError(context, 'Error editing todo');
                  }
                },
              ),
            ],
          );
        });
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
