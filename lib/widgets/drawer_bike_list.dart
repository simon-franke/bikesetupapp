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
            return Dismissible(
              key: Key(bike.id),
              direction: DismissDirection.endToStart,
              background: Container(
                color: Colors.red.shade700,
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                child: const Icon(Icons.delete_outline, color: Colors.white),
              ),
              confirmDismiss: (direction) async {
                if (snapshot.data!.docs.length <= 1) {
                  BikeAlerts.deleteError(context, 'Bike');
                  return false;
                }
                final defaultBikeId =
                    await DatabaseService(widget.user!.uid).getDefaultBike();
                if (!context.mounted) return false;
                if (bike.id == defaultBikeId) {
                  BikeAlerts.deleteError(context, 'Default Bike');
                  return false;
                }
                if (!context.mounted) return false;
                final confirmed = await showDialog<bool>(
                  context: context,
                  barrierDismissible: false,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: Theme.of(ctx).cardTheme.color,
                    title: Text('Deleting Bike',
                        style: Theme.of(ctx).textTheme.titleLarge),
                    content: Text(
                        'Are you sure you want to delete this Bike?',
                        style: Theme.of(ctx).textTheme.titleMedium),
                    actionsAlignment: MainAxisAlignment.spaceAround,
                    actions: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(ctx)
                                .floatingActionButtonTheme
                                .backgroundColor),
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: Text('Cancel',
                            style: Theme.of(ctx).textTheme.labelLarge),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(ctx)
                                .floatingActionButtonTheme
                                .backgroundColor),
                        onPressed: () => Navigator.of(ctx).pop(true),
                        child: Text('Delete',
                            style: Theme.of(ctx).textTheme.labelLarge),
                      ),
                    ],
                  ),
                );
                if (confirmed == true && context.mounted) {
                  try {
                    DatabaseService(widget.user!.uid).deleteBike(bike.id);
                  } catch (e) {
                    BikeAlerts.generalError(context, 'Error deleting bike');
                  }
                }
                return confirmed ?? false;
              },
              child: Card(
                elevation: 5,
                child: ExpansionTile(
                  initiallyExpanded: currentBikeName == widget.bikeName,
                  onExpansionChanged: (value) {},
                  tilePadding: const EdgeInsets.symmetric(horizontal: 8),
                  minTileHeight: 48,
                  leading: IconButton(
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 32, minHeight: 32),
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
                      Icons.assignment_outlined,
                      color: Theme.of(context).iconTheme.color,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    currentBikeName,
                    style: Theme.of(context).textTheme.labelLarge,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  subtitle: Text(
                    currentBikeType,
                    style: Theme.of(context).textTheme.bodySmall,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  children: <Widget>[
                    StreamBuilder(
                        stream: DatabaseService(widget.user!.uid)
                            .getSetups(bike.id),
                        builder: ((context, AsyncSnapshot setupSnapshot) {
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
                              setupSnapshot.connectionState) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }
                          if (setupSnapshot.hasError) {
                            return const Center(
                                child: Text('Something went wrong!'));
                          }
                          if (setupSnapshot.data.docs.isEmpty) {
                            return const Center(child: Text('No Setups'));
                          }
                          return Container(
                            color: Colors.black.withValues(alpha: 0.04),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                ListView.builder(
                                  shrinkWrap: true,
                                  physics:
                                      const NeverScrollableScrollPhysics(),
                                  padding: EdgeInsets.zero,
                                  itemCount: setupSnapshot.data.docs.length,
                                  itemBuilder: (context, index) {
                                    DocumentSnapshot setup =
                                        setupSnapshot.data.docs[index];
                                    return Dismissible(
                                      key: Key(setup.id),
                                      direction: DismissDirection.endToStart,
                                      background: Container(
                                        color: Colors.red.shade700,
                                        alignment: Alignment.centerRight,
                                        padding:
                                            const EdgeInsets.only(right: 20),
                                        child: const Icon(
                                            Icons.delete_outline,
                                            color: Colors.white),
                                      ),
                                      confirmDismiss: (direction) async {
                                        if (setupSnapshot.data.docs.length <=
                                            1) {
                                          BikeAlerts.deleteError(
                                              context, 'Setup');
                                          return false;
                                        }
                                        final defaultSetupId =
                                            await DatabaseService(
                                                    widget.user!.uid)
                                                .getDefaultSetup(bike.id);
                                        if (!context.mounted) return false;
                                        if (setup.id == defaultSetupId) {
                                          BikeAlerts.deleteError(
                                              context, 'Default Setup');
                                          return false;
                                        }
                                        if (!context.mounted) return false;
                                        final confirmed =
                                            await showDialog<bool>(
                                          context: context,
                                          barrierDismissible: false,
                                          builder: (ctx) => AlertDialog(
                                            backgroundColor:
                                                Theme.of(ctx).cardTheme.color,
                                            title: Text('Deleting Setup',
                                                style: Theme.of(ctx)
                                                    .textTheme
                                                    .titleLarge),
                                            content: Text(
                                                'Are you sure you want to delete this Setup?',
                                                style: Theme.of(ctx)
                                                    .textTheme
                                                    .titleMedium),
                                            actionsAlignment:
                                                MainAxisAlignment.spaceAround,
                                            actions: [
                                              ElevatedButton(
                                                style:
                                                    ElevatedButton.styleFrom(
                                                        backgroundColor: Theme
                                                                .of(ctx)
                                                            .floatingActionButtonTheme
                                                            .backgroundColor),
                                                onPressed: () =>
                                                    Navigator.of(ctx)
                                                        .pop(false),
                                                child: Text('Cancel',
                                                    style: Theme.of(ctx)
                                                        .textTheme
                                                        .labelLarge),
                                              ),
                                              ElevatedButton(
                                                style:
                                                    ElevatedButton.styleFrom(
                                                        backgroundColor: Theme
                                                                .of(ctx)
                                                            .floatingActionButtonTheme
                                                            .backgroundColor),
                                                onPressed: () =>
                                                    Navigator.of(ctx).pop(true),
                                                child: Text('Delete',
                                                    style: Theme.of(ctx)
                                                        .textTheme
                                                        .labelLarge),
                                              ),
                                            ],
                                          ),
                                        );
                                        if (confirmed == true &&
                                            context.mounted) {
                                          try {
                                            DatabaseService(widget.user!.uid)
                                                .deleteSetup(
                                                    uBikeID, setup.id);
                                          } catch (e) {
                                            BikeAlerts.generalError(context,
                                                'Error deleting setup');
                                          }
                                        }
                                        return confirmed ?? false;
                                      },
                                      child: ListTile(
                                        dense: true,
                                        contentPadding: const EdgeInsets.only(
                                            left: 32, right: 8),
                                        leading: IconButton(
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(
                                              minWidth: 28, minHeight: 28),
                                          onPressed: () {
                                            Navigator.of(context).push(
                                              AppRoutes.fadeSlide(NewBike(
                                                user: widget.user!,
                                                newBikeMode:
                                                    NewBikeMode.editSetup,
                                                bikeName: bikeName,
                                                uBikeID: uBikeID,
                                                setupName:
                                                    setup['setup_name'],
                                                uSetupID: setup.id,
                                                bikeType: bikeType,
                                              )),
                                            );
                                          },
                                          icon: Icon(
                                            Icons.edit_outlined,
                                            color: Theme.of(context)
                                                .iconTheme
                                                .color,
                                            size: 16,
                                          ),
                                        ),
                                        title: Text(
                                          setup['setup_name'],
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall,
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
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
                                      ),
                                    );
                                  },
                                ),
                                // New Setup row
                                InkWell(
                                  onTap: () {
                                    BikeType bt =
                                        BikeType.fromString(currentBikeType);
                                    if (bt == BikeType.error) {
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
                                        bikeType: bt,
                                      )),
                                    );
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 32, vertical: 10),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.add,
                                          size: 16,
                                          color: Theme.of(context)
                                              .floatingActionButtonTheme
                                              .backgroundColor,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'New Setup',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color: Theme.of(context)
                                                    .floatingActionButtonTheme
                                                    .backgroundColor,
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        })),
                ],
              ),
            ),
          );
          },
        );
      }),
    );
  }
}
