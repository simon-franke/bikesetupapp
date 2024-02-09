import 'package:bikesetupapp/alert_dialogs/bike_alert_dialogs.dart';
import 'package:bikesetupapp/database_service/database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DefaultBikeSelector extends StatelessWidget {
  final User user;
  final Size size;
  const DefaultBikeSelector(
      {super.key, required this.user, required this.size});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        stream: DatabaseService(user.uid).getBikes(),
        builder: (((context, AsyncSnapshot snapshot) {
          if (ConnectionState.waiting == snapshot.connectionState) {
            return const SizedBox(
              height: 100,
              width: 100,
            );
          } else if (snapshot.hasError) {
            return const Center(child: Text('Error'));
          } else {
            if (snapshot.data.docs.isEmpty) {
              return const Center(
                child: Text('No Bikes'),
              );
            } else {
              return SizedBox(
                width: size.width * 0.8,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListView.builder(
                      itemCount: snapshot.data.docs.length,
                      shrinkWrap: true,
                      itemBuilder: (context, index) {
                        DocumentSnapshot bike = snapshot.data.docs[index];
                        return Card(
                            color: Theme.of(context).scaffoldBackgroundColor,
                            child: ListTile(
                                title: Text(
                                  bike['bikename'],
                                  style:
                                      Theme.of(context).textTheme.labelMedium,
                                ),
                                onTap: () {
                                  DatabaseService(user.uid)
                                      .setDefaultBike(bike.id);
                                  Navigator.of(context).pop();
                                },
                                trailing: IconButton(
                                  onPressed: () {
                                    BikeAlerts.renameBike(
                                        context, bike.id, bike['bikename']);
                                  },
                                  icon: Icon(Icons.edit,
                                      color: Theme.of(context)
                                          .textTheme
                                          .titleLarge!
                                          .color),
                                )));
                      },
                    )
                  ],
                ),
              );
            }
          }
        })));
  }
}
