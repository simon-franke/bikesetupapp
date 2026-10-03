import 'auth_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({FirebaseAuth? auth})
      : _auth = auth ?? FirebaseAuth.instance;
  final FirebaseAuth _auth;
  @override
  User? get currentUser => _auth.currentUser;
  @override
  Future<UserCredential> signInAnonymously() => _auth.signInAnonymously();
  @override
  Future<UserCredential> signInWithGoogle() async {
    if (kIsWeb) {
      return await _auth.signInWithPopup(GoogleAuthProvider());
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
    return await _auth.signInWithCredential(credential);
  }

  @override
  Future<UserCredential> signInWithApple() async {
    if (kIsWeb) {
      return await _auth.signInWithPopup(OAuthProvider('apple.com'));
    }

    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
    );

    final oauthCredential = OAuthProvider('apple.com').credential(
      idToken: appleCredential.identityToken,
      accessToken: appleCredential.authorizationCode,
    );

    return await _auth.signInWithCredential(oauthCredential);
  }

  @override
  Future<UserCredential> signInWithEmail(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
        email: email, password: password);
  }

  @override
  Future<UserCredential> signUpWithEmail(String email, String password) async {
    return await _auth.createUserWithEmailAndPassword(
        email: email, password: password);
  }

  //Sign Out
  @override
  Future<void> signOut() => _auth.signOut();
}
