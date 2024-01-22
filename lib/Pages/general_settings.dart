import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class GeneralSettings extends StatefulWidget {
  final User user;
  final String bikename;
  final String setupname;
  const GeneralSettings(
      {super.key,
      required this.user,
      required this.bikename,
      required this.setupname});

  @override
  State<GeneralSettings> createState() => _GeneralSettingsState();
}

class _GeneralSettingsState extends State<GeneralSettings> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Theme.of(context).iconTheme.color,
            ),
          ),
        ),
        body: const Text('General Settings') //TODO: Implement General Settings
        );
  }
}
