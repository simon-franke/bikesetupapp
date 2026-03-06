import 'package:bikesetupapp/app_pages/settings_page.dart';
import 'package:bikesetupapp/app_services/app_routes.dart';
import 'package:bikesetupapp/bike_enums/new_bike_mode.dart';
import 'package:bikesetupapp/widgets/drawer_bike_list.dart';
import 'package:bikesetupapp/widgets/new_bike_bottom_sheet.dart';
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
        // Header
        Container(
          height: size.height * 0.20,
          color: Theme.of(context).primaryColor,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          child: SafeArea(
            bottom: false,
            child: Row(
              children: [
                user != null && user!.photoURL != null
                    ? CircleAvatar(
                        backgroundImage: NetworkImage(user!.photoURL!),
                        radius: 24,
                      )
                    : CircleAvatar(
                        backgroundColor: Theme.of(context).primaryColor,
                        backgroundImage:
                            const AssetImage('assets/incognito.png'),
                        radius: 24,
                      ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bike Setup',
                        style: Theme.of(context).textTheme.titleLarge,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      if (user?.email != null)
                        Text(
                          user!.email!,
                          style: Theme.of(context).textTheme.titleSmall,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        // Bike list
        Expanded(
          child: BikeList(
            user: user,
            bikeName: bikeName,
          ),
        ),
        // Fixed footer
        Container(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.06),
            border: Border(
              top: BorderSide(color: Colors.black.withValues(alpha: 0.12), width: 0.5),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  dense: true,
                  leading: Icon(
                    Icons.settings_outlined,
                    size: 20,
                    color: Theme.of(context).iconTheme.color,
                  ),
                  title: Text(
                    'Settings',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  onTap: () {
                    Navigator.of(context).push(AppRoutes.fadeSlide(SettingsPage(
                      bikeName: bikeName,
                      bikeType: bikeType,
                      chosenSetup: chosenSetup,
                    )));
                  },
                ),
                ListTile(
                  dense: true,
                  leading: Icon(
                    Icons.add_circle_outline,
                    size: 20,
                    color: Theme.of(context).iconTheme.color,
                  ),
                  title: Text(
                    'New Bike',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  onTap: () {
                    if (user != null) {
                      if (isInDrawer) Navigator.of(context).pop();
                      showNewBikeSheet(
                          context, user!, NewBikeMode.newBike);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('No User logged in')));
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
