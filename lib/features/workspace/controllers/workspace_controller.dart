import 'package:bikesetupapp/common/models/command_result.dart';
import 'package:bikesetupapp/common/controllers/operation_controller.dart';
import 'package:bikesetupapp/features/strava/controllers/strava_controller.dart';
import '../models/active_view.dart';

class WorkspaceController extends OperationController {
  WorkspaceController(
      {required String bikeName,
      required String bikeId,

      required String setupName,
      required String setupId,
      StravaController? strava})
      : _strava = strava,
        _bikeName = bikeName,
        _bikeId = bikeId,
        _setupName = setupName,
        _setupId = setupId;
  final StravaController? _strava;
  String _bikeName;
  String _bikeId;
  String _setupName;
  String _setupId;
  ActiveView _activeView = ActiveView.setup;
  bool _serviceAlert = false;
  double? _mileageKm;
  String get bikeName => _bikeName;
  String get bikeId => _bikeId;
  String get setupName => _setupName;
  String get setupId => _setupId;
  ActiveView get activeView => _activeView;
  bool get serviceAlert => _serviceAlert;
  double? get mileageKm => _mileageKm;

  Future<CommandResult<void>> selectBike(
      String name, String id, String setup, String setupID) {
    _bikeName = name;
    _bikeId = id;
    _setupName = setup;
    _setupId = setupID;
    _mileageKm = null;
    _serviceAlert = false;
    emit();
    return loadMileage();
  }

  void selectView(ActiveView value) {
    _activeView = value;
    emit();
  }

  void setServiceAlert(bool value) {
    if (_serviceAlert == value) return;
    _serviceAlert = value;
    emit();
  }

  Future<CommandResult<void>> loadMileage() => command(() async {
        final generation = beginRequest('mileage');
        if (_strava == null || _bikeId.isEmpty) return;
        final mileage = await _strava.getMileageForBike(_bikeId);
        if (!isCurrentRequest('mileage', generation)) {
          throw const CommandAborted();
        }
        _mileageKm = mileage;
        emit();
      });
}
