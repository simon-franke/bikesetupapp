import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  signInWithGoogle() async {
    if (kIsWeb) {
      return await FirebaseAuth.instance
          .signInWithPopup(GoogleAuthProvider());
    }

    // Trigger the authentication flow
    final GoogleSignInAccount googleUser =
        await GoogleSignIn.instance.authenticate();

    // Obtain the auth details from the request
    final GoogleSignInAuthentication googleAuth = googleUser.authentication;

    // Create a new credential
    final credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
    );

    // Once signed in, return the UserCredential
    return await FirebaseAuth.instance.signInWithCredential(credential);
  }

  //Sign Out
  signOut() {
    FirebaseAuth.instance.signOut();
  }
}
