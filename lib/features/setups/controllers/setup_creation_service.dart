import '../models/setup_configuration.dart';
import '../repositories/setups_repository.dart';

/// Creates a complete setup; callers own operation state and notifications.
class SetupCreationService {
  SetupCreationService(this._repository);
  final SetupsRepository _repository;

  Future<void> create(String bikeId, String setupId, String name,
      Map<String, String> information,
      {Map<String, Map<String, String>> values = const {}}) async {
    final configuration = SetupConfiguration.fromInformation(information);
    for (final category in configuration.fields.entries) {
      for (final field in category.value) {
        await _repository.setSetting(field, values[category.key]?[field] ?? '',
            bikeId, category.key, setupId);
      }
    }
    await _repository.createSetupList(bikeId, setupId, name, information);
  }
}
