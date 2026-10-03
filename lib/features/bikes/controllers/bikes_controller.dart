import 'package:bikesetupapp/features/bikes/models/bike.dart';
import 'package:bikesetupapp/features/bikes/repositories/bikes_repository.dart';
import 'package:bikesetupapp/common/controllers/operation_controller.dart';
import 'package:bikesetupapp/features/setups/controllers/setups_controller.dart';
import 'package:uuid/uuid.dart';

class BikesController extends OperationController {
  BikesController(this._repository, this._setups);
  final BikesRepository _repository;
  final SetupsController Function() _setups;
  Future<String> createBike(String bikeName,
          Map<String, String> setupInformation, String bikeType) =>
      run(() async {
        final String uBikeID = const Uuid().v4();
        final String uSetupID = const Uuid().v4();

        await _setups()
            .createSetup(uBikeID, uSetupID, 'Default', setupInformation);

        if (await getDefaultBike() == "") {
          await setDefaultBike(uBikeID);
        }

        await _setups().setDefaultSetup(uBikeID, uSetupID);

        await _repository.createBikeRecord(uBikeID, bikeName, bikeType);

        return uBikeID;
      });
  Future<void> selectSetup(String bikeId, String setupId) => run(() async {
        await _repository.setDefaultBike(bikeId);
        await _setups().setDefaultSetup(bikeId, setupId);
      });

  Future<void> setDefaultBike(String uBikeID) =>
      run(() => _repository.setDefaultBike(uBikeID));
  Future<void> renameBike(String uBikeID, String bikeName) =>
      run(() => _repository.renameBike(uBikeID, bikeName));
  Future<void> deleteBike(String uBikeID) =>
      run(() => _repository.deleteBike(uBikeID));
  Stream<List<Bike>> getBikes() => _repository.getBikes();
  Future<String> getDefaultBike() => _repository.getDefaultBike();
  Future<String> getBikeNameFromID(String uBikeID) =>
      _repository.getBikeNameFromID(uBikeID);
  Future<String> getBikeType(String uBikeID) =>
      _repository.getBikeType(uBikeID);
}
