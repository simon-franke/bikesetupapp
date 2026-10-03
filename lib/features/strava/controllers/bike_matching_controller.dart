import 'package:bikesetupapp/common/controllers/operation_controller.dart';
import 'package:bikesetupapp/features/bikes/controllers/bikes_controller.dart';
import 'package:bikesetupapp/features/bikes/models/bike.dart';
import '../models/strava_bike.dart';
import 'strava_controller.dart';

class BikeMatchingController extends OperationController {
  BikeMatchingController(this._bikes, this._strava);
  final BikesController _bikes;
  final StravaController _strava;
  List<StravaBike> stravaBikes = [];
  List<Bike> appBikes = [];
  final Map<String, String?> links = {};
  bool loading = true;
  bool syncing = false;
  String? syncError;

  Future<void> load({bool syncIfEmpty = true}) async {
    try {
      var incoming = await _strava.getStravaBikes().first;
      final bikes = await _bikes.getBikes().first;
      if (incoming.isEmpty && syncIfEmpty) {
        syncing = true;
        emit();
        if (!await _strava.sync()) syncError = _strava.lastError;
        incoming = await _strava.getStravaBikes().first;
      }
      if (isDisposed) return;
      stravaBikes = incoming;
      appBikes = bikes;
      links.clear();
      for (final strava in incoming) {
        if (strava.linkedBikeId != null) {
          links[strava.stravaGearId] = strava.linkedBikeId;
        } else {
          final lower = strava.name.toLowerCase();
          for (final bike in bikes) {
            if (bike.name.toLowerCase().contains(lower) ||
                lower.contains(bike.name.toLowerCase())) {
              links[strava.stravaGearId] = bike.id;
              break;
            }
          }
        }
      }
    } catch (_) {
      syncError = 'Could not load bikes. Try again.';
    } finally {
      loading = false;
      syncing = false;
      emit();
    }
  }

  Future<void> sync() async {
    if (syncing) return;
    syncing = true;
    syncError = null;
    emit();
    try {
      if (!await _strava.sync()) syncError = _strava.lastError;
      await load(syncIfEmpty: false);
    } finally {
      syncing = false;
      emit();
    }
  }

  void link(String gearId, String? bikeId) {
    links[gearId] = bikeId;
    emit();
  }

  Future<void> save() => run(() async {
        for (final strava in stravaBikes) {
          final id = links[strava.stravaGearId];
          if (id != null) {
            await _strava.linkStravaBike(strava.stravaGearId, id);
          } else if (strava.linkedBikeId != null) {
            await _strava.unlinkStravaBike(strava.stravaGearId);
          }
        }
      });
}
