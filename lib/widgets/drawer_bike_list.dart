import 'package:bikesetupapp/alert_dialogs/bike_alert_dialogs.dart';
import 'package:bikesetupapp/app_pages/home_page.dart';
import 'package:bikesetupapp/app_pages/new_bike_page.dart';
import 'package:bikesetupapp/app_pages/todolist_page.dart';
import 'package:bikesetupapp/app_services/app_routes.dart';
import 'package:bikesetupapp/database_service/database.dart';
import 'package:bikesetupapp/bike_enums/bike_type.dart';
import 'package:bikesetupapp/bike_enums/new_bike_mode.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BikeList extends StatefulWidget {
  final User? user;
  final String bikeName;
  const BikeList({super.key, required this.user, required this.bikeName});

  @override
  State<BikeList> createState() => _BikeListState();
}

class _BikeListState extends State<BikeList> {
  @override
  Widget build(BuildContext context) {
    if (widget.user == null) {
      return Center(
        child: Text('No User', style: Theme.of(context).textTheme.labelLarge),
      );
    }
    return StreamBuilder(
      stream: DatabaseService(widget.user!.uid).getBikes(),
      builder: ((context, AsyncSnapshot snapshot) {
        if (ConnectionState.waiting == snapshot.connectionState) {
          return Center(
              child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).floatingActionButtonTheme.backgroundColor!),
          ));
        }
        if (snapshot.hasError) {
          return Center(
              child: Text(
            'Error',
            style: Theme.of(context).textTheme.labelLarge,
          ));
        }
        if (snapshot.data == null || snapshot.data.docs.isEmpty) {
          return Center(
            child:
                Text('No Bikes', style: Theme.of(context).textTheme.labelLarge),
          );
        }
        return ListView.builder(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(top: 0),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            DocumentSnapshot bike = snapshot.data.docs[index];
            String currentBikeName;
            String currentBikeType;
            try {
              currentBikeName = bike['bike_name'];
              currentBikeType = bike['bike_type'];
            } catch (e) {
              currentBikeName = "";
              currentBikeType = "Error";
            }
            return Card(
              elevation: 5,
              child: ExpansionTile(
                initiallyExpanded: currentBikeName == widget.bikeName,
                onExpansionChanged: (value) {},
                leading: IconButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      AppRoutes.fadeSlide(ToDoList(
                        user: widget.user!,
                        uBikeID: bike.id,
                        bikeName: currentBikeName,
                      )),
                    );
                  },
                  icon: Icon(
                    Icons.edit_calendar_outlined,
                    color: Theme.of(context).iconTheme.color,
                  ),
                ),
                title: Text(
                  currentBikeName,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                subtitle: Text(
                  currentBikeType,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                trailing: IconButton(
                  onPressed: () async {
                    if (snapshot.data!.docs.length <= 1) {
                      BikeAlerts.deleteError(context, 'Bike');
                      return;
                    }
                    if (bike.id ==
                        await DatabaseService(widget.user!.uid)
                            .getDefaultBike()) {
                      if (!context.mounted) return;
                      BikeAlerts.deleteError(context, 'Default Bike');
                      return;
                    }
                    if (!context.mounted) return;
                    BikeAlerts.deleteBike(context, widget.user!, bike.id);
                  },
                  icon: Icon(
                    Icons.delete,
                    color: Theme.of(context).iconTheme.color,
                  ),
                ),
                children: <Widget>[
                  StreamBuilder(
                      stream:
                          DatabaseService(widget.user!.uid).getSetups(bike.id),
                      builder: ((context, AsyncSnapshot snapshot) {
                        String bikeName = currentBikeName;
                        String uBikeID = bike.id;
                        BikeType bikeType =
                            BikeType.fromString(currentBikeType);
                        if (bikeType == BikeType.error) {
                          return const Center(
                            child: Text('Something went wrong!'),
                          );
                        }
                        if (ConnectionState.waiting ==
                            snapshot.connectionState) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                        if (snapshot.hasError) {
                          return const Center(
                              child: Text('Something went wrong!'));
                        }
                        if (snapshot.data.docs.isEmpty) {
                          return const Center(
                            child: Text('No Setups'),
                          );
                        }
                        return SizedBox(
                            child: Padding(
                          padding: const EdgeInsets.only(left: 20.0),
                          child: ListView.builder(
                              shrinkWrap: true,
                              physics: const BouncingScrollPhysics(),
                              padding: const EdgeInsets.only(top: 0),
                              itemCount: snapshot.data.docs.length,
                              itemBuilder: (context, index) {
                                DocumentSnapshot setup =
                                    snapshot.data.docs[index];
                                return ListTile(
                                  leading: IconButton(
                                    onPressed: () {
                                      Navigator.of(context).push(
                                        AppRoutes.fadeSlide(NewBike(
                                          user: widget.user!,
                                          newBikeMode: NewBikeMode.editSetup,
                                          bikeName: bikeName,
                                          uBikeID: uBikeID,
                                          setupName: setup['setup_name'],
                                          uSetupID: setup.id,
                                          bikeType: bikeType,
                                        )),
                                      );
                                    },
                                    icon: Icon(
                                      Icons.edit,
                                      color: Theme.of(context).iconTheme.color,
                                    ),
                                  ),
                                  title: Text(
                                    setup['setup_name'],
                                    style:
                                        Theme.of(context).textTheme.labelMedium,
                                  ),
                                  onTap: () {
                                    Navigator.of(context).push(
                                      AppRoutes.fadeSlide(MyHomePage(
                                        bikeName: bikeName,
                                        uBikeID: uBikeID,
                                        user: widget.user,
                                        bikeType: bikeType,
                                        setupName: setup['setup_name'],
                                        uSetupID: setup.id,
                                      )),
                                    );
                                  },
                                  trailing: IconButton(
                                    onPressed: () async {
                                      if (snapshot.data.docs.length <= 1) {
                                        BikeAlerts.deleteError(
                                            context, 'Setup');
                                        return;
                                      }
                                      if (setup.id ==
                                          await DatabaseService(
                                                  widget.user!.uid)
                                              .getDefaultSetup(bike.id)) {
                                        if (!context.mounted) return;
                                        BikeAlerts.deleteError(
                                            context, 'Default Setup');
                                        return;
                                      }
                                      if (!context.mounted) return;
                                      BikeAlerts.deleteSetup(context,
                                          widget.user!, bike.id, setup.id);
                                    },
                                    icon: Icon(
                                      Icons.delete,
                                      color: Theme.of(context).iconTheme.color,
                                    ),
                                  ),
                                );
                              }),
                        ));
                      })),
                  ElevatedButton(
                    onPressed: () {
                      BikeType bikeType = BikeType.fromString(currentBikeType);
                      if (bikeType == BikeType.error) {
                        BikeAlerts.generalError(
                            context, 'Something went wrong!');
                        return;
                      }
                      Navigator.of(context).push(
                        AppRoutes.fadeSlide(NewBike(
                          user: widget.user!,
                          newBikeMode: NewBikeMode.newSetup,
                          bikeName: currentBikeName,
                          uBikeID: bike.id,
                          setupName: '',
                          uSetupID: '',
                          bikeType: bikeType,
                        )),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context)
                            .floatingActionButtonTheme
                            .backgroundColor),
                    child: Text(
                      'New Setup',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  )
                ],
              ),
            );
          },
        );
      }),
    );
  }
}
