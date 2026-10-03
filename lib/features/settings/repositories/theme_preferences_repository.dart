abstract interface class ThemePreferencesRepository {
  Future<String?> readTheme();
  Future<void> saveTheme(String mode);
}
