import 'package:bikesetupapp/common/controllers/operation_controller.dart';
import '../models/strava_auth.dart';
import '../repositories/strava_repository.dart';

class StravaConnectionController extends OperationController {
  StravaConnectionController(this._repository);
  final StravaRepository _repository;
  Future<StravaAuth?> getAuth() => _repository.getAuth();
  Future<StravaAuth?> authorize() => run(_repository.authorize);
  Future<void> authorizeWeb() => run(_repository.authorizeWeb);
  Future<void> deauthorize() => run(_repository.deauthorize);
  Future<DateTime?> getLastSyncTime() => _repository.getLastSyncTime();
  Future<double?> mileageAtDate(
      {required String gearId,
      required DateTime date,
      required double currentTotalKm}) async {
    final token = await _repository.getValidToken();
    if (token == null) return null;
    return _repository.fetchMileageAtDate(
        accessToken: token,
        gearId: gearId,
        date: date,
        currentTotalKm: currentTotalKm);
  }
}
