import 'dart:async';
import 'package:bikesetupapp/common/models/command_result.dart';
import 'package:bikesetupapp/features/tests/models/setup_test.dart';
import 'package:bikesetupapp/features/tests/repositories/tests_repository.dart';

class MemoryTests implements TestsRepository {
  final records = <String, SetupTest>{};
  final updates = StreamController<void>.broadcast();
  bool fail = false;
  bool applied = false;

  @override
  Stream<List<SetupTest>> watch(String bike, String setup) async* {
    yield records.values.toList();
    await for (final _ in updates.stream) {
      yield records.values.toList();
    }
  }

  void _checkFailure() {
    if (fail) throw const AppFailure(FailureCode.saveFailed);
  }

  @override
  Future<void> create(String bike, String setup, SetupTest test) async {
    _checkFailure();
    if (records.containsKey(test.id) || test.stage != TestStage.draft) {
      throw const AppFailure(FailureCode.saveFailed);
    }
    records[test.id] = test;
    updates.add(null);
  }

  @override
  Future<void> update(String bike, String setup, String id,
      {required TestStage expectedStage,
      required SetupTest Function(SetupTest) change}) async {
    _checkFailure();
    final current = records[id];
    if (current == null ||
        current.stage == TestStage.finished ||
        current.stage != expectedStage) {
      throw const AppFailure(FailureCode.saveFailed);
    }
    final updated = change(current);
    if (updated.id != id || updated.stage == TestStage.finished) {
      throw const AppFailure(FailureCode.invalidInput);
    }
    records[id] = updated;
    updates.add(null);
  }

  @override
  Future<void> finish(String bike, String setup, String id,
      {bool apply = false,
      String? newSetupId,
      String? newSetupName,
      bool onlyIfUnchanged = false}) async {
    _checkFailure();
    final current = records[id];
    if (current == null) throw const AppFailure(FailureCode.saveFailed);
    if (onlyIfUnchanged &&
        (current.stage != TestStage.draft || current.changes.isNotEmpty)) {
      return;
    }
    if (current.stage == TestStage.finished) return;
    if ((apply || newSetupId != null) && current.stage != TestStage.review) {
      throw const AppFailure(FailureCode.invalidInput);
    }
    applied = apply;
    if (current.stage == TestStage.draft) {
      records.remove(id);
    } else {
      records[id] =
          current.copyWith(stage: TestStage.finished, result: 'Baseline kept');
    }
    updates.add(null);
  }
}
