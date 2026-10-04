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
      double? currentMileageKm}) {
    final key =
        (bikeId, type, name.trim(), serviceIntervalKm, currentMileageKm);
    return share(
        ('createComponent', key),
        () => command(() async {
              if (name.trim().isEmpty || serviceIntervalKm <= 0) {
                throw const AppFailure(FailureCode.invalidInput);
              }
              final (componentId, entryId, date) = _componentDrafts.putIfAbsent(
                  key, () => (_newId(), _newId(), _now().toUtc()));
              final component = ServiceComponent(
                  id: componentId,
                  bikeId: bikeId,
                  type: type,
                  name: name.trim(),
                  serviceIntervalKm: serviceIntervalKm,
                  createdAt: date);
              final baseline = ServiceEntry(
                  id: entryId,
                  componentId: componentId,
                  mileageAtServiceKm: currentMileageKm,
                  date: date,
                  note: 'Initial setup');
              await _repository.createComponentWithBaseline(
                  component, baseline);
              if (isDisposed) throw const CommandAborted();
              _componentDrafts.remove(key);
            }));
  }

  Future<CommandResult<void>> updateComponent(String componentId,
          {String? name, int? serviceIntervalKm}) =>
      command(() => _repository.updateComponent(componentId,
          name: name, serviceIntervalKm: serviceIntervalKm));
  Future<CommandResult<void>> deleteComponent(String componentId) =>
      command(() => _repository.deleteComponent(componentId));
  Future<CommandResult<void>> deleteServiceEntry(
          String componentId, String entryId) =>
      command(() => _repository.deleteServiceEntry(componentId, entryId));

  Future<CommandResult<void>> logService(
          {required String componentId,
          required DateTime date,
          double? mileageAtServiceKm,
          String? note,
          String? entryId}) =>
      command(() => _writeService(
          componentId: componentId,
          date: date,
          mileageAtServiceKm: mileageAtServiceKm,
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
            note: 'Checked — still good for $extendKm km',
            entryId: entryId);
      });

  Future<void> _writeService(
      {required String componentId,
      required DateTime date,
      double? mileageAtServiceKm,
      String? note,
      String? entryId}) {
    final trimmed = note?.trim();
    return _repository.addServiceEntry(
        componentId,
        ServiceEntry(
            id: entryId ?? _newId(),
            componentId: componentId,
            date: date.toUtc(),
            mileageAtServiceKm: mileageAtServiceKm,
            note: trimmed == null || trimmed.isEmpty ? null : trimmed));
  }
}
