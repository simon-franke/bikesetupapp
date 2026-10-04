import 'package:bikesetupapp/common/data/platform_operation.dart';
import 'package:bikesetupapp/common/models/command_result.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme_preferences_repository.dart';

class SharedPreferencesThemeRepository implements ThemePreferencesRepository {
  @override
  Future<String?> readTheme() async => platformOperation(
      () async =>
          (await SharedPreferences.getInstance()).getString('themeMode'),
      fallback: FailureCode.loadFailed);
  @override
  Future<void> saveTheme(String mode) => platformOperation(() async {
        final saved = await (await SharedPreferences.getInstance())
            .setString('themeMode', mode);
        if (!saved) throw const AppFailure(FailureCode.saveFailed);
      }, fallback: FailureCode.saveFailed);
}
