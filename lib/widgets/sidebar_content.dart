import 'package:bikesetupapp/app_pages/bike_selector_page.dart';
import 'package:bikesetupapp/app_pages/settings_page.dart';
import 'package:bikesetupapp/app_services/app_routes.dart';
import 'package:bikesetupapp/widgets/drawer_bike_list.dart';
import 'package:bikesetupapp/bike_enums/bike_type.dart';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SidebarContent extends StatelessWidget {
  final String bikeName;
  final BikeType bikeType;
  final String chosenSetup;
  final User? user;
  final bool isInDrawer;

  const SidebarContent({
    super.key,
    required this.bikeName,
    required this.bikeType,
    required this.chosenSetup,
    required this.user,
    this.isInDrawer = false,
  });

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    return Column(
      children: [
        Container(
          height: size.height * 0.20,
          color: Theme.of(context).primaryColor,
          child: Center(
            child: ListTile(
              leading: user != null && user!.photoURL != null
                  ? Padding(
                      padding: const EdgeInsets.all(5),
                      child: CircleAvatar(
                        backgroundImage: NetworkImage('${user?.photoURL}'),
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.all(5),
                      child: CircleAvatar(
                        backgroundColor: Theme.of(context).primaryColor,
                        backgroundImage:
                            const AssetImage('assets/incognito.png'),
                      ),
                    ),
              title: Text('Bike Setup',
                  style: Theme.of(context).textTheme.titleLarge),
              subtitle: user != null && user!.email != null
                  ? Text(
                      '${user?.email}',
                      style: Theme.of(context).textTheme.titleSmall,
                    )
                  : null,
            ),
          ),
        ),
        Expanded(
          child: BikeList(
            user: user,
            bikeName: bikeName,
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.all(5),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(AppRoutes.fadeSlide(SettingsPage(
                    bikeName: bikeName,
                    bikeType: bikeType,
                    chosenSetup: chosenSetup,
                  )));
                },
                style: IconButton.styleFrom(
                    backgroundColor: Theme.of(context)
                        .floatingActionButtonTheme
                        .backgroundColor),
                child: Text(
                  'Settings',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(5),
              child: ElevatedButton(
                onPressed: () {
                  if (user != null) {
                    if (isInDrawer) Navigator.of(context).pop();
                    Navigator.of(context).push(
                        AppRoutes.fadeSlide(BikeTypeSelector(user: user!)));
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('No User logged in')));
                  }
                },
                style: IconButton.styleFrom(
                    backgroundColor: Theme.of(context)
                        .floatingActionButtonTheme
                        .backgroundColor),
                child: Text(
                  'New Bike',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
