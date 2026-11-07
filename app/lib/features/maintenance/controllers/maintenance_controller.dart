import '../models/service_icon.dart';
import 'package:bikesetupapp/common/models/command_result.dart';
import 'package:bikesetupapp/common/controllers/operation_controller.dart';
import 'package:uuid/uuid.dart';
import '../models/component_type.dart';
import '../models/service_component.dart';
import '../models/service_entry.dart';
import '../models/deferred_service.dart';
import '../repositories/maintenance_repository.dart';

class MaintenanceController extends OperationController {
  MaintenanceController(this._repository,
      {String Function()? newId, DateTime Function()? now})
      : _newId = newId ?? const Uuid().v4,
        _now = now ?? DateTime.now;
  final MaintenanceRepository _repository;
  final String Function() _newId;
  final DateTime Function() _now;
  final Map<Object, (String, String, DateTime)> _componentDrafts = {};

  Stream<List<ServiceComponent>> getComponentsForBike(String bikeId) =>
      _repository.getComponentsForBike(bikeId);
  Stream<List<ServiceEntry>> getEntriesForComponent(String componentId) =>
      _repository.getEntriesForComponent(componentId);
  Stream<ServiceEntry?> streamLatestEntryForComponent(String componentId) =>
      _repository.streamLatestEntryForComponent(componentId);

  Future<CommandResult<void>> createComponent(
      {required String bikeId,
      required ComponentType type,
      required String name,
      required int serviceIntervalKm,
      ServiceIcon? customIcon,
      double? currentMileageKm,
      double? serviceIntervalHours,
      double initialRideHours = 0,
      double initialDistanceKm = 0,
      bool includeIndoorRides = false,
      DateTime? baselineDate}) {
    final key = (
      bikeId,
      type,
      name.trim(),
      customIcon,
      serviceIntervalKm,
      currentMileageKm,
      serviceIntervalHours,
      initialRideHours,
      initialDistanceKm,
      includeIndoorRides,
      baselineDate
    );
    return share(
        ('createComponent', key),
        () => command(() async {
              if (name.trim().isEmpty ||
                  !(serviceIntervalHours ?? serviceIntervalKm).isFinite ||
                  (serviceIntervalHours ?? serviceIntervalKm) <= 0 ||
                  !initialRideHours.isFinite ||
                  initialRideHours < 0 ||
                  !initialDistanceKm.isFinite ||
                  initialDistanceKm < 0 ||
                  (baselineDate?.isAfter(_now()) ?? false)) {
                throw const AppFailure(FailureCode.invalidInput);
              }
              final (componentId, entryId, date) = _componentDrafts.putIfAbsent(
                  key, () => (_newId(), _newId(), _now().toUtc()));
              final component = ServiceComponent(
                  id: componentId,
                  bikeId: bikeId,
                  type: type,
                  name: name.trim(),
                  customIcon: customIcon,
                  serviceIntervalKm: serviceIntervalKm,
                  serviceIntervalHours: serviceIntervalHours,
                  includeIndoorRides: includeIndoorRides,
                  createdAt: date);
              final baseline = ServiceEntry(
                  id: entryId,
                  componentId: componentId,
                  mileageAtServiceKm: currentMileageKm,
                  date: baselineDate?.toUtc() ?? date,
                  initialRideHours:
                      serviceIntervalHours == null ? null : initialRideHours,
                  initialDistanceKm:
                      serviceIntervalHours == null ? initialDistanceKm : null,
                  note: 'Initial setup');
              await _repository.createComponentWithBaseline(
                  component, baseline);
              if (isDisposed) throw const CommandAborted();
              _componentDrafts.remove(key);
            }));
  }

  Future<CommandResult<void>> updateComponent(String componentId,
          {String? name,
          int? serviceIntervalKm,
          double? serviceIntervalHours}) =>
      command(() {
        if ((serviceIntervalHours != null &&
                (!serviceIntervalHours.isFinite ||
                    serviceIntervalHours <= 0)) ||
            (serviceIntervalKm != null && serviceIntervalKm <= 0)) {
          throw const AppFailure(FailureCode.invalidInput);
        }
        return _repository.updateComponent(componentId,
            name: name,
            serviceIntervalKm: serviceIntervalKm,
            serviceIntervalHours: serviceIntervalHours);
      });
  Future<CommandResult<void>> deleteComponent(String componentId) =>
      command(() => _repository.deleteComponent(componentId));
  Future<CommandResult<void>> deleteServiceEntry(
          String componentId, String entryId) =>
      command(() => _repository.deleteServiceEntry(componentId, entryId));

  Future<CommandResult<void>> logService(
          {required String componentId,
          required DateTime date,
          double? mileageAtServiceKm,
          double? initialRideHours,
          String? note,
          String? entryId}) =>
      command(() => _writeService(
          componentId: componentId,
          date: date,
          mileageAtServiceKm: mileageAtServiceKm,
          initialRideHours: initialRideHours,
          note: note,
          entryId: entryId));

  Future<CommandResult<void>> deferService(
          {required ServiceComponent component,
          required double currentMileageKm,
          required int extendKm,
          String? entryId,
          DateTime? date}) =>
      command(() async {
        if (extendKm <= 0 || component.serviceIntervalKm <= 0) {
          throw const AppFailure(FailureCode.invalidInput);
        }
        await _writeService(
            componentId: component.id,
            date: date ?? _now(),
            mileageAtServiceKm: deferredServiceMileage(
                currentMileageKm: currentMileageKm,
                extendKm: extendKm,
                serviceIntervalKm: component.serviceIntervalKm),
            note: 'Checked, still good for $extendKm km',
            entryId: entryId);
      });

  Future<void> _writeService(
      {required String componentId,
      required DateTime date,
      double? mileageAtServiceKm,
      double? initialRideHours,
      String? note,
      String? entryId}) {
    if (initialRideHours != null &&
        (!initialRideHours.isFinite ||
            initialRideHours < 0 ||
            date.isAfter(_now()))) {
      throw const AppFailure(FailureCode.invalidInput);
    }
    final trimmed = note?.trim();
    return _repository.addServiceEntry(
        componentId,
        ServiceEntry(
            id: entryId ?? _newId(),
            componentId: componentId,
            date: date.toUtc(),
            mileageAtServiceKm: mileageAtServiceKm,
            initialRideHours: initialRideHours,
            note: trimmed == null || trimmed.isEmpty ? null : trimmed));
  }
}
