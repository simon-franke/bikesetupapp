import 'package:bikesetupapp/Pages/home_page.dart';
import 'package:bikesetupapp/Pages/new_bike.dart'; // Add this line
import 'package:bikesetupapp/Services/alert_dialogs.dart';
import 'package:bikesetupapp/Services/database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class BikeList extends StatefulWidget {
  final User? user;
  const BikeList({super.key, required this.user});

  @override
  State<BikeList> createState() => _BikeListState();
}

class _BikeListState extends State<BikeList> {
  @override
  Widget build(BuildContext context) {
    if (widget.user == null) { // No user is signed in
      return const Center(
        child: Text('No User'),
      );
    } else { // User is signed in
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
            }
            else {
              return ListView.builder(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(top: 0),
              itemCount: bikes.length,
              itemBuilder: (context, index) {
                return Card(
                  elevation: 5,
                  child: ListTile(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (BuildContext context) => MyHomePage(
                            bikename: bikes.keys.elementAt(index),
                            user: widget.user,
                          ),
                        ),
                      );
                    },
                    leading: IconButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (BuildContext context) => NewBike(
                              user: widget.user!,
                              isnewbike: false,
                              isdefaultbike: false,
                              bike: bikes.keys.elementAt(index),
                            ),
                          ),
                        );
                      },
                      icon: Icon(
                        Icons.edit,
                        color: Theme.of(context).iconTheme.color,
                      ),
                    ),
                    title: Text(bikes.keys.elementAt(index), style: Theme.of(context).textTheme.labelLarge,),
                    trailing: IconButton(
                      onPressed: () async {
                        AlertDialogs.deleteBike(
                            context,
                            widget.user!,
                            bikes.keys.elementAt(index));
                      },
                      icon: Icon(
                        Icons.delete,
                        color: Theme.of(context).iconTheme.color,
                      ),
                    ),
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
