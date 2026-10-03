import 'package:shared_preferences/shared_preferences.dart';
import 'theme_preferences_repository.dart';

class SharedPreferencesThemeRepository implements ThemePreferencesRepository {
  @override
  Future<String?> readTheme() async =>
      (await SharedPreferences.getInstance()).getString('themeMode');
  @override
  Future<void> saveTheme(String mode) async {
    await (await SharedPreferences.getInstance()).setString('themeMode', mode);
  }
}
