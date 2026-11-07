import 'dart:async';
import 'package:bikesetupapp/common/controllers/write_queue.dart';
import 'package:bikesetupapp/common/models/command_result.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bikesetupapp/common/controllers/operation_controller.dart';
import '../repositories/auth_repository.dart';

class AuthController extends OperationController {
  AuthController(this._repository,
      {void Function()? onSignedOut, Future<void> Function()? onSigningOut})
      : _onSignedOut = onSignedOut,
        _onSigningOut = onSigningOut {
    if (_repository case final AuthSessionEvents events) {
      var previousUid = _repository.currentUser?.uid;
      _subscription = events.userChanges.listen((user) {
        if (previousUid != null && previousUid != user?.uid) {
          _onSignedOut?.call();
        }
        previousUid = user?.uid;
        emit();
      }, onError: (Object error, StackTrace stack) {
        // SDK stream errors are reported; command failures retain their own UI.
        Zone.current.handleUncaughtError(error, stack);
      });
    }
  }
  StreamSubscription<User?>? _subscription;
  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  final void Function()? _onSignedOut;
  final Future<void> Function()? _onSigningOut;
  final AuthRepository _repository;
  final WriteQueue _sessions = WriteQueue();
  Future<CommandResult<T>> _session<T>(
          Object key, Future<T> Function() action) =>
      share(
          key,
          () => command(() => _sessions.enqueue(() {
                if (isDisposed) throw const CommandAborted();
                return action();
              })));
  User? get currentUser => _repository.currentUser;
  Future<CommandResult<UserCredential>> signInWithGoogle() =>
      _session('google', _repository.signInWithGoogle);
  Future<CommandResult<UserCredential>> signInWithApple() =>
      _session('apple', _repository.signInWithApple);
  Future<CommandResult<UserCredential>> signInAnonymously() =>
      _session('anonymous', _repository.signInAnonymously);
  Future<CommandResult<UserCredential>> signInWithEmail(
          String email, String password) =>
      _session(('email', email, password),
          () => _repository.signInWithEmail(email, password));
  Future<CommandResult<UserCredential>> signUpWithEmail(
          String email, String password) =>
      _session(('signup', email, password),
          () => _repository.signUpWithEmail(email, password));
  Future<CommandResult<void>> resetPassword(String email) =>
      _session(('reset', email), () => _repository.resetPassword(email));
  Future<CommandResult<void>> deleteAccount({String? password}) =>
      _session('delete', () async {
        await _repository.deleteAccount(password: password);
        _onSignedOut?.call();
      });
  Future<CommandResult<void>> signOut() => _session('signout', () async {
        await _onSigningOut?.call();
        await _repository.signOut();
        _onSignedOut?.call();
      });
}
