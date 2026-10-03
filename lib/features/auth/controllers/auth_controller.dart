import 'package:firebase_auth/firebase_auth.dart';
import 'package:bikesetupapp/common/controllers/operation_controller.dart';
import '../repositories/auth_repository.dart';

class AuthController extends OperationController {
  AuthController(this._repository, {void Function()? onSignedOut})
      : _onSignedOut = onSignedOut;
  final void Function()? _onSignedOut;
  final AuthRepository _repository;
  User? get currentUser => _repository.currentUser;
  Future<UserCredential> signInWithGoogle() =>
      run(_repository.signInWithGoogle);
  Future<UserCredential> signInWithApple() => run(_repository.signInWithApple);
  Future<UserCredential> signInAnonymously() =>
      run(_repository.signInAnonymously);
  Future<UserCredential> signInWithEmail(String email, String password) =>
      run(() => _repository.signInWithEmail(email, password));
  Future<UserCredential> signUpWithEmail(String email, String password) =>
      run(() => _repository.signUpWithEmail(email, password));
  Future<void> signOut() => run(() async {
        await _repository.signOut();
        _onSignedOut?.call();
      });
}
