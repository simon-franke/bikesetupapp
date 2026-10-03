import 'setting_save_controller.dart';
import 'package:bikesetupapp/features/setups/models/bike_setup.dart';
import 'package:bikesetupapp/features/setups/repositories/setups_repository.dart';
import 'package:bikesetupapp/common/controllers/operation_controller.dart';
import 'package:bikesetupapp/features/setups/models/category.dart';

class SetupsController extends OperationController {
  SetupsController(this._repository);
  final SetupsRepository _repository;
  final Map<(String, String, String, String), SettingWriteQueue> _writes = {};

  Future<void> createSetup(
    String uBikeID,
    String uSetupID,
    String setupName,
    Map<String, String> setupInformation,
  ) =>
      run(() async {
        await createFork(uBikeID, uSetupID);
        await createShock(uBikeID, uSetupID,
            shockType: setupInformation['shock'] ?? 'Air');
        await createFrontTire(uBikeID, uSetupID);
        await createRearTire(uBikeID, uSetupID);
        await createGeneralSettings(uBikeID, uSetupID);
        await createSetupList(uBikeID, uSetupID, setupName, setupInformation);
      });
  Future<void> createFork(String uBikeID, String uSetupID) async {
    await setSetting(
        'Pressure', '90', uBikeID, Category.fork.category, uSetupID);
    await setSetting('Rebound', '5', uBikeID, Category.fork.category, uSetupID);
    await setSetting(
        'Compression', '8', uBikeID, Category.fork.category, uSetupID);
    await setSetting('Tokens', '2', uBikeID, Category.fork.category, uSetupID);
  }

  Future<void> createShock(String uBikeID, String uSetupID,
      {String shockType = 'Air'}) async {
    if (shockType == 'Coil') {
      await setSetting(
          'Preload', '0', uBikeID, Category.shock.category, uSetupID);
      await setSetting(
          'Spring Rate', '450', uBikeID, Category.shock.category, uSetupID);
    } else {
      await setSetting(
          'Pressure', '180', uBikeID, Category.shock.category, uSetupID);
      await setSetting(
          'Tokens', '0', uBikeID, Category.shock.category, uSetupID);
    }
    await setSetting(
        'Rebound', '5', uBikeID, Category.shock.category, uSetupID);
    await setSetting(
        'Compression', '8', uBikeID, Category.shock.category, uSetupID);
  }

  Future<void> createFrontTire(String uBikeID, String uSetupID) async {
    await setSetting(
        'Pressure', '26', uBikeID, Category.frontTire.category, uSetupID);
  }

  Future<void> createRearTire(String uBIkeID, String uSetupID) async {
    await setSetting(
        'Pressure', '26', uBIkeID, Category.rearTire.category, uSetupID);
  }

  Future<void> createGeneralSettings(String uBikeID, String uSetupID) async {
    await setSetting(
        'Reach', '450mm', uBikeID, Category.generalSettings.category, uSetupID);
    await setSetting('Stack Height', '20mm', uBikeID,
        Category.generalSettings.category, uSetupID);
    await setSetting('Seat Height', '35mm', uBikeID,
        Category.generalSettings.category, uSetupID);
  }

  Future<void> createSetupList(String uBikeID, String uSetupID,
          String setupName, Map<String, dynamic> setupInformation) =>
      run(() => _repository.createSetupList(
          uBikeID, uSetupID, setupName, setupInformation));
  Future<void> setDefaultSetup(String uBikeID, String uSetupID) =>
      run(() => _repository.setDefaultSetup(uBikeID, uSetupID));
  Future<void> setSetting(String key, String value, String uBikeID,
          String category, String uSetupID) =>
      run(() => _writes.putIfAbsent((
            uBikeID,
            uSetupID,
            category,
            key
          ), SettingWriteQueue.new).enqueue(() =>
              _repository.setSetting(key, value, uBikeID, category, uSetupID)));
  Future<void> editSetting(String key, String value, String uBikeID,
          String category, String uSetupID) =>
      run(() =>
          _repository.editSetting(key, value, uBikeID, category, uSetupID));
  Future<void> deleteSetup(String uBikeID, String uSetupID) =>
      run(() => _repository.deleteSetup(uBikeID, uSetupID));
  Future<void> deleteSetting(
          String key, String uBikeID, String category, String uSetupID) =>
      run(() => _repository.deleteSetting(key, uBikeID, category, uSetupID));
  Future<void> setSettingMeta(String key, String familyName, String uBikeID,
          String category, String uSetupID) =>
      run(() => _repository.setSettingMeta(
          key, familyName, uBikeID, category, uSetupID));
  Future<void> deleteSettingMeta(
          String key, String uBikeID, String category, String uSetupID) =>
      run(() =>
          _repository.deleteSettingMeta(key, uBikeID, category, uSetupID));
  Stream<Map<String, dynamic>> getSettingsMeta(
          String uBikeID, String category, String uSetupID) =>
      _repository.getSettingsMeta(uBikeID, category, uSetupID);
  Stream<Map<String, dynamic>> getSettings(
          String uBikeID, String category, String uSetupID) =>
      _repository.getSettings(uBikeID, category, uSetupID);
  Stream<List<BikeSetup>> getSetups(String uBikeID) =>
      _repository.getSetups(uBikeID);
  Stream<Map<String, dynamic>> getDocumentElement(
          String uBikeID, String category, String uSetupID) =>
      _repository.getDocumentElement(uBikeID, category, uSetupID);
  Future<String> getDefaultSetup(String uBikeID) =>
      _repository.getDefaultSetup(uBikeID);
  Future<String> getSetupNameFromID(String uBikeID, String uSetupID) =>
      _repository.getSetupNameFromID(uBikeID, uSetupID);
  Future<Map<String, dynamic>> getSetupInformation(
          String uBikeID, String uSetupID) =>
      _repository.getSetupInformation(uBikeID, uSetupID);
  Future<Map<String, dynamic>> getSetupInformationAsMap(
          String uBikeID, String uSetupID) =>
      _repository.getSetupInformationAsMap(uBikeID, uSetupID);
}
