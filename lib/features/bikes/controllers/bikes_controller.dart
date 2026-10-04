import 'package:bikesetupapp/common/models/command_result.dart';
import 'package:bikesetupapp/features/bikes/models/bike.dart';
import 'package:bikesetupapp/features/bikes/repositories/bikes_repository.dart';
import 'package:bikesetupapp/common/controllers/operation_controller.dart';
import 'package:bikesetupapp/features/setups/controllers/setup_creation_service.dart';
import 'package:bikesetupapp/features/setups/repositories/setups_repository.dart';
import 'package:uuid/uuid.dart';

class BikesController extends OperationController {
  BikesController(this._repository, this._setups);
  final BikesRepository _repository;
  final SetupsRepository _setups;
  Future<CommandResult<String>> createBike(String bikeName,
          Map<String, String> setupInformation, String bikeType) =>
      command(() async {
        final String uBikeID = const Uuid().v4();
        final String uSetupID = const Uuid().v4();

        await SetupCreationService(_setups)
            .create(uBikeID, uSetupID, 'Default', setupInformation);

        if (await getDefaultBike() == "") {
          await _repository.setDefaultBike(uBikeID);
        }

        await _setups.setDefaultSetup(uBikeID, uSetupID);

        await _repository.createBikeRecord(uBikeID, bikeName, bikeType);

        return uBikeID;
      });
  Future<CommandResult<void>> selectSetup(String bikeId, String setupId) =>
      command(() async {
        await _repository.setDefaultBike(bikeId);
        await _setups.setDefaultSetup(bikeId, setupId);
      });

  Future<CommandResult<void>> setDefaultBike(String uBikeID) =>
      command(() => _repository.setDefaultBike(uBikeID));
  Future<CommandResult<void>> renameBike(String uBikeID, String bikeName) =>
      command(() => _repository.renameBike(uBikeID, bikeName));
  Future<CommandResult<void>> deleteBike(String uBikeID) =>
      command(() => _repository.deleteBike(uBikeID));
  Stream<List<Bike>> getBikes() => _repository.getBikes();
  Future<String> getDefaultBike() => _repository.getDefaultBike();
  Future<String> getBikeNameFromID(String uBikeID) =>
      _repository.getBikeNameFromID(uBikeID);
  Future<String> getBikeType(String uBikeID) =>
      _repository.getBikeType(uBikeID);
}
