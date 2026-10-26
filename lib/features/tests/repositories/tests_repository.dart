import '../models/setup_test.dart';

abstract interface class TestsRepository {
  Stream<List<SetupTest>> watch(String bike, String setup);
  Future<void> save(String bike, String setup, SetupTest test);

  /// Atomically archives the test and optionally applies changes or creates a setup.
  Future<void> finish(String bike, String setup, SetupTest test,
      {bool apply = false, String? newSetupId, String? newSetupName});
}
