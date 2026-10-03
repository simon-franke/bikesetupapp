import 'package:flutter/material.dart';
import '../repositories/theme_preferences_repository.dart';

class AppStateNotifier extends ChangeNotifier {
  late ThemeMode themeMode;

  AppStateNotifier(this.themeMode, {ThemePreferencesRepository? preferences})
      : _preferences = preferences;
  final ThemePreferencesRepository? _preferences;

  Future<void> updateTheme(ThemeMode mode) async {
    await _preferences?.saveTheme(mode.name);
    themeMode = mode;
    notifyListeners();
  }

  static ThemeMode fromSaved(String? saved) {
    if (saved == null) return ThemeMode.dark;
    return ThemeMode.values.firstWhere(
      (m) => m.name == saved,
      orElse: () => ThemeMode.dark,
    );
  }
}
