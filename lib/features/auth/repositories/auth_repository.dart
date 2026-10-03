import 'package:firebase_auth/firebase_auth.dart';

abstract interface class AuthRepository {
  User? get currentUser;
  Future<UserCredential> signInWithGoogle();
  Future<UserCredential> signInWithApple();
  Future<UserCredential> signInWithEmail(String email, String password);
  Future<UserCredential> signUpWithEmail(String email, String password);
  Future<UserCredential> signInAnonymously();
  Future<void> signOut();
}
