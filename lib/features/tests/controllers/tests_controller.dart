import 'package:bikesetupapp/features/setups/models/setup_configuration.dart';
import 'package:uuid/uuid.dart';
import 'package:bikesetupapp/features/setups/models/setup_defaults.dart';
import 'package:bikesetupapp/common/controllers/operation_controller.dart';
import 'package:bikesetupapp/common/controllers/write_queue.dart';
import 'package:bikesetupapp/common/models/command_result.dart';
import 'package:bikesetupapp/features/setups/repositories/setups_repository.dart';
import '../models/setup_test.dart';
import '../repositories/tests_repository.dart';

class TestsController extends OperationController {
  TestsController(this._repository, this._setups);
  final TestsRepository _repository;
  final SetupsRepository _setups;
  final WriteQueue _writes = WriteQueue();
  // A successful write can precede its watch snapshot. Keep only those saved
  // fields until the stream acknowledges them, without hiding unrelated edits.
  final _savedFields =
      <(String, String, String), Map<(String, String), String>>{};

  SetupTest withSavedValues(String bike, String setup, SetupTest test) {
    final key = (bike, setup, test.id);
    final pending = _savedFields[key];
    if (pending == null) return test;
    if (test.stage != TestStage.draft) {
      _savedFields.remove(key);
      return test;
    }
    pending.removeWhere(
        (field, value) => test.values[field.$1]?[field.$2] == value);
    if (pending.isEmpty) {
      _savedFields.remove(key);
      return test;
    }
    final values = readValues(test.values);
    for (final entry in pending.entries) {
      values[entry.key.$1]?[entry.key.$2] = entry.value;
    }
    return test.copyWith(values: values);
  }

  Stream<List<SetupTest>> watch(String bike, String setup) =>
      _repository.watch(bike, setup);
  Future<CommandResult<SetupTest>> create(
          String bike, String setup, String name, List<String> categories) =>
      command(() => _writes.enqueue(() async {
            if (isDisposed) throw const CommandAborted();
            final values = <String, Map<String, String>>{};
            final metadata = <String, Map<String, String>>{};
            final information = await _setups.getSetupInformation(bike, setup);
            final configuration =
                SetupConfiguration.fromInformation(information);
            final defaults = SetupDefaults.forShock(
                information['shock']?.toString() ?? 'Air');
            for (final category in configuration?.fields.keys ?? categories) {
              values[category] =
                  (await _setups.getSettings(bike, category, setup).first)
                      .map((k, v) => MapEntry(k, v.toString()));
              metadata[category] =
                  (await _setups.getSettingsMeta(bike, category, setup).first)
                      .map((k, v) => MapEntry(k, v.toString()));
              final fields = configuration?.fields[category] ??
                  defaults.entries
                      .where((e) => e.key.category == category)
                      .firstOrNull
                      ?.value
                      .keys ??
                  <String>[];
              for (final field in fields) {
                values[category]!.putIfAbsent(field, () => '');
              }
            }
            if (isDisposed) throw const CommandAborted();
            final draft = SetupTest(
                id: const Uuid().v4(),
                name: '$name test',
                setupInformation: {
                  for (final entry in information.entries)
                    if (entry.value is String && entry.key != 'activeTestId')
                      entry.key: entry.value as String,
                  SetupConfiguration.metadataKey: (configuration ??
                          SetupConfiguration({
                            for (final entry in values.entries)
                              entry.key: entry.value.keys.toList(),
                          }))
                      .encode(),
                },
                fieldMetadata: readValues(metadata),
                before: readValues(values),
                values: readValues(values));
            await _repository.create(bike, setup, draft);
            return draft;
          }));
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

  Future<CommandResult<void>> renameDraft(
          String bike, String setup, String id, String name) =>
      _update(bike, setup, id, TestStage.draft,
          (latest) => latest.copyWith(name: name.trim()));

  Future<CommandResult<void>> moveDraftStep(
          String bike, String setup, String id, int step) =>
      _update(bike, setup, id, TestStage.draft, (latest) {
        if (step < 0) throw const AppFailure(FailureCode.invalidInput);
        return latest.copyWith(draftStep: step);
      });

  Future<CommandResult<void>> updateField(String bike, String setup, String id,
          String category, String field, String value) =>
      _update(bike, setup, id, TestStage.draft, (latest) {
        if (!latest.values.containsKey(category) ||
            !latest.values[category]!.containsKey(field)) {
          throw const AppFailure(FailureCode.invalidInput);
        }
        final values = readValues(latest.values);
        values[category]![field] = value;
        return latest.copyWith(values: values);
      }, onCommitted: () {
        (_savedFields[(bike, setup, id)] ??= {})[(category, field)] = value;
      });

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
    super.dispose();
  }
}
