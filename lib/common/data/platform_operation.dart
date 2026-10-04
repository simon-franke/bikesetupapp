import 'package:flutter/services.dart';
import '../models/command_result.dart';

/// Translate platform adapter failures without hiding programming errors.
Future<T> platformOperation<T>(Future<T> Function() action,
    {required FailureCode fallback}) async {
  try {
    return await action();
  } on PlatformException catch (error, stack) {
    throw AppFailure(fallback, cause: error, stackTrace: stack);
  }
}
