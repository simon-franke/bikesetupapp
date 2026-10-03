import 'package:bikesetupapp/features/setups/models/bike_setup.dart';

abstract interface class SetupsRepository {
  Future<void> createSetupList(String uBikeID, String uSetupID,
      String setupName, Map<String, dynamic> setupInformation);
  Future<void> setDefaultSetup(String uBikeID, String uSetupID);
  Future<void> setSetting(String key, String value, String uBikeID,
      String category, String uSetupID);
  Future<void> editSetting(String key, String value, String uBikeID,
      String category, String uSetupID);
  Future<void> deleteSetup(String uBikeID, String uSetupID);
  Future<void> deleteSetting(
      String key, String uBikeID, String category, String uSetupID);
  Future<void> setSettingMeta(String key, String familyName, String uBikeID,
      String category, String uSetupID);
  Future<void> deleteSettingMeta(
      String key, String uBikeID, String category, String uSetupID);
  Stream<Map<String, dynamic>> getSettingsMeta(
      String uBikeID, String category, String uSetupID);
  Stream<Map<String, dynamic>> getSettings(
      String uBikeID, String category, String uSetupID);
  Stream<List<BikeSetup>> getSetups(String uBikeID);
  Stream<Map<String, dynamic>> getDocumentElement(
      String uBikeID, String category, String uSetupID);
  Future<String> getDefaultSetup(String uBikeID);
  Future<String> getSetupNameFromID(String uBikeID, String uSetupID);
  Future<Map<String, dynamic>> getSetupInformation(
      String uBikeID, String uSetupID);
  Future<Map<String, dynamic>> getSetupInformationAsMap(
      String uBikeID, String uSetupID);
}
