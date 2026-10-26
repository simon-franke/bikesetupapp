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
  Stream<List<SetupTest>> watch(String bike, String setup) =>
      _repository.watch(bike, setup);
  Future<CommandResult<void>> create(
          String bike, String setup, String name, List<String> categories) =>
      command(() => _writes.enqueue(() async {
            if (isDisposed) throw const CommandAborted();
            final existing = await _repository.watch(bike, setup).first;
            if (existing.any((t) => t.stage != TestStage.finished)) return;
            final values = <String, Map<String, String>>{};
            final information = await _setups.getSetupInformation(bike, setup);
            final configuration =
                SetupConfiguration.fromInformation(information);
            final defaults = SetupDefaults.forShock(
                information['shock']?.toString() ?? 'Air');
            for (final category in configuration?.fields.keys ?? categories) {
              values[category] =
                  (await _setups.getSettings(bike, category, setup).first)
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
            await _repository.save(
                bike,
                setup,
                SetupTest(
                    id: const Uuid().v4(),
                    name: '$name test',
                    before: readValues(values),
                    values: readValues(values)));
          }));
  Future<CommandResult<void>> _update(String bike, String setup, String id,
          TestStage stage, SetupTest Function(SetupTest) change) =>
      command(() => _writes.enqueue(() async {
            final latest = await _latest(bike, setup, id);
            if (latest.stage != stage) {
              throw const AppFailure(FailureCode.saveFailed);
            }
            await _repository.save(bike, setup, change(latest));
          }));

  Future<SetupTest> _latest(String bike, String setup, String id) async {
    if (isDisposed) throw const CommandAborted();
    final latest = (await _repository.watch(bike, setup).first)
        .where((test) => test.id == id)
        .firstOrNull;
    if (isDisposed) throw const CommandAborted();
    if (latest == null) throw const AppFailure(FailureCode.saveFailed);
    return latest;
  }

  Future<CommandResult<void>> renameDraft(
          String bike, String setup, String id, String name) =>
      _update(bike, setup, id, TestStage.draft,
          (latest) => latest.copyWith(name: name.trim()));

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
            final test = await _latest(bike, setup, id);
            if (test.stage == TestStage.finished) return;
            if ((apply || newSetupName != null) &&
                test.stage != TestStage.review) {
              throw const AppFailure(FailureCode.invalidInput);
            }
            if (newSetupName != null) {
              final name = newSetupName.trim();
              if (name.isEmpty ||
                  (await _setups.getSetups(bike).first)
                      .any((s) => s.name.toLowerCase() == name.toLowerCase())) {
                throw const AppFailure(FailureCode.duplicateName);
              }
            }
            await _repository.finish(bike, setup, test,
                apply: apply,
                newSetupId: newSetupName == null ? null : test.id,
                newSetupName: newSetupName?.trim());
          }));
}
