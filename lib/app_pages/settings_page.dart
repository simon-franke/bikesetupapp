import 'package:bikesetupapp/alert_dialogs/auth_alert_dialogs.dart';
import 'package:bikesetupapp/app_pages/bike_matching_page.dart';
import 'package:bikesetupapp/app_pages/google_sign_in.dart';
import 'package:bikesetupapp/app_services/app_routes.dart';
import 'package:bikesetupapp/app_services/app_state_notifier.dart';
import 'package:bikesetupapp/app_services/strava_token_storage.dart';
import 'package:bikesetupapp/bike_enums/bike_type.dart';
import 'package:bikesetupapp/database_service/service_database.dart';
import 'package:bikesetupapp/database_service/strava_auth_service.dart';

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
  bool _isStravaConnected = false;
  int? _stravaAthleteId;

  @override
  void initState() {
    super.initState();
    _checkStravaConnection();
  }

  Future<void> _checkStravaConnection() async {
    final auth = await StravaTokenStorage.getAuth();
    if (mounted) {
      setState(() {
        _isStravaConnected = auth != null;
        _stravaAthleteId = auth?.athleteId;
      });
    }
  }

  Future<void> _connectStrava() async {
    final auth = await StravaAuthService().authorize();
    if (auth != null && mounted) {
      setState(() {
        _isStravaConnected = true;
        _stravaAthleteId = auth.athleteId;
      });
    }
  }

  Future<void> _disconnectStrava() async {
    await StravaAuthService().deauthorize();
    if (user != null) {
      await ServiceDatabaseService(user!.uid).deleteAllStravaBikes();
    }
    if (mounted) {
      setState(() {
        _isStravaConnected = false;
        _stravaAthleteId = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Theme',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 10),
                  SegmentedButton<ThemeMode>(
                    segments: const [
                      ButtonSegment(
                        value: ThemeMode.light,
                        icon: Icon(Icons.light_mode),
                        label: Text('Light'),
                      ),
                      ButtonSegment(
                        value: ThemeMode.system,
                        icon: Icon(Icons.brightness_auto),
                        label: Text('System'),
                      ),
                      ButtonSegment(
                        value: ThemeMode.dark,
                        icon: Icon(Icons.dark_mode),
                        label: Text('Dark'),
                      ),
                    ],
                    selected: {Provider.of<AppStateNotifier>(context).themeMode},
                    onSelectionChanged: (selection) {
                      Provider.of<AppStateNotifier>(context, listen: false)
                          .updateTheme(selection.first);
                    },
                  ),
                ],
              ),
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
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Strava',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 10),
                  if (_isStravaConnected) ...[
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFC4C02),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.directions_bike,
                          size: 20,
                          color: Colors.white,
                        ),
                      ),
                      title: Text(
                        'Connected',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      subtitle: _stravaAthleteId != null
                          ? Text(
                              'Athlete ID: $_stravaAthleteId',
                              style: Theme.of(context).textTheme.labelSmall,
                            )
                          : null,
                      trailing: TextButton(
                        onPressed: _disconnectStrava,
                        child: const Text(
                          'Disconnect',
                          style: TextStyle(color: Color(0xFFE05545)),
                        ),
                      ),
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.sync_alt, size: 20),
                      title: Text(
                        'Manage Strava bikes',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      trailing: const Icon(Icons.chevron_right, size: 20),
                      onTap: () {
                        if (user != null) {
                          Navigator.of(context).push(
                            AppRoutes.fadeSlide(
                                BikeMatchingPage(user: user!)),
                          );
                        }
                      },
                    ),
                  ] else
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFC4C02),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: _connectStrava,
                        icon: const Icon(Icons.directions_bike, size: 20),
                        label: const Text('Connect Strava'),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
