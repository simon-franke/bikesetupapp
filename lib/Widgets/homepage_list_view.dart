import 'package:bikesetupapp/alert_dialogs/settings_alert_dialogs.dart';
import 'package:bikesetupapp/database_service/database.dart';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomePageListView extends StatefulWidget {
  final User user;
  final String bikename;
  final String ubid;
  final String category;
  final String setup;
  final String usid;
  const HomePageListView(
      {super.key,
      required this.user,
      required this.bikename,
      required this.ubid,
      required this.category,
      required this.setup,
      required this.usid});

  @override
  State<HomePageListView> createState() => _HomePageListViewState();
}

class _HomePageListViewState extends State<HomePageListView> {
  late Future<void> initData;
  late bool isDataLoaded = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: DatabaseService(widget.user.uid)
          .getSettings(widget.ubid, widget.category, widget.usid),
      builder: ((context, AsyncSnapshot snapshot) {
        if (ConnectionState.waiting == snapshot.connectionState) {
          return Center(
            child: CircularProgressIndicator.adaptive(
                valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context)
                    .floatingActionButtonTheme
                    .backgroundColor!)),
          );
        }
        if (snapshot.hasError) {
          return Center(
              child:
                  Text('Error', style: Theme.of(context).textTheme.labelLarge));
        }
        if (snapshot.data == null || snapshot.data!.data() == null) {
          return Center(
              child: CircularProgressIndicator.adaptive(
            valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).floatingActionButtonTheme.backgroundColor!),
          ));
        }
        Map<String, dynamic>? settings =
            snapshot.data!.data() as Map<String, dynamic>?;
        if (settings == null) {
          return Center(
              child:
                  Text('Error', style: Theme.of(context).textTheme.labelLarge));
        }
        return ListView.builder(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(top: 40 + 5),
          itemCount: settings.length,
          itemBuilder: (context, index) {
            return Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15.0),
              ),
              elevation: 5,
              child: ListTile(
                leading: IconButton(
                    onPressed: () {
                      SettingsAlerts.editValue(
                          context,
                          widget.user,
                          settings.keys.elementAt(index),
                          settings.values.elementAt(index),
                          widget.ubid,
                          widget.category,
                          widget.usid);
                    },
                    icon: Icon(
                      Icons.edit,
                      color: Theme.of(context).iconTheme.color,
                    )),
                title: Text(
                  settings.keys.elementAt(index),
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                subtitle: Text(
                  settings.values.elementAt(index),
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                trailing: Visibility(
                    visible: settings.keys.elementAt(index) != 'Pressure',
                    child: IconButton(
                        tooltip: 'Delete Setting',
                        onPressed: () {
                          SettingsAlerts.deleteCategory(
                              context,
                              widget.user,
                              settings.keys.elementAt(index),
                              widget.ubid,
                              widget.category,
                              widget.usid);
                        },
                        icon: Icon(Icons.delete,
                            color: Theme.of(context).iconTheme.color))),
              ),
            );
          },
        );
      }),
    );
  }
}
