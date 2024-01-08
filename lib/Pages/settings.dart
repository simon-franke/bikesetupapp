import 'package:bikesetupapp/Pages/google_sign_in.dart';
import 'package:bikesetupapp/Pages/home_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bikesetupapp/Services/app_state_notifier.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bikesetupapp/Services/auth_service.dart';

class SettingsPage extends StatefulWidget {
  final String bikename;
  final String biketype;
  final String chosensetup;
  const SettingsPage({Key? key, required this.bikename, required this.biketype, required this.chosensetup}) : super(key: key);

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
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
            onPressed: () {
              if (user == null) {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (BuildContext context) => const LoginPage()));
              } else {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (BuildContext context) => MyHomePage(
                          user: user,
                          bikename: widget.bikename,
                          biketype: widget.biketype,
                          chosensetup: widget.chosensetup,
                        )));
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
                  value: Provider.of<AppStateNotifier>(context).isDarkModeOn,
                  onChanged: (boolVal) {
                    Provider.of<AppStateNotifier>(context, listen: false)
                        .updateTheme(boolVal);
                  }),
            ),
          ),
          Card(
            child: ListTile(
              leading: user != null
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
              title: user != null
                  ? Text(
                      '${user?.displayName}',
                      style: Theme.of(context).textTheme.labelLarge,
                    )
                  : Text(
                      'No User',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
              subtitle: user != null
                  ? Text(
                      '${user?.email}',
                      style: Theme.of(context).textTheme.labelSmall,
                    )
                  : Text(
                      'No User logged in',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
              trailing: user != null
                  ? IconButton(
                      icon: Icon(
                        Icons.logout,
                        color: Theme.of(context).iconTheme.color,
                      ),
                      onPressed: () {
                        AuthService().signOut();
                        setState(() {
                          user = null;
                        });
                      },
                    )
                  : IconButton(
                      icon: Icon(
                        Icons.login,
                        color: Theme.of(context).iconTheme.color,
                      ),
                      onPressed: () async {
                        Navigator.of(context).push(MaterialPageRoute(
                            builder: (BuildContext context) =>
                                const LoginPage()));
                      },
                    ),
            ),
          )
        ],
      ),
    );
  }
}
