import 'dart:async';
import 'package:bikesetupapp/features/auth/repositories/firebase_auth_repository.dart';
import 'package:bikesetupapp/features/auth/controllers/auth_controller.dart';
import 'package:bikesetupapp/features/auth/repositories/auth_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';

class FakeGoogleAccount extends Fake implements GoogleSignInAccount {
  @override
  GoogleSignInAuthentication get authentication =>
      const GoogleSignInAuthentication(idToken: 'google-token');
}

class FakeGoogle extends Fake implements GoogleSignIn {
  final initialized = Completer<void>();
  int initializations = 0;
  int authentications = 0;
  @override
  Future<void> initialize(
      {String? clientId,
      String? serverClientId,
      String? nonce,
      String? hostedDomain}) {
    initializations++;
    return initialized.future;
  }

  @override
  Future<GoogleSignInAccount> authenticate(
      {List<String> scopeHint = const []}) async {
    authentications++;
    expect(initialized.isCompleted, isTrue);
    return FakeGoogleAccount();
  }
}

class FakeCredential extends Fake implements UserCredential {}

class FakeFirebaseAuth extends Fake implements FirebaseAuth {
  @override
  Future<UserCredential> signInWithCredential(
          AuthCredential credential) async =>
      FakeCredential();
}

class SignOutRepository extends Fake implements AuthRepository {
  final List<String> events;
  SignOutRepository(this.events);
  @override
  Future<void> signOut() async {
    events.add('firebase-sign-out');
  }
}

void main() {
  test(
      'native Google initialization completes before authentication and runs once',
      () async {
    final google = FakeGoogle();
    final repository =
        FirebaseAuthRepository(auth: FakeFirebaseAuth(), googleSignIn: google);
    final signIn = repository.signInWithGoogle();
    expect(google.initializations, 1);
    expect(google.authentications, 0);
    google.initialized.complete();
    await signIn;
    await repository.signInWithGoogle();
    expect(google.initializations, 1);
    expect(google.authentications, 2);
  });
  test(
      'sign-out clears active connection before Firebase user and controller cache',
      () async {
    final events = <String>[];
    final gate = Completer<void>();
    final auth = AuthController(SignOutRepository(events),
        onSigningOut: () async {
          events.add('clear-strava');
          await gate.future;
        },
        onSignedOut: () => events.add('dispose-users'));
    final signOut = auth.signOut();
    await Future<void>.delayed(Duration.zero);
    expect(events, ['clear-strava']);
    gate.complete();
    await signOut;
    expect(events, ['clear-strava', 'firebase-sign-out', 'dispose-users']);
    auth.dispose();
  });
}
