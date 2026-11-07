import '../../../common/controllers/optimistic_edits.dart';
import '../../setups/models/unit_system.dart';
import 'package:bikesetupapp/features/setups/models/setup_configuration.dart';
import 'package:uuid/uuid.dart';
import 'package:bikesetupapp/common/controllers/operation_controller.dart';
import 'package:bikesetupapp/common/controllers/write_queue.dart';
import 'package:bikesetupapp/common/models/command_result.dart';
import 'package:bikesetupapp/features/setups/repositories/setups_repository.dart';
import '../models/setup_test.dart';
import '../repositories/tests_repository.dart';

/// Manages experiment snapshots, draft edits, and stage transitions.
///
/// Writes are serialized, and saved draft values stay visible while watch
/// snapshots catch up. Repository updates enforce the expected experiment stage.
class TestsController extends OperationController {
  TestsController(this._repository, this._setups);

  final TestsRepository _repository;
  final SetupsRepository _setups;
  final WriteQueue _writes = WriteQueue();
  // A successful write can precede its watch snapshot. Keep only those saved
  // fields until the stream acknowledges them, without hiding unrelated edits.
  final _savedFields =
      <(String, String, String), Map<(String, String), String>>{};

  final _savedFamilies =
      <(String, String, String), Map<(String, String), String>>{};

  final _observedFields = <(String, String, String, String, String), String>{};

  final _localEdits =
      OptimisticEdits<(String, String, String, String, String), String>();

  SetupTest _withLocalEdits(String bike, String setup, SetupTest test) {
    final values = readValues(test.values);

    for (final field in _localEdits.keys.toList()) {
      if ((field.$1, field.$2, field.$3) != (bike, setup, test.id)) continue;
      final value = _localEdits.resolve(field, values[field.$4]?[field.$5]);
      if (value == null) {
        values[field.$4]?.remove(field.$5);
      } else {
        (values[field.$4] ??= {})[field.$5] = value;
      }
    }

    return test.copyWith(values: values);
  }

  /// Overlays pending and recently saved draft edits on a watched experiment.
  ///
  /// Also records observed fields and retires saved overrides once the stream
  /// acknowledges their values and unit metadata.
  SetupTest withSavedValues(String bike, String setup, SetupTest test) {
    for (final category in test.values.entries) {
      for (final field in category.value.entries) {
        _observedFields[(bike, setup, test.id, category.key, field.key)] =
            field.value;
      }
    }

    final key = (bike, setup, test.id);
    final pending = _savedFields[key];
    final families = _savedFamilies[key];
    if (pending == null) return _withLocalEdits(bike, setup, test);

    if (test.stage != TestStage.draft) {
      _savedFields.remove(key);
      _savedFamilies.remove(key);
      return test;
    }

    pending.removeWhere((field, value) =>
        test.values[field.$1]?[field.$2] == value &&
        (families?[field] == null ||
            test.fieldMetadata[field.$1]?[field.$2] == families![field]));
    if (pending.isEmpty) {
      _savedFields.remove(key);
      _savedFamilies.remove(key);
      return _withLocalEdits(bike, setup, test);
    }

    final values = readValues(test.values);
    final metadata = readValues(test.fieldMetadata);

    for (final entry in pending.entries) {
      (values[entry.key.$1] ??= {})[entry.key.$2] = entry.value;
      if (families?[entry.key] != null) {
        (metadata[entry.key.$1] ??= {})[entry.key.$2] = families![entry.key]!;
      }
    }

    return _withLocalEdits(
        bike, setup, test.copyWith(values: values, fieldMetadata: metadata));
  }

  Stream<List<SetupTest>> watch(String bike, String setup) =>
      _repository.watch(bike, setup);

