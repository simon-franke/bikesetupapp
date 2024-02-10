import 'package:bikesetupapp/database_service/database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CopyFromOtherSetup extends StatefulWidget {
  final User user;
  final Size size;
  final String ubid;

  const CopyFromOtherSetup({super.key, required this.ubid, required this.size, required this.user});

  @override
  State<CopyFromOtherSetup> createState() => _CopyFromOtherSetupState();
}

class _CopyFromOtherSetupState extends State<CopyFromOtherSetup> {
  String? selectedSetup;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: DatabaseService(widget.user.uid).getSetups(widget.ubid),
      builder: (BuildContext context, AsyncSnapshot snapshot) {
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
              width: widget.size.width * 0.8,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListView.builder(
                    itemCount: snapshot.data.docs.length,
                    shrinkWrap: true,
                    itemBuilder: (context, index) {
                      DocumentSnapshot setup = snapshot.data.docs[index];
                      return Card(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        child: ListTile(
                          leading: Checkbox(
                            value: selectedSetup == setup['setupname'],
                            onChanged: (value) {
                              setState(() {
                                selectedSetup = value! ? setup['setupname'] : null;
                              });
                            },
                          ),
                          title: Text(
                            setup['setupname'],
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          }
        }
      },
    );
  }
}