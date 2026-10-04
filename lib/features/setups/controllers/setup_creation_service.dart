import '../models/setup_defaults.dart';
import '../repositories/setups_repository.dart';

/// Creates a complete setup; callers own operation state and notifications.
class SetupCreationService {
  SetupCreationService(this._repository);
  final SetupsRepository _repository;

  Future<void> create(String bikeId, String setupId, String name,
      Map<String, String> information) async {
    final defaults = SetupDefaults.forShock(information['shock'] ?? 'Air');
    for (final category in defaults.entries) {
      for (final field in category.value.entries) {
        await _repository.setSetting(
            field.key, field.value, bikeId, category.key.category, setupId);
      }
    }
    await _repository.createSetupList(bikeId, setupId, name, information);
  }
}
