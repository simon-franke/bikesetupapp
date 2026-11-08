import 'package:bikesetupapp/common/models/command_result.dart';
import 'package:bikesetupapp/common/ui/failure_message.dart';

String authFailureMessage(AppFailure failure, bool upgrade) => upgrade &&
        failure.code == FailureCode.emailInUse
    ? 'That account already exists. Your guest bikes are still here. Use a different account to save them.'
    : failureMessage(failure);
