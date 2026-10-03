import 'package:bikesetupapp/features/bikes/models/bike.dart';

abstract interface class BikesRepository {
  Future<void> setDefaultBike(String uBikeID);
  Future<void> renameBike(String uBikeID, String bikeName);
  Future<void> deleteBike(String uBikeID);
  Stream<List<Bike>> getBikes();
  Future<String> getDefaultBike();
  Future<String> getBikeNameFromID(String uBikeID);
  Future<String> getBikeType(String uBikeID);
  Future<void> createBikeRecord(String id, String name, String type);
}
