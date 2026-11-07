import 'package:firebase_core/firebase_core.dart';
import '../models/command_result.dart';

/// Translate known SDK failures at the persistence boundary; programming errors propagate.
Future<T> firebaseOperation<T>(Future<T> Function() action,
    {FailureCode fallback = FailureCode.loadFailed}) async {
  try {
    return await action();
  } on FirebaseException catch (error, stack) {
    if ([
      'popup-closed-by-user',
      'cancelled-popup-request',
      'web-context-cancelled',
      'canceled'
    ].contains(error.code)) {
      throw const CommandAborted();
    }

    final code = switch (error.code) {
      'permission-denied' || 'unauthenticated' => FailureCode.permissionDenied,
      'unavailable' || 'network-request-failed' => FailureCode.unavailable,
      'wrong-password' ||
      'user-not-found' ||
      'invalid-credential' ||
      'invalid-email' ||
      'user-mismatch' ||
      'requires-recent-login' =>
        FailureCode.invalidCredentials,
      'email-already-in-use' ||
      'credential-already-in-use' ||
      'account-exists-with-different-credential' =>
        FailureCode.emailInUse,
      'weak-password' => FailureCode.weakPassword,
      'too-many-requests' || 'resource-exhausted' => FailureCode.rateLimited,
      _ => fallback,
    };
    throw AppFailure(code, cause: error, stackTrace: stack);
  }
}

Stream<T> firebaseStream<T>(Stream<T> source) =>
    source.handleError((Object error, StackTrace stack) {
      if (error is FirebaseException) {
        final code = error.code == 'permission-denied'
            ? FailureCode.permissionDenied
            : FailureCode.loadFailed;
        throw AppFailure(code, cause: error, stackTrace: stack);
      }
      Error.throwWithStackTrace(error, stack);
    });
