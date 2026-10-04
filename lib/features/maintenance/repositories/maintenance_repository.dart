import 'package:bikesetupapp/features/maintenance/models/service_component.dart';
import 'package:bikesetupapp/features/maintenance/models/service_entry.dart';

abstract interface class MaintenanceRepository {
  Stream<List<ServiceComponent>> getComponentsForBike(String bikeId);
  Future<void> createComponentWithBaseline(
      ServiceComponent component, ServiceEntry baseline);
  Future<void> updateComponent(String componentId,
      {String? name, int? serviceIntervalKm});
  Future<void> deleteComponent(String componentId);
  Stream<List<ServiceEntry>> getEntriesForComponent(String componentId);
  Future<void> addServiceEntry(String componentId, ServiceEntry entry);
  Future<void> deleteServiceEntry(String componentId, String entryId);
  Stream<ServiceEntry?> streamLatestEntryForComponent(String componentId);
  Future<ServiceEntry?> getLatestEntryForComponent(String componentId);
}
