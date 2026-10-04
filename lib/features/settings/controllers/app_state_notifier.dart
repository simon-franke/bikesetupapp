import 'package:bikesetupapp/common/controllers/operation_controller.dart';
import 'package:bikesetupapp/common/controllers/write_queue.dart';
import 'package:bikesetupapp/common/models/command_result.dart';
import 'package:flutter/material.dart';
import '../repositories/theme_preferences_repository.dart';

class AppStateNotifier extends OperationController {
  ThemeMode _themeMode;
  ThemeMode get themeMode => _themeMode;

  AppStateNotifier(ThemeMode themeMode,
      {ThemePreferencesRepository? preferences})
      : _themeMode = themeMode,
        _preferences = preferences;
  final ThemePreferencesRepository? _preferences;

  final WriteQueue _writes = WriteQueue();
  Future<CommandResult<void>> updateTheme(ThemeMode mode) => command(() async {
        final generation = beginRequest('theme');
        await _writes.enqueue(() async {
          if (isDisposed) throw const CommandAborted();
          await _preferences?.saveTheme(mode.name);
        });
        if (!isCurrentRequest('theme', generation)) {
          throw const CommandAborted();
        }
        _themeMode = mode;
        emit();
      });

  static ThemeMode fromSaved(String? saved) {
    if (saved == null) return ThemeMode.dark;
    return ThemeMode.values.firstWhere(
      (m) => m.name == saved,
      orElse: () => ThemeMode.dark,
    );
  }
}
