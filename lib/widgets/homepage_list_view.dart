import 'package:bikesetupapp/alert_dialogs/settings_alert_dialogs.dart';
import 'package:bikesetupapp/database_service/database.dart';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomePageListView extends StatefulWidget {
  final User user;
  final String bikeName;
  final String uBikeID;
  final String category;
  final String setup;
  final String uSetupID;
  final double topPadding;
  const HomePageListView(
      {super.key,
      required this.user,
      required this.bikeName,
      required this.uBikeID,
      required this.category,
      required this.setup,
      required this.uSetupID,
      this.topPadding = 45.0});

  @override
  State<HomePageListView> createState() => _HomePageListViewState();
}

class _HomePageListViewState extends State<HomePageListView>
    with SingleTickerProviderStateMixin {
  late AnimationController _listAnimController;

  @override
  void initState() {
    super.initState();
    _listAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _listAnimController.forward();
  }

  @override
  void didUpdateWidget(HomePageListView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.category != oldWidget.category) {
      _listAnimController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _listAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: DatabaseService(widget.user.uid)
          .getSettings(widget.uBikeID, widget.category, widget.uSetupID),
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
              child: Text('This bike does not exist',
                  style: Theme.of(context).textTheme.labelLarge));
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
          padding: EdgeInsets.only(top: widget.topPadding + 5),
          itemCount: settings.length,
          itemBuilder: (context, index) {
            final interval = Interval(
              (index * 40.0).clamp(0, 280) / 400,
              ((index * 40.0).clamp(0, 280) + 300) / 400,
              curve: Curves.easeOut,
            );
            final anim = CurvedAnimation(
              parent: _listAnimController,
              curve: interval,
            );
            return FadeTransition(
              opacity: anim,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.1),
                  end: Offset.zero,
                ).animate(anim),
                child: Card(
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
                              widget.uBikeID,
                              widget.category,
                              widget.uSetupID);
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
                                  widget.uBikeID,
                                  widget.category,
                                  widget.uSetupID);
                            },
                            icon: Icon(Icons.delete,
                                color: Theme.of(context).iconTheme.color))),
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
