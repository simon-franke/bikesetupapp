import 'package:bikesetupapp/features/bikes/repositories/bikes_repository.dart';
import 'package:bikesetupapp/features/setups/repositories/setups_repository.dart';

class StartupSelection {
  const StartupSelection(
      {required this.bikeId,
      required this.bikeName,

      required this.setupId,
      required this.setupName});
  final String bikeId;
  final String bikeName;

  final String setupId;
  final String setupName;
}

/// Resolves a complete default selection without constructing UI or routes.
class StartupController {
  StartupController(this._bikes, this._setups);
  final BikesRepository _bikes;
  final SetupsRepository _setups;

  Future<StartupSelection?> loadSelection() async {
    final bikeId = await _bikes.getDefaultBike();
    if (bikeId.isEmpty) return null;
    final setupId = await _setups.getDefaultSetup(bikeId);
    if (setupId.isEmpty) return null;
    final setupName = await _setups.getSetupNameFromID(bikeId, setupId);
    if (setupName.isEmpty) return null;
    return StartupSelection(
        bikeId: bikeId,
        bikeName: await _bikes.getBikeNameFromID(bikeId),

        setupId: setupId,
        setupName: setupName);
  }
}
