import 'package:bikesetupapp/common/models/command_result.dart';
import 'package:bikesetupapp/features/bikes/models/bike.dart';
import 'package:bikesetupapp/features/bikes/repositories/bikes_repository.dart';
import 'package:bikesetupapp/common/controllers/operation_controller.dart';
import 'package:bikesetupapp/features/setups/controllers/setup_creation_service.dart';
import 'package:bikesetupapp/features/setups/repositories/setups_repository.dart';
import 'package:uuid/uuid.dart';
import '../models/bike_creation_draft.dart';

class BikesController extends OperationController {
  BikesController(this._repository, this._setups);
  final BikesRepository _repository;
  final SetupsRepository _setups;
  Future<CommandResult<({String bikeId, String setupId})>> createFromDraft(BikeCreationDraft draft) =>
      command(() => _create(draft.name, draft.toSetupInformation(), values: draft.values));

  Future<CommandResult<String>> createBike(String bikeName,
          Map<String, String> setupInformation) =>
      command(() async => (await _create(bikeName, setupInformation)).bikeId);

  Future<({String bikeId, String setupId})> _create(String bikeName,
      Map<String, String> setupInformation, {Map<String, Map<String, String>> values = const {}}) async {
    if ((await _repository.getBikes().first).any((bike) =>
        bike.name.toLowerCase() == bikeName.trim().toLowerCase())) {
      throw const AppFailure(FailureCode.duplicateName);
    }
    final bikeId = const Uuid().v4();
    final setupId = const Uuid().v4();
    await SetupCreationService(_setups).create(bikeId, setupId, 'Default', setupInformation, values: values);
    if (await getDefaultBike() == '') await _repository.setDefaultBike(bikeId);
    await _setups.setDefaultSetup(bikeId, setupId);
    await _repository.createBikeRecord(bikeId, bikeName.trim());
    return (bikeId: bikeId, setupId: setupId);
  }
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
}
