import 'package:bikesetupapp/alert_dialogs/auth_alert_dialogs.dart';
import 'package:bikesetupapp/alert_dialogs/bike_alert_dialogs.dart';
import 'package:bikesetupapp/app_pages/google_sign_in.dart';
import 'package:bikesetupapp/app_services/app_routes.dart';
import 'package:bikesetupapp/app_services/app_state_notifier.dart';
import 'package:bikesetupapp/bike_enums/bike_type.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bikesetupapp/database_service/auth_service.dart';

class SettingsPage extends StatefulWidget {
  final String bikeName;
  final BikeType bikeType;
  final String chosenSetup;
  const SettingsPage({
    super.key,
    required this.bikeName,
    required this.bikeType,
    required this.chosenSetup,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  User? user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
            onPressed: () {
              if (user == null) {
                Navigator.of(context)
                    .push(AppRoutes.fadeSlide(const LoginPage()));
              } else {
                Navigator.of(context).pop();
              }
            },
            icon: const Icon(Icons.arrow_back)),
        title: Text(
          'App Settings',
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
      body: ListView(
        children: [
          Card(
            child: ListTile(
              title: Text(
                'Theme',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              trailing: Switch(
                  activeThumbColor: Colors.grey,
                  value: Provider.of<AppStateNotifier>(context).isDarkModeOn,
                  onChanged: (boolVal) {
                    Provider.of<AppStateNotifier>(context, listen: false)
                        .updateTheme(boolVal);
                  }),
            ),
          ),
          Card(
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
              title: user != null && user!.displayName != null
                  ? Text(
                      '${user?.displayName}',
                      style: Theme.of(context).textTheme.labelLarge,
                    )
                  : Text(
                      user != null ? 'Anonymous' : 'No User',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
              subtitle: user != null && user!.email != null
                  ? Text(
                      '${user?.email}',
                      style: Theme.of(context).textTheme.labelSmall,
                    )
                  : null,
              trailing: user != null
                  ? IconButton(
                      icon: Icon(
                        Icons.logout,
                        color: Theme.of(context).iconTheme.color,
                      ),
                      onPressed: () async {
                        if (user != null && user!.isAnonymous) {
                          bool? wantsToSignOut =
                              await AuthAlerts.signOutAnonymous(context, user!);
                          if (wantsToSignOut == null || !wantsToSignOut) {
                            return;
                          }
                        }
                        AuthService().signOut();
                        setState(() {
                          user = null;
                        });
                      })
                  : IconButton(
                      icon: Icon(
                        Icons.login,
                        color: Theme.of(context).iconTheme.color,
                      ),
                      onPressed: () async {
                        Navigator.of(context)
                            .push(AppRoutes.fadeSlide(const LoginPage()));
                      },
                    ),
            ),
          ),
          Visibility(
              visible: user != null,
              child: Card(
                  child: ListTile(
                      title: Text(
                        'Select default Bike',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      trailing: IconButton(
                        onPressed: () {
                          BikeAlerts.selectDefaultBike(context, user!, size);
                        },
                        icon: Icon(Icons.tune,
                            color: Theme.of(context).textTheme.labelMedium !=
                                    null
                                ? Theme.of(context).textTheme.labelMedium!.color
                                : Colors.white),
                      ))))
        ],
      ),
    );
  }
}