  /// Captures the setup's configured fields and metadata in an independent draft.
  ///
  /// The original values become the baseline for comparing later edits. Category
  /// streams are read sequentially, so this is not an atomic cross-category read.
  Future<CommandResult<SetupTest>> create(
          String bike, String setup, String name) =>
      command(() => _writes.enqueue(() async {
            if (isDisposed) throw const CommandAborted();

            final information = await _setups.getSetupInformation(bike, setup);
            final configuration =
                SetupConfiguration.fromInformation(information);
            final (values, metadata) =
                await _captureSetupFields(bike, setup, configuration);
            if (isDisposed) throw const CommandAborted();

            final draft = SetupTest(
                id: const Uuid().v4(),
                name: '$name test',
                setupInformation: {
                  for (final entry in information.entries)
                    if (entry.value is String) entry.key: entry.value as String,
                  SetupConfiguration.metadataKey: configuration.encode(),
                },
                fieldMetadata: readValues(metadata),
                before: readValues(values),
                values: readValues(values));
            await _repository.create(bike, setup, draft);

            return draft;
          }));

  Future<(Map<String, Map<String, String>>, Map<String, Map<String, String>>)>
      _captureSetupFields(
          String bike, String setup, SetupConfiguration configuration) async {
    final values = <String, Map<String, String>>{};
    final metadata = <String, Map<String, String>>{};

    for (final category in configuration.fields.keys) {
      values[category] =
          (await _setups.getSettings(bike, category, setup).first)
              .map((k, v) => MapEntry(k, v.toString()));
      metadata[category] =
          (await _setups.getSettingsMeta(bike, category, setup).first)
              .map((k, v) => MapEntry(k, v.toString()));
      final fields = configuration.fields[category]!;
      for (final field in fields) {
        values[category]!.putIfAbsent(field, () => '');
      }
    }

    return (values, metadata);
  }

  Future<CommandResult<void>> _update(String bike, String setup, String id,
          TestStage stage, SetupTest Function(SetupTest) change,
          {void Function()? onCommitted}) =>
      command(() => _writes.enqueue(() async {
            if (isDisposed) throw const CommandAborted();
            await _repository.update(bike, setup, id, expectedStage: stage,
                change: (current) {
              if (isDisposed) throw const CommandAborted();
              return change(current);
            });
            if (!isDisposed) onCommitted?.call();
          }));

  Future<CommandResult<void>> renameExperiment(
          String bike, String setup, String id, TestStage stage, String name) =>
      _update(bike, setup, id, stage,
          (latest) => latest.copyWith(name: name.trim()));

  Future<CommandResult<void>> editExperiment(
          String bike, String setup, String id) =>
      _update(bike, setup, id, TestStage.ride, (latest) {
        if (latest.rides.isNotEmpty) {
          throw const AppFailure(FailureCode.invalidInput);
        }
        return latest.copyWith(stage: TestStage.draft, draftStep: 0);
      });

  Future<CommandResult<void>> moveDraftStep(
          String bike, String setup, String id, int step) =>
      _update(bike, setup, id, TestStage.draft, (latest) {
        if (step < 0) throw const AppFailure(FailureCode.invalidInput);
        return latest.copyWith(draftStep: step);
      });

  Future<CommandResult<void>> updateField(String bike, String setup, String id,
      String category, String field, String value,
      {String? previousValue}) async {
    if (isDisposed) return const CommandCancelled();

    final key = (bike, setup, id, category, field);
    final token = previousValue == null
        ? null
        : _localEdits.begin(
            key,
            _savedFields[(bike, setup, id)]?[(category, field)] ??
                _observedFields[key] ??
                previousValue,
            value);
    emit();
    var success = false;

    try {
      final result = await _update(bike, setup, id, TestStage.draft, (latest) {
        if (!latest.values.containsKey(category) ||
            !latest.values[category]!.containsKey(field)) {
          throw const AppFailure(FailureCode.invalidInput);
        }
        final values = readValues(latest.values);
        values[category]![field] = value;
        return latest.copyWith(values: values);
      }, onCommitted: () {
        final pending = _savedFields[(bike, setup, id)] ??= {};
        pending[(category, field)] = value;
      });
      success = result.isSuccess;

      return result;
    } finally {
      if (token != null) _localEdits.complete(key, token, success: success);
      emit();
    }
  }

