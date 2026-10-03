import 'package:bikesetupapp/features/maintenance/models/service_component.dart';
import 'package:bikesetupapp/features/maintenance/models/service_entry.dart';
import 'package:bikesetupapp/features/maintenance/repositories/maintenance_repository.dart';
import 'package:bikesetupapp/common/controllers/operation_controller.dart';

class MaintenanceController extends OperationController {
  MaintenanceController(this._repository);
  final MaintenanceRepository _repository;
  Stream<List<ServiceComponent>> getComponentsForBike(String bikeId) =>
      _repository.getComponentsForBike(bikeId);
  Future<void> addComponent(ServiceComponent component) =>
      run(() => _repository.addComponent(component));
  Future<void> updateComponent(String componentId,
          {String? name, int? serviceIntervalKm}) =>
      run(() => _repository.updateComponent(componentId,
          name: name, serviceIntervalKm: serviceIntervalKm));
  Future<void> deleteComponent(String componentId) =>
      run(() => _repository.deleteComponent(componentId));
  Stream<List<ServiceEntry>> getEntriesForComponent(String componentId) =>
      _repository.getEntriesForComponent(componentId);
  Future<void> addServiceEntry(String componentId, ServiceEntry entry) =>
      run(() => _repository.addServiceEntry(componentId, entry));
  Future<void> deleteServiceEntry(String componentId, String entryId) =>
      run(() => _repository.deleteServiceEntry(componentId, entryId));
  Stream<ServiceEntry?> streamLatestEntryForComponent(String componentId) =>
      _repository.streamLatestEntryForComponent(componentId);
  Future<ServiceEntry?> getLatestEntryForComponent(String componentId) =>
      _repository.getLatestEntryForComponent(componentId);
}
