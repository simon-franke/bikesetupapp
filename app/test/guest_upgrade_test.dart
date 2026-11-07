import 'package:bikesetupapp/features/auth/repositories/firebase_auth_repository.dart';
import 'package:bikesetupapp/common/models/command_result.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';

class LinkedCredential extends Fake implements UserCredential {
  LinkedCredential(this.linkedUser);

  final User linkedUser;

  @override
  User get user => linkedUser;
}

class Guest extends Fake implements User {
  bool anonymous = true;
  bool conflict = false;
  int links = 0;

  @override
  String get uid => 'guest-with-bikes';
  @override
  bool get isAnonymous => anonymous;

  @override
  Future<UserCredential> linkWithCredential(AuthCredential credential) async {
    links++;
    if (conflict) {
      throw FirebaseAuthException(code: 'credential-already-in-use');
    }
    anonymous = false;
    return LinkedCredential(this);
  }
}

class GuestFirebase extends Fake implements FirebaseAuth {
  GuestFirebase(this.guest);

  final Guest guest;
  int replacements = 0;

  @override
  User get currentUser => guest;

  @override
  Future<UserCredential> signInWithCredential(AuthCredential credential) async {
    replacements++;
    throw StateError('Must link, never replace a guest session');
  }

  @override
  Future<UserCredential> createUserWithEmailAndPassword(
      {required String email, required String password}) async {
    replacements++;
    throw StateError('Must link, never replace a guest session');
  }
}

void main() {
  test('email upgrade keeps the Firebase UID that owns the bikes', () async {
    final guest = Guest();
    final firebase = GuestFirebase(guest);
    final repository = FirebaseAuthRepository(auth: firebase);
    final result =
        await repository.signUpWithEmail('rider@example.com', 'password');
    expect(result.user!.uid, 'guest-with-bikes');
    expect(result.user!.isAnonymous, isFalse);
    expect(guest.links, 1);
    expect(firebase.replacements, 0);
  });
  test(
      'an existing-account collision preserves the guest and reports a recoverable failure',
      () async {
    final guest = Guest()..conflict = true;
    final firebase = GuestFirebase(guest);
    final repository = FirebaseAuthRepository(auth: firebase);
    await expectLater(
        repository.signUpWithEmail('existing@example.com', 'password'),
        throwsA(isA<AppFailure>().having(
            (failure) => failure.code, 'code', FailureCode.emailInUse)));
    expect(repository.currentUser!.uid, 'guest-with-bikes');
    expect(repository.currentUser!.isAnonymous, isTrue);
    expect(firebase.replacements, 0);
  });
}
