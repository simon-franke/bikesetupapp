import 'package:bikesetupapp/common/models/command_result.dart';
import 'setting_save_controller.dart';
import 'package:bikesetupapp/features/setups/models/bike_setup.dart';
import 'package:bikesetupapp/features/setups/repositories/setups_repository.dart';
import 'package:bikesetupapp/common/controllers/operation_controller.dart';
import 'setup_creation_service.dart';

class SetupsController extends OperationController {
  SetupsController(this._repository);
  final SetupsRepository _repository;
  final Map<(String, String, String, String), SettingWriteQueue> _writes = {};

  Future<CommandResult<void>> createSetup(
    String uBikeID,
    String uSetupID,
    String setupName,
    Map<String, String> setupInformation,
  ) =>
      command(() => SetupCreationService(_repository)
          .create(uBikeID, uSetupID, setupName, setupInformation));
  Future<CommandResult<void>> setSetting(String key, String value,
          String uBikeID, String category, String uSetupID) =>
      command(() => _writes.putIfAbsent((uBikeID, uSetupID, category, key),
              SettingWriteQueue.new).enqueue(() {
            if (isDisposed) throw const CommandAborted();
            return _repository.setSetting(
                key, value, uBikeID, category, uSetupID);
          }));
  Future<CommandResult<void>> deleteSetup(String uBikeID, String uSetupID) =>
      command(() => _repository.deleteSetup(uBikeID, uSetupID));
  Future<CommandResult<void>> addField(
          String key, String value, String bike, String category, String setup,
          {String? familyName}) =>
      command(() async {
        await _repository.setSetting(key, value, bike, category, setup);
        if (familyName != null) {
          await _repository.setSettingMeta(
              key, familyName, bike, category, setup);
        }
      });
  Future<CommandResult<void>> deleteField(
          String key, String bike, String category, String setup) =>
      command(() async {
        await _repository.deleteSetting(key, bike, category, setup);
        await _repository.deleteSettingMeta(key, bike, category, setup);
      });
  Stream<Map<String, dynamic>> getSettingsMeta(
          String uBikeID, String category, String uSetupID) =>
      _repository.getSettingsMeta(uBikeID, category, uSetupID);
  Stream<Map<String, dynamic>> getSettings(
          String uBikeID, String category, String uSetupID) =>
      _repository.getSettings(uBikeID, category, uSetupID);
  Stream<List<BikeSetup>> getSetups(String uBikeID) =>
      _repository.getSetups(uBikeID);
  Future<String> getDefaultSetup(String uBikeID) =>
      _repository.getDefaultSetup(uBikeID);
  Future<String> getSetupNameFromID(String uBikeID, String uSetupID) =>
      _repository.getSetupNameFromID(uBikeID, uSetupID);
  Future<Map<String, dynamic>> getSetupInformation(
          String uBikeID, String uSetupID) =>
      _repository.getSetupInformation(uBikeID, uSetupID);
}
