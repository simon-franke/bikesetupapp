import 'package:bikesetupapp/common/models/command_result.dart';
import 'package:bikesetupapp/common/controllers/operation_controller.dart';
import '../models/strava_auth.dart';
import '../repositories/strava_repository.dart';

class StravaConnectionController extends OperationController {
  StravaConnectionController(this._repository, {bool Function()? canAuthorize})
      : _canAuthorize = canAuthorize;
  final bool Function()? _canAuthorize;
  void _requireAccount() {
    if (_canAuthorize?.call() == false) {
      throw const AppFailure(FailureCode.authenticationFailed);
    }
  }

  final StravaRepository _repository;
  Future<StravaAuth?> getAuth() => _repository.getAuth();
  Future<CommandResult<StravaAuth>> authorize() => share(
      'authorize',
      () => command(() async {
            _requireAccount();
            final auth = await _repository.authorize();
            if (auth == null || isDisposed) throw const CommandAborted();
            return auth;
          }));
  Future<CommandResult<void>> deauthorize() => command(_repository.deauthorize);
  Future<DateTime?> getLastSyncTime() => _repository.getLastSyncTime();
  Future<double?> mileageAtDate(
      {required String gearId,
      required DateTime date,
      required double currentTotalKm}) async {
    return _repository.fetchMileageAtDate(
        gearId: gearId, date: date, currentTotalKm: currentTotalKm);
  }
}
