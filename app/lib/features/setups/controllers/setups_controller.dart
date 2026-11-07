import 'dart:async';
import '../../../common/controllers/optimistic_edits.dart';
import 'package:bikesetupapp/common/controllers/write_queue.dart';
import '../models/setup_configuration.dart';
import 'package:bikesetupapp/common/models/command_result.dart';
import 'setting_save_controller.dart';
import '../models/category.dart';
import 'package:bikesetupapp/features/setups/models/bike_setup.dart';
import 'package:bikesetupapp/features/setups/repositories/setups_repository.dart';
import 'package:bikesetupapp/common/controllers/operation_controller.dart';
import 'setup_creation_service.dart';

/// Coordinates setup configuration and keeps local setting edits visible while saving.
///
/// Category changes are serialized together; setting writes are ordered per field.
class SetupsController extends OperationController {
  SetupsController(this._repository);

  final SetupsRepository _repository;
  final _categoryWrites = WriteQueue();
  final Map<(String, String, String, String), SettingWriteQueue> _writes = {};

  final _localEdits =
      OptimisticEdits<(String, String, String, String), String>();
  final _lastSettings = <(String, String, String), Map<String, dynamic>>{};

  /// Updates configured fields, treating Tires as both front and rear categories.
  ///
  /// Disabling a category removes it from the configuration, not its stored values.
  Future<CommandResult<void>> setCategoryEnabled(
          String bike, String setup, String category, bool enabled,
          {String? suspensionType,
          required Map<String, List<String>> addedFields}) =>
      command(() => _categoryWrites.enqueue(() async {
            if (suspensionType != null &&
                (!enabled ||
                    !['Fork', 'Shock'].contains(category) ||
                    !['Air', 'Coil'].contains(suspensionType))) {
              throw const AppFailure(FailureCode.invalidInput);
            }

            final information =
                await _repository.getSetupInformation(bike, setup);
            final configuration =
                SetupConfiguration.fromInformation(information);
            final fields = <String, List<String>>{
              ...configuration.fields,
            };
            final categories =
                category == 'Tires' ? ['FrontTire', 'RearTire'] : [category];

            for (final key in categories) {
              if (enabled) {
                fields.putIfAbsent(key, () => addedFields[key] ?? <String>[]);
              } else {
                fields.remove(key);
              }
            }

            final name = await _repository.getSetupNameFromID(bike, setup);
            await _repository.createSetupList(bike, setup, name, {
              ...information,
              if (suspensionType != null)
                category.toLowerCase(): suspensionType,
              SetupConfiguration.metadataKey:
                  SetupConfiguration(fields).encode(),
            });
          }));

  Future<CommandResult<void>> updateSetupInformation(String bike, String setup,
          String name, Map<String, String> information) =>
      command(
          () => _repository.createSetupList(bike, setup, name, information));

  /// Copies stored values and metadata, then publishes the destination setup.
  ///
  /// An empty [source] creates configured fields using the default setup's
  /// information. Duplicate names return a failure; copying is not atomic.
  Future<CommandResult<void>> copySetup(
          String bike, String id, String name, String source) =>
      command(() async {
        final setups = await _repository.getSetups(bike).first;
        if (setups
            .any((s) => s.name.toLowerCase() == name.trim().toLowerCase())) {
          throw const AppFailure(FailureCode.duplicateName);
        }

        if (source.isEmpty) {
          await _createSetupFromDefault(bike, id, name);
          return;
        }

        final information = await _repository.getSetupInformation(bike, source);
        final categories = {
          ...Category.values.map((category) => category.category),
          ...SetupConfiguration.fromInformation(information).fields.keys,
        };

        for (final category in categories) {
          await _copyCategorySettings(bike, source, id, category);
        }

        await _repository.createSetupList(bike, id, name.trim(), information);
      });

  Future<void> _createSetupFromDefault(
      String bike, String id, String name) async {
    final current = await _repository.getDefaultSetup(bike);
    final information = current.isEmpty
        ? <String, dynamic>{}
        : await _repository.getSetupInformation(bike, current);
    await SetupCreationService(_repository).create(bike, id, name, {
      for (final entry in information.entries)
        if (entry.value is String) entry.key: entry.value as String,
    });
  }

  Future<void> _copyCategorySettings(
      String bike, String source, String id, String category) async {
    final values = await _repository.getSettings(bike, category, source).first;
    final meta =
        await _repository.getSettingsMeta(bike, category, source).first;

    for (final field in values.entries) {
      await _repository.setSetting(
          field.key, field.value.toString(), bike, category, id);
    }

    for (final field in meta.entries) {
      await _repository.setSettingMeta(
          field.key, field.value.toString(), bike, category, id);
    }
  }

  /// Shows the edit immediately and queues persistence with other writes to this field.
  ///
  /// Failed edits roll back without hiding newer pending edits. Successful values
  /// remain visible until the settings stream catches up.
  Future<CommandResult<void>> setSetting(String key, String value,
      String uBikeID, String category, String uSetupID) async {
    if (isDisposed) return const CommandCancelled();

    final scope = (uBikeID, uSetupID, category);
    final field = (uBikeID, uSetupID, category, key);
    final token =
        _localEdits.begin(field, _lastSettings[scope]?[key]?.toString(), value);
    emit();
    var success = false;

    try {
      final result = await command(
          () => _writes.putIfAbsent(field, SettingWriteQueue.new).enqueue(() {
                if (isDisposed) throw const CommandAborted();
                return _repository.setSetting(
                    key, value, uBikeID, category, uSetupID);
              }));
      success = result.isSuccess;
      return result;
    } finally {
      _localEdits.complete(field, token, success: success);
      emit();
    }
  }

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
      Stream.multi((sink) {
        final scope = (uBikeID, uSetupID, category);
        Map<String, dynamic>? remote;
        void publish() {
          if (remote == null || isDisposed) return;

          final visible = Map<String, dynamic>.from(remote!);

          for (final field in _localEdits.keys.toList()) {
            if ((field.$1, field.$2, field.$3) != scope) continue;
            final value =
                _localEdits.resolve(field, remote![field.$4]?.toString());
            if (value == null) {
              visible.remove(field.$4);
            } else {
              visible[field.$4] = value;
            }
          }

          sink.add(visible);
        }

        addListener(publish);
        final subscription = _repository
            .getSettings(uBikeID, category, uSetupID)
            .listen((values) {
          remote = Map<String, dynamic>.from(values);
          _lastSettings[scope] = remote!;
          publish();
        }, onError: sink.addError);
        sink.onCancel = () {
          removeListener(publish);
          unawaited(subscription.cancel());
        };
      });

  @override
  void dispose() {
    _localEdits.clear();
    _lastSettings.clear();
    super.dispose();
  }

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
