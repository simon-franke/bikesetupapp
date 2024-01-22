import 'package:bikesetupapp/Pages/home_page.dart';
import 'package:bikesetupapp/Pages/new_bike.dart'; // Add this line
import 'package:bikesetupapp/Services/alert_dialogs.dart';
import 'package:bikesetupapp/Services/database.dart';
import 'package:bikesetupapp/Services/enums.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

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
      // No user is signed in
      return const Center(
        child: Text('No User'),
      );
    } else {
      // User is signed in
      return StreamBuilder(
        stream: DatabaseService(widget.user!.uid).getBikes(),
        builder: ((context, AsyncSnapshot snapshot) {
          if (ConnectionState.waiting == snapshot.connectionState) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Center(child: Text('Error'));
          } else {
            Map<String, dynamic>? bikes =
                snapshot.data!.data() as Map<String, dynamic>?;
            if (bikes == null) {
              return const Center(
                child: Text('No Bikes'),
              );
            } else {
              return ListView.builder(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(top: 0),
                itemCount: bikes.length,
                itemBuilder: (context, index) {
                  return Card(
                    elevation: 5,
                    child: ExpansionTile(
                      initiallyExpanded:
                          bikes.keys.elementAt(index) == widget.bikename,
                      onExpansionChanged: (value) {},
                      title: Text(
                        bikes.keys.elementAt(index),
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      subtitle: Text(
                        bikes.values.elementAt(index),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      trailing: IconButton(
                        onPressed: () async {
                          if (bikes.length <= 1) {
                            AlertDialogs.deleteBikeError(context);
                            return;
                          }
                          AlertDialogs.deleteBike(context, widget.user!,
                              bikes.keys.elementAt(index));
                        },
                        icon: Icon(
                          Icons.delete,
                          color: Theme.of(context).iconTheme.color,
                        ),
                      ),
                      children: <Widget>[
                        StreamBuilder(
                            stream: DatabaseService(widget.user!.uid)
                                .getSetups(bikes.keys.elementAt(index)),
                            builder: ((context, AsyncSnapshot snapshot) {
                              String bikename = bikes.keys.elementAt(index);
                              
                              BikeType biketype = BikeType.fromString(bikes.values.elementAt(index));
                              if (biketype == BikeType.error) {
                                return const Center(
                                  child: Text('Error'),
                                );
                              }
                              if (ConnectionState.waiting ==
                                  snapshot.connectionState) {
                                return const Center(
                                    child: CircularProgressIndicator());
                              } else if (snapshot.hasError) {
                                return const Center(child: Text('Error'));
                              } else {
                                Map<String, dynamic>? setuplist = snapshot.data!
                                    .data() as Map<String, dynamic>?;
                                if (setuplist == null) {
                                  return const Center(
                                    child: Text('No Setups'),
                                  );
                                } else {
                                  return SizedBox(
                                      child: ListView.builder(
                                          shrinkWrap: true,
                                          physics:
                                              const BouncingScrollPhysics(),
                                          padding:
                                              const EdgeInsets.only(top: 0),
                                          itemCount: setuplist.length,
                                          itemBuilder: (context, index) {
                                            return ListTile(
                                              leading: IconButton(
                                                onPressed: () {
                                                  Navigator.of(context).push(
                                                    MaterialPageRoute(
                                                      builder: (BuildContext
                                                              context) =>
                                                          NewBike(
                                                              user:
                                                                  widget.user!,
                                                              newbikemode: NewBikeMode
                                                                  .editSetup,
                                                              isdefaultbike:
                                                                  false,
                                                              bike: bikename,
                                                              setup: setuplist
                                                                  .keys
                                                                  .elementAt(
                                                                      index),
                                                              biketype:
                                                                  biketype),
                                                    ),
                                                  );
                                                },
                                                icon: Icon(
                                                  Icons.edit,
                                                  color: Theme.of(context)
                                                      .iconTheme
                                                      .color,
                                                ),
                                              ),
                                              title: Text(
                                                setuplist.keys.elementAt(index),
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .labelMedium,
                                              ),
                                              onTap: () {
                                                Navigator.of(context).push(
                                                  MaterialPageRoute(
                                                    builder: (BuildContext
                                                            context) =>
                                                        MyHomePage(
                                                      bikename: bikename,
                                                      user: widget.user,
                                                      biketype: biketype,
                                                      chosensetup: setuplist
                                                          .keys
                                                          .elementAt(index),
                                                    ),
                                                  ),
                                                );
                                              },
                                              trailing: IconButton(
                                                onPressed: () async {
                                                  if (setuplist.length <= 1) {
                                                    AlertDialogs
                                                        .deleteBikeError(
                                                            context);
                                                    return;
                                                  }
                                                  AlertDialogs.deleteSetup(
                                                      context,
                                                      widget.user!,
                                                      bikename,
                                                      setuplist.keys
                                                          .elementAt(index));
                                                },
                                                icon: Icon(
                                                  Icons.delete,
                                                  color: Theme.of(context)
                                                      .iconTheme
                                                      .color,
                                                ),
                                              ),
                                            );
                                          }));
                                }
                              }
                            })),
                        ElevatedButton(
                          onPressed: () {
                            BikeType biketype = BikeType.fromString(bikes.values.elementAt(index));
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (BuildContext context) => NewBike(
                                  user: widget.user!,
                                  newbikemode: NewBikeMode.newSetup,
                                  isdefaultbike: false,
                                  setup: "",
                                  bike: bikes.keys.elementAt(index),
                                  biketype: biketype,
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context)
                                  .floatingActionButtonTheme
                                  .backgroundColor),
                          child: Text(
                            'New Setup',
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        )
                      ],
                    ),
                  );
                },
              );
            }
          }
        }),
      );
    }
  }
}
