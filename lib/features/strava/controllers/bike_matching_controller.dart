import 'package:bikesetupapp/common/controllers/operation_controller.dart';
import 'package:bikesetupapp/common/models/command_result.dart';
import 'package:bikesetupapp/features/bikes/controllers/bikes_controller.dart';
import 'package:bikesetupapp/features/bikes/models/bike.dart';
import '../models/strava_bike.dart';
import '../models/bike_link_suggestions.dart';
import 'strava_controller.dart';

class BikeMatchingController extends OperationController {
  BikeMatchingController(this._bikes, this._strava);
  final BikesController _bikes;
  final StravaController _strava;
  List<StravaBike> _stravaBikes = [];
  List<Bike> _appBikes = [];
  final Map<String, String?> _links = {};
  bool _loading = true;
  bool _syncing = false;
  List<StravaBike> get stravaBikes => List.unmodifiable(_stravaBikes);
  List<Bike> get appBikes => List.unmodifiable(_appBikes);
  Map<String, String?> get links => Map.unmodifiable(_links);
  bool get loading => _loading;
  bool get syncing => _syncing;

  Future<CommandResult<void>> load({bool syncIfEmpty = true}) =>
      command(() async {
        final generation = beginRequest('load');
        _syncing = false;
        _loading = true;
        emit();
        try {
          final syncFailure = await _load(generation, syncIfEmpty: syncIfEmpty);
          if (syncFailure != null) throw syncFailure;
        } finally {
          if (isCurrentRequest('load', generation)) {
            _loading = false;
            emit();
          }
        }
      });

  Future<AppFailure?> _load(int generation, {required bool syncIfEmpty}) async {
    void check() {
      if (!isCurrentRequest('load', generation)) throw const CommandAborted();
    }

    var incoming = await _strava.getStravaBikes().first;
    check();
    final bikes = await _bikes.getBikes().first;
    check();
    AppFailure? syncFailure;
    if (incoming.isEmpty && syncIfEmpty) {
      _syncing = true;
      emit();
      try {
        final synced = await _strava.sync();
        check();
        if (synced.isCancelled) throw const CommandAborted();
        syncFailure = synced.failure;
        incoming = await _strava.getStravaBikes().first;
        check();
      } finally {
        if (isCurrentRequest('load', generation)) {
          _syncing = false;
          emit();
        }
      }
    }
    _stravaBikes = List.of(incoming);
    _appBikes = List.of(bikes);
    _links
      ..clear()
      ..addAll(suggestBikeLinks(incoming, bikes));
    emit();
    return syncFailure;
  }

  Future<CommandResult<void>> sync() => share(
      'sync',
      () => command(() async {
            final generation = beginRequest('load');
            _syncing = true;
            emit();
            try {
              final result = await _strava.sync();
              if (!isCurrentRequest('load', generation)) {
                throw const CommandAborted();
              }
              if (result.isCancelled) throw const CommandAborted();
              await _load(generation, syncIfEmpty: false);
              result.requireValue();
            } finally {
              if (isCurrentRequest('load', generation)) {
                _loading = false;
                _syncing = false;
                emit();
              }
            }
          }));

  void link(String gearId, String? bikeId) {
    if (isDisposed || !_stravaBikes.any((bike) => bike.stravaGearId == gearId)) {
      return;
    }
    if (bikeId != null && !_appBikes.any((bike) => bike.id == bikeId)) return;
    _links[gearId] = bikeId;
    emit();
  }

  Future<CommandResult<void>> save() => share(
      'save',
      () => command(() async {
            final incoming = List.of(_stravaBikes);
            final links = Map.of(_links);
            for (final strava in incoming) {
              if (isDisposed) throw const CommandAborted();
              final id = links[strava.stravaGearId];
              if (id != null) {
                (await _strava.linkStravaBike(strava.stravaGearId, id))
                    .requireValue();
              } else if (strava.linkedBikeId != null) {
                (await _strava.unlinkStravaBike(strava.stravaGearId))
                    .requireValue();
              }
              if (isDisposed) throw const CommandAborted();
            }
          }));
}
