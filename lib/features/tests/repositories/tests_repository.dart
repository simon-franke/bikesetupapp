import '../models/setup_test.dart';

abstract interface class TestsRepository {
  Stream<List<SetupTest>> watch(String bike, String setup);

  /// Creates an independent draft only if its ID is unused.
  Future<void> create(String bike, String setup, SetupTest test);

  /// Reads, validates and changes an existing active test atomically.
  /// [change] must be synchronous and free of side effects: a transaction retry
  /// may invoke it again with a newer snapshot. Missing tests are never created.
  Future<void> update(String bike, String setup, String id,
      {required TestStage expectedStage,
      required SetupTest Function(SetupTest current) change});

  /// When onlyIfUnchanged is true, only an unchanged draft may be deleted.
  /// Atomically finishes the current stored test, optionally applying its
  /// changes or creating a setup. A draft finished without applying is deleted.
  Future<void> finish(String bike, String setup, String id,
      {bool apply = false,
      String? newSetupId,
      String? newSetupName,
      bool onlyIfUnchanged = false});
}
