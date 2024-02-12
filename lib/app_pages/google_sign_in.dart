import 'package:bikesetupapp/alert_dialogs/auth_alert_dialogs.dart';
import 'package:bikesetupapp/database_service/auth_service.dart';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

const String googleIcon = 'assets/google_icon.png';
const String incognitoIcon = 'assets/incognito.png';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text(
            "Login",
            style: Theme.of(context).textTheme.titleLarge,
          ),
          backgroundColor: Theme.of(context).primaryColor,
        ),
        body: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                    ),
                    onPressed: (() async {
                      final UserCredential userCredential;
                      try {
                        userCredential = await AuthService().signInWithGoogle();
                      } catch (e) {
                        if (!mounted) return;
                        AuthAlerts.generalError(context, 'Error: $e');
                        return;
                      }
                      if (!mounted) {
                        return;
                      }
                      AuthAlerts.handleAuthentication(
                          userCredential, context);
                    }),
                    child: Padding(
                      padding: const EdgeInsets.all(0),
                      child: SizedBox(
                          width: size.width * 0.75,
                          child: ListTile(
                            leading: Padding(
                              padding: const EdgeInsets.all(10),
                              child: Image.asset(googleIcon),
                            ),
                            title: Text(
                              'Sign in with Google',
                              //style: Theme.of(context).textTheme.titleMedium,
                              style: TextStyle(
                                  color: Colors.grey[800],
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold),
                            ),
                          )),
                    )),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 5, bottom: 5),
                child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                    ),
                    onPressed: (() async {
                      final UserCredential userCredential;
                      try {
                        userCredential = await FirebaseAuth.instance.signInAnonymously();
                      } catch (e) {
                        if (!mounted) return;
                        AuthAlerts.generalError(context, 'Error: $e');
                        return;
                      }
                      if (!mounted) {
                        return;
                      }
                      AuthAlerts.handleAuthentication(
                          userCredential, context);
                    }),
                    child: Padding(
                      padding: const EdgeInsets.all(0),
                      child: SizedBox(
                          width: size.width * 0.75,
                          child: ListTile(
                              leading: Padding(
                                padding: const EdgeInsets.all(10),
                                child: Image.asset(incognitoIcon),
                              ),
                              title: Text(
                                'Sign in anonymously',
                                style: TextStyle(
                                    color: Colors.grey[800],
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold),
                              ))),
                    )),
              ),
            ],
          ),
        ));
  }
}
