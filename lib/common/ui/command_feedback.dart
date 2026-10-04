import 'package:flutter/material.dart';
import '../models/command_result.dart';
import 'failure_message.dart';

/// Presentation boundary: expected failures get messages; unexpected failures
/// retain their exception/stack in Flutter's error reporting and controller state.
Future<bool> presentCommand<T>(
    BuildContext context, Future<CommandResult<T>> Function() action,
    {String fallback = 'Something went wrong. Try again.'}) async {
  try {
    final result = await action();
    if (!context.mounted) return false;
    final failure = result.failure;
    if (failure != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(failureMessage(failure)),
          duration: const Duration(seconds: 8)));
    }
    return result.isSuccess;
  } catch (error, stack) {
    FlutterError.reportError(FlutterErrorDetails(
        exception: error, stack: stack, library: 'controller command'));
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(fallback)));
    }
    return false;
  }
}
