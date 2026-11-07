import 'dart:async';
import 'package:bikesetupapp/features/auth/repositories/auth_repository.dart';
import 'package:bikesetupapp/common/models/command_result.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';

class SessionUser extends Fake implements User {
  SessionUser({this.id = 'user', this.guest = false});
  final String id;
  final bool guest;
  @override
  String get uid => id;
  @override
  bool get isAnonymous => guest;
  @override
  String? get displayName => null;
  @override
  String? get email => guest ? null : 'rider@example.com';
  @override
  String? get photoURL => null;
  @override
  List<UserInfo> get providerData => guest ? [] : [PasswordProvider()];
}

class PasswordProvider extends Fake implements UserInfo {
  @override
  String get providerId => 'password';
}

class SessionCredential extends Fake implements UserCredential {}

class FakeAuthRepository extends Fake
    implements AuthRepository, AuthSessionEvents {
  User? user;
  bool failSignOut = false;
  bool failSignIn = false;
  bool failDeletion = false;
  String? resetEmail;
  @override
  Future<void> resetPassword(String email) async {
    resetEmail = email;
  }

  @override
  Future<void> deleteAccount({String? password}) async {
    if (failDeletion) throw const AppFailure(FailureCode.accountDeletionFailed);
    if (password != 'password') {
      throw const AppFailure(FailureCode.invalidCredentials);
    }
    setUser(null);
  }

  final events = StreamController<User?>.broadcast();
  @override
  User? get currentUser => user;
  @override
  Stream<User?> get userChanges => events.stream;
  void setUser(User? value) {
    user = value;
    events.add(value);
  }

  @override
  Future<UserCredential> signInAnonymously() async {
    setUser(SessionUser(guest: true));
    return SessionCredential();
  }

  @override
  Future<UserCredential> signInWithEmail(String email, String password) async {
    if (failSignIn) throw const AppFailure(FailureCode.invalidCredentials);
    setUser(SessionUser());
    return SessionCredential();
  }

  @override
  Future<UserCredential> signUpWithEmail(String email, String password) =>
      signInWithEmail(email, password);
  @override
  Future<void> signOut() async {
    if (failSignOut) throw const AppFailure(FailureCode.unavailable);
    setUser(null);
  }
}
