import 'package:bikesetupapp/common/models/command_result.dart';

class StravaInsufficientScopeException extends AppFailure {
  const StravaInsufficientScopeException()
      : super(FailureCode.insufficientActivityScope);
}

class StravaApiException extends AppFailure {
  const StravaApiException(super.code,
      {super.statusCode, super.cause, super.stackTrace});
}
