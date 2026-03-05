import 'package:bikesetupapp/widgets/sidebar_content.dart';
import 'package:bikesetupapp/bike_enums/bike_type.dart';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NavDrawer extends StatelessWidget {
  final String bikeName;
  final BikeType bikeType;
  final String chosenSetup;
  final User? user;
  const NavDrawer(
      {super.key,
      required this.bikeName,
      required this.bikeType,
      required this.chosenSetup,
      required this.user});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      child: SidebarContent(
        bikeName: bikeName,
        bikeType: bikeType,
        chosenSetup: chosenSetup,
        user: user,
        isInDrawer: true,
      ),
    );
  }
}
