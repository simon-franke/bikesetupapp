import 'package:bikesetupapp/common/controllers/operation_controller.dart';
import 'package:bikesetupapp/features/bikes/models/bike_type.dart';
import 'package:bikesetupapp/features/setups/models/category.dart';
import 'package:bikesetupapp/features/strava/controllers/strava_controller.dart';
import '../models/active_view.dart';

class WorkspaceController extends OperationController {
  WorkspaceController(
      {required this.bikeName,
      required this.bikeId,
      required this.bikeType,
      required this.setupName,
      required this.setupId,
      StravaController? strava})
      : _strava = strava,
        category = _initialCategory(bikeType);
  final StravaController? _strava;
  String bikeName;
  String bikeId;
  BikeType bikeType;
  String setupName;
  String setupId;
  Category category;
  ActiveView activeView = ActiveView.setup;
  bool serviceAlert = false;
  double? mileageKm;
  int _mileageGeneration = 0;
  static Category _initialCategory(BikeType type) =>
      type.hasShock ? Category.shock : Category.rearTire;

  void selectBike(
      String name, String id, BikeType type, String setup, String setupID) {
    bikeName = name;
    bikeId = id;
    bikeType = type;
    setupName = setup;
    setupId = setupID;
    category = _initialCategory(type);
    mileageKm = null;
    serviceAlert = false;
    emit();
    loadMileage();
  }

  void selectCategory(Category value) {
    category = value;
    emit();
  }

  void selectView(ActiveView value) {
    activeView = value;
    emit();
  }

  void setServiceAlert(bool value) {
    if (serviceAlert == value) return;
    serviceAlert = value;
    emit();
  }

  Future<void> loadMileage() async {
    if (_strava == null || bikeId.isEmpty) return;
    final id = bikeId;
    final generation = ++_mileageGeneration;
    try {
      final mileage = await _strava.getMileageForBike(id);
      if (isDisposed || generation != _mileageGeneration || id != bikeId) {
        return;
      }
      mileageKm = mileage;
    } catch (_) {
      if (isDisposed || generation != _mileageGeneration || id != bikeId) {
        return;
      }
      mileageKm = null;
    }
    emit();
  }
}