  Future<CommandResult<void>> addField(String bike, String setup, String id,
      String category, String field, String value,
      {UnitFamily? family}) {
    final name = field.trim();

    return _update(bike, setup, id, TestStage.draft, (latest) {
      if (!latest.values.containsKey(category) ||
          name.isEmpty ||
          name.length > 100 ||
          value.trim().isEmpty ||
          latest.values[category]!.entries.any((entry) =>
              entry.key.toLowerCase() == name.toLowerCase() &&
              entry.value.trim().isNotEmpty)) {
        throw const AppFailure(FailureCode.invalidInput);
      }

      final values = readValues(latest.values);
      final metadata = readValues(latest.fieldMetadata);
      values[category]![name] = value;
      if (family != null) (metadata[category] ??= {})[name] = family.name;

      return latest.copyWith(values: values, fieldMetadata: metadata);
    }, onCommitted: () {
      (_savedFields[(bike, setup, id)] ??= {})[(category, name)] = value;
      if (family != null) {
        (_savedFamilies[(bike, setup, id)] ??= {})[(category, name)] =
            family.name;
      }
    });
  }

  Future<CommandResult<void>> startTest(
          String bike, String setup, String id, String name) =>
      _update(bike, setup, id, TestStage.draft, (latest) {
        if (latest.changes.isEmpty) {
          throw const AppFailure(FailureCode.invalidInput);
        }
        return latest.copyWith(name: name.trim(), stage: TestStage.ride);
      });

  Future<CommandResult<void>> updateFeedback(
          String bike, String setup, String id, RideFeedback feedback) =>
      _update(bike, setup, id, TestStage.ride,
          (latest) => latest.copyWith(feedback: feedback));

  Future<CommandResult<void>> logRide(
          String bike, String setup, String id, RideFeedback feedback) =>
      _update(bike, setup, id, TestStage.ride, (latest) {
        if (feedback.validationError != null) {
          throw const AppFailure(FailureCode.invalidInput);
        }
        return latest.copyWith(
            stage: TestStage.review,
            feedback: const RideFeedback(),
            rides: [...latest.rides, feedback.trimmed]);
      });

  Future<CommandResult<void>> resumeTest(
          String bike, String setup, String id) =>
      _update(bike, setup, id, TestStage.review,
          (latest) => latest.copyWith(stage: TestStage.ride));

  /// Finishes an experiment, optionally applying it or saving it as a new setup.
  ///
  /// A supplied [newSetupName] must be nonempty and unique ignoring case. Saved
  /// field overrides are cleared only after the repository operation succeeds.
  Future<CommandResult<void>> finish(String bike, String setup, String id,
          {bool apply = false, String? newSetupName}) =>
      command(() => _writes.enqueue(() async {
            if (isDisposed) throw const CommandAborted();

            if (newSetupName != null) {
              final name = newSetupName.trim();
              if (name.isEmpty ||
                  (await _setups.getSetups(bike).first)
                      .any((s) => s.name.toLowerCase() == name.toLowerCase())) {
                throw const AppFailure(FailureCode.duplicateName);
              }
            }

            if (isDisposed) throw const CommandAborted();

            await _repository.finish(bike, setup, id,
                apply: apply,
                newSetupId: newSetupName == null ? null : id,
                newSetupName: newSetupName?.trim());
            _savedFields.remove((bike, setup, id));
            _savedFamilies.remove((bike, setup, id));
          }));

  Future<CommandResult<void>> discardUnchangedDraft(
          String bike, String setup, String id) =>
      command(() => _writes.enqueue(() async {
            if (isDisposed) throw const CommandAborted();
            await _repository.finish(bike, setup, id, onlyIfUnchanged: true);
          }));

  @override
  void dispose() {
    _savedFields.clear();
    _savedFamilies.clear();
    _localEdits.clear();
    _observedFields.clear();
    super.dispose();
  }
}
