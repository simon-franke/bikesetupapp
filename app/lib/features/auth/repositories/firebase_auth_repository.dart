import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:bikesetupapp/common/data/firebase_operation.dart';
import 'package:bikesetupapp/common/models/command_result.dart';
import 'auth_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;
import 'package:google_sign_in/google_sign_in.dart';

class FirebaseAuthRepository implements AuthRepository, AuthSessionEvents {
  FirebaseAuthRepository(
      {FirebaseAuth? auth,
      GoogleSignIn? googleSignIn,
      this.beforeAccountDeletion,
      http.Client? client})
      : _client = client,
        _auth = auth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn.instance;
  final http.Client? _client;
  final GoogleSignIn _googleSignIn;
  final Future<void> Function()? beforeAccountDeletion;
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
    }
  }

  final FirebaseAuth _auth;
  @override
  Stream<User?> get userChanges => _auth.userChanges();

  Future<UserCredential> _useCredential(AuthCredential credential) {
    final guest = _auth.currentUser;
    return guest?.isAnonymous == true
        ? guest!.linkWithCredential(credential)
        : _auth.signInWithCredential(credential);
  }

  @override
  User? get currentUser => _auth.currentUser;
  @override
  Future<UserCredential> signInAnonymously() =>
      firebaseOperation(() => _auth.signInAnonymously(),
          fallback: FailureCode.authenticationFailed);
  @override
  Future<UserCredential> signInWithGoogle() async {
    return _authentication(() async {
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
      return await _useCredential(credential);
    });
  }

  @override
  Future<UserCredential> signInWithApple() => _authentication(() {
        final provider = AppleAuthProvider()
          ..addScope('email')
          ..addScope('name');
        final guest = _auth.currentUser;
        return guest?.isAnonymous == true
            ? guest!.linkWithProvider(provider)
            : _auth.signInWithProvider(provider);
      });

  @override
  Future<UserCredential> signInWithEmail(String email, String password) async {
    return _authentication(() async {
      return await _useCredential(
          EmailAuthProvider.credential(email: email, password: password));
    });
  }

  @override
  Future<UserCredential> signUpWithEmail(String email, String password) async {
    return _authentication(() async {
      if (_auth.currentUser?.isAnonymous == true) {
        return _useCredential(
            EmailAuthProvider.credential(email: email, password: password));
      }
      return await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
    });
  }

  @override
  Future<void> resetPassword(String email) => _authentication(() async {
        try {
          await _auth.sendPasswordResetEmail(email: email);
        } on FirebaseAuthException catch (error) {
          // Do not disclose whether an address has an account.
          if (error.code != 'user-not-found') rethrow;
        }
      });

  Future<http.Response> _post(Uri uri,
      {required Map<String, String> headers, required String body}) async {
    try {
      return await (_client?.post(uri, headers: headers, body: body) ??
              http.post(uri, headers: headers, body: body))
          .timeout(const Duration(seconds: 60));
    } on TimeoutException {
      throw const AppFailure(FailureCode.accountDeletionFailed);
    } on http.ClientException {
      throw const AppFailure(FailureCode.accountDeletionFailed);
    }
  }

  @override
  Future<void> deleteAccount({String? password}) => _authentication(() async {
        final user = _auth.currentUser;
        if (user == null) {
          throw const AppFailure(FailureCode.authenticationFailed);
        }
        final providers =
            user.providerData.map((provider) => provider.providerId).toSet();
        if (providers.contains('apple.com')) {
          final provider = AppleAuthProvider();
          final credential = await user.reauthenticateWithProvider(provider);
          final applePlatform = (defaultTargetPlatform == TargetPlatform.iOS ||
              defaultTargetPlatform == TargetPlatform.macOS);
          if (applePlatform) {
            final code = credential.additionalUserInfo?.authorizationCode;
            if (code == null || code.isEmpty) {
              throw const AppFailure(FailureCode.accountDeletionFailed);
            }
            await _auth.revokeTokenWithAuthorizationCode(code);
          } else {
            final token = credential.credential?.accessToken;
            if (token == null || token.isEmpty) {
              throw const AppFailure(FailureCode.accountDeletionFailed);
            }
            final response = await _post(
                Uri.https(
                    'identitytoolkit.googleapis.com',
                    '/v2/accounts:revokeToken',
                    {'key': _auth.app.options.apiKey}),
                headers: {'Content-Type': 'application/json'},
                body: jsonEncode({
                  'providerId': 'apple.com',
                  'tokenType': 'ACCESS_TOKEN',
                  'token': token,
                  'idToken': await user.getIdToken(true)
                }));
            if (response.statusCode != 200) {
              throw const AppFailure(FailureCode.accountDeletionFailed);
            }
          }
        } else if (providers.contains('password')) {
          if (password == null || password.isEmpty || user.email == null) {
            throw const AppFailure(FailureCode.invalidCredentials);
          }
          await user.reauthenticateWithCredential(EmailAuthProvider.credential(
              email: user.email!, password: password));
        } else if (providers.contains('google.com')) {
          await _initializeGoogle();
          final google = await _googleSignIn.authenticate();
          await user.reauthenticateWithCredential(GoogleAuthProvider.credential(
              idToken: google.authentication.idToken));
        } else if (!user.isAnonymous) {
          throw const AppFailure(FailureCode.authenticationFailed);
        }
        await beforeAccountDeletion?.call();
        final token = await user.getIdToken(true);
        if (token == null || _auth.currentUser?.uid != user.uid) {
          throw const CommandAborted();
        }
        final response = await _post(
            Uri.parse(
                'https://us-central1-${_auth.app.options.projectId}.cloudfunctions.net/deleteAccount'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json'
            },
            body: '{}');
        if (response.statusCode != 200) {
          throw const AppFailure(FailureCode.accountDeletionFailed);
        }
        await _auth.signOut();
      });

  //Sign Out
  @override
  Future<void> signOut() => firebaseOperation(() => _auth.signOut(),
      fallback: FailureCode.authenticationFailed);
}
