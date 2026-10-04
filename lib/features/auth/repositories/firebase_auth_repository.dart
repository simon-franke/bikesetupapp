import 'package:bikesetupapp/common/data/firebase_operation.dart';
import 'package:bikesetupapp/common/models/command_result.dart';
import 'auth_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({FirebaseAuth? auth, GoogleSignIn? googleSignIn})
      : _auth = auth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn.instance;
  final GoogleSignIn _googleSignIn;
  static Future<void>? _googleInitialization;
  Future<void>? _injectedGoogleInitialization;

  Future<void> _initializeGoogle() {
    if (identical(_googleSignIn, GoogleSignIn.instance)) {
      return _googleInitialization ??= _googleSignIn.initialize();
    }
    return _injectedGoogleInitialization ??= _googleSignIn.initialize();
  }

  Future<T> _authentication<T>(Future<T> Function() action) async {
    try {
      return await firebaseOperation(action,
          fallback: FailureCode.authenticationFailed);
    } on GoogleSignInException catch (error, stack) {
      if (error.code == GoogleSignInExceptionCode.canceled) {
        throw const CommandAborted();
      }
      throw AppFailure(FailureCode.authenticationFailed,
          cause: error, stackTrace: stack);
    } on SignInWithAppleAuthorizationException catch (error, stack) {
      if (error.code == AuthorizationErrorCode.canceled) {
        throw const CommandAborted();
      }
      throw AppFailure(FailureCode.authenticationFailed,
          cause: error, stackTrace: stack);
    }
  }

  final FirebaseAuth _auth;
  @override
  User? get currentUser => _auth.currentUser;
  @override
  Future<UserCredential> signInAnonymously() =>
      firebaseOperation(() => _auth.signInAnonymously(),
          fallback: FailureCode.authenticationFailed);
  @override
  Future<UserCredential> signInWithGoogle() async {
    return _authentication(() async {
      if (kIsWeb) {
        return await _auth.signInWithPopup(GoogleAuthProvider());
      }

      await _initializeGoogle();
      // Trigger the authentication flow
      final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      // Once signed in, return the UserCredential
      return await _auth.signInWithCredential(credential);
    });
  }

  @override
  Future<UserCredential> signInWithApple() async {
    return _authentication(() async {
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
    });
  }

  @override
  Future<UserCredential> signInWithEmail(String email, String password) async {
    return _authentication(() async {
      return await _auth.signInWithEmailAndPassword(
          email: email, password: password);
    });
  }

  @override
  Future<UserCredential> signUpWithEmail(String email, String password) async {
    return _authentication(() async {
      return await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
    });
  }

  //Sign Out
  @override
  Future<void> signOut() => firebaseOperation(() => _auth.signOut(),
      fallback: FailureCode.authenticationFailed);
}
