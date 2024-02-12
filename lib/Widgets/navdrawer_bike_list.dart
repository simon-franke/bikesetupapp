import 'package:bikesetupapp/alert_dialogs/bike_alert_dialogs.dart';
import 'package:bikesetupapp/app_pages/home_page.dart';
import 'package:bikesetupapp/app_pages/new_bike_page.dart';
import 'package:bikesetupapp/app_pages/todolist_page.dart';
import 'package:bikesetupapp/database_service/database.dart';
import 'package:bikesetupapp/bike_enums/biketype.dart';
import 'package:bikesetupapp/bike_enums/new_bike_mode.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BikeList extends StatefulWidget {
  final User? user;
  final String bikename;
  const BikeList({super.key, required this.user, required this.bikename});

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
            String currentbikename;
            String currentbiketype;
            try {
              currentbikename = bike['bikename'];
              currentbiketype = bike['biketype'];
            } catch (e) {
              currentbikename = "";
              currentbiketype = "Error";
            }
            return Card(
              elevation: 5,
              child: ExpansionTile(
                initiallyExpanded: currentbikename == widget.bikename,
                onExpansionChanged: (value) {},
                leading: IconButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (BuildContext context) => ToDoList(
                                user: widget.user!,
                                ubid: bike.id,
                                bikename: currentbikename,
                              )),
                    );
                  },
                  icon: Icon(
                    Icons.edit_calendar_outlined,
                    color: Theme.of(context).iconTheme.color,
                  ),
                ),
                title: Text(
                  currentbikename,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                subtitle: Text(
                  currentbiketype,
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
                      if (!mounted) return;
                      BikeAlerts.deleteError(context, 'Default Bike');
                      return;
                    }
                    if (!mounted) return;
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
                        String bikename = currentbikename;
                        String ubid = bike.id;
                        BikeType biketype =
                            BikeType.fromString(currentbiketype);
                        if (biketype == BikeType.error) {
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
                                            MaterialPageRoute(
                                              builder: (BuildContext context) =>
                                                  NewBike(
                                                      user: widget.user!,
                                                      newbikemode:
                                                          NewBikeMode.editSetup,
                                                      bikename: bikename,
                                                      ubid: ubid,
                                                      setupname:
                                                          setup['setupname'],
                                                      usid: setup.id,
                                                      biketype: biketype),
                                            ),
                                          );
                                        },
                                        icon: Icon(
                                          Icons.edit,
                                          color:
                                              Theme.of(context).iconTheme.color,
                                        ),
                                      ),
                                      title: Text(
                                        setup['setupname'],
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelMedium,
                                      ),
                                      onTap: () {
                                        Navigator.of(context).push(
                                          PageRouteBuilder(
                                            transitionDuration:
                                                const Duration(milliseconds: 200),
                                            transitionsBuilder:
                                                (BuildContext context,
                                                    Animation<double> animation,
                                                    Animation<double>
                                                        secondaryAnimation,
                                                    Widget child) {
                                              return SlideTransition(
                                                position: Tween<Offset>(
                                                  begin: const Offset(1.0, 0.0),
                                                  end: Offset.zero,
                                                ).animate(animation),
                                                child: child,
                                              );
                                            },
                                            pageBuilder: (BuildContext context,
                                                Animation<double> animation,
                                                Animation<double>
                                                    secondaryAnimation) {
                                              return MyHomePage(
                                                bikename: bikename,
                                                ubid: ubid,
                                                user: widget.user,
                                                biketype: biketype,
                                                setupname: setup['setupname'],
                                                usid: setup.id,
                                              );
                                            },
                                          ),
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
                                            if (!mounted) return;
                                            BikeAlerts.deleteError(
                                                context, 'Default Setup');
                                            return;
                                          }
                                          if (!mounted) return;
                                          BikeAlerts.deleteSetup(context,
                                              widget.user!, bike.id, setup.id);
                                        },
                                        icon: Icon(
                                          Icons.delete,
                                          color:
                                              Theme.of(context).iconTheme.color,
                                        ),
                                      ),
                                    );
                                  }),
                            ));
                      })),
                  ElevatedButton(
                    onPressed: () {
                      BikeType biketype = BikeType.fromString(currentbiketype);
                      if (biketype == BikeType.error) {
                        BikeAlerts.generalError(context, 'Something went wrong!');
                        return;
                      }
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (BuildContext context) => NewBike(
                              user: widget.user!,
                              newbikemode: NewBikeMode.newSetup,
                              bikename: currentbikename,
                              ubid: bike.id,
                              setupname: '',
                              usid: '',
                              biketype: biketype),
                        ),
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
