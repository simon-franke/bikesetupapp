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
            if (existing.any((t) => t.stage != 'finished')) return;
            final values = <String, Map<String, String>>{};
            final information = await _setups.getSetupInformation(bike, setup);
            final configuration = SetupConfiguration.fromInformation(information);
            final defaults = SetupDefaults.forShock(information['shock']?.toString() ?? 'Air');
            for (final category in configuration?.fields.keys ?? categories) {
              values[category] =
                  (await _setups.getSettings(bike, category, setup).first)
                      .map((k, v) => MapEntry(k, v.toString()));
              final fields = configuration?.fields[category] ?? defaults.entries
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
  Future<CommandResult<void>> save(String bike, String setup, SetupTest test) =>
      command(() => _writes.enqueue(() {
            if (isDisposed) throw const CommandAborted();
            return _repository.save(bike, setup, test);
          }));
  Future<CommandResult<void>> updateDraft(String bike, String setup, String id,
          {String? name,
          String? category,
          String? field,
          String? value,
          Map<String, String>? feedback}) =>
      command(() => _writes.enqueue(() async {
            if (isDisposed) throw const CommandAborted();
            final latest = (await _repository.watch(bike, setup).first)
                .where((test) => test.id == id && test.stage != 'finished')
                .firstOrNull;
            if (latest == null) throw const AppFailure(FailureCode.saveFailed);
            final values = readValues(latest.values);
            if (category != null && field != null && value != null) {
              if (latest.stage != 'draft') {
                throw const AppFailure(FailureCode.saveFailed);
              }
              (values[category] ??= {})[field] = value;
            }
            await _repository.save(
                bike,
                setup,
                latest.copyWith(
                    name: name, values: values, feedback: feedback));
          }));
  Future<CommandResult<void>> finish(String bike, String setup, SetupTest test,
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
            await _repository.finish(bike, setup, test,
                apply: apply,
                newSetupId: newSetupName == null ? null : test.id,
                newSetupName: newSetupName?.trim());
          }));
}
