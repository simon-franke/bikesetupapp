import 'package:bikesetupapp/common/models/command_result.dart';
import 'package:bikesetupapp/common/controllers/operation_controller.dart';
import 'package:bikesetupapp/features/bikes/models/bike_type.dart';
import 'package:bikesetupapp/features/setups/models/category.dart';
import 'package:bikesetupapp/features/strava/controllers/strava_controller.dart';
import '../models/active_view.dart';

class WorkspaceController extends OperationController {
  WorkspaceController(
      {required String bikeName,
      required String bikeId,
      required BikeType bikeType,
      required String setupName,
      required String setupId,
      StravaController? strava})
      : _strava = strava,
        _bikeName = bikeName,
        _bikeId = bikeId,
        _bikeType = bikeType,
        _setupName = setupName,
        _setupId = setupId,
        _category = _initialCategory(bikeType);
  final StravaController? _strava;
  String _bikeName;
  String _bikeId;
  BikeType _bikeType;
  String _setupName;
  String _setupId;
  Category _category;
  ActiveView _activeView = ActiveView.setup;
  bool _serviceAlert = false;
  double? _mileageKm;
  String get bikeName => _bikeName;
  String get bikeId => _bikeId;
  BikeType get bikeType => _bikeType;
  String get setupName => _setupName;
  String get setupId => _setupId;
  Category get category => _category;
  ActiveView get activeView => _activeView;
  bool get serviceAlert => _serviceAlert;
  double? get mileageKm => _mileageKm;
  static Category _initialCategory(BikeType type) =>
      type.hasShock ? Category.shock : Category.rearTire;

  Future<CommandResult<void>> selectBike(
      String name, String id, BikeType type, String setup, String setupID) {
    _bikeName = name;
    _bikeId = id;
    _bikeType = type;
    _setupName = setup;
    _setupId = setupID;
    _category = _initialCategory(type);
    _mileageKm = null;
    _serviceAlert = false;
    emit();
    return loadMileage();
  }

  void selectCategory(Category value) {
    _category = value;
    emit();
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
