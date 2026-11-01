import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Quiet touch feedback, shared across controls to avoid overlapping pulses.
abstract final class AppHaptics {
  static final Stopwatch _clock = Stopwatch()..start();
  static int? _lastPulse;

  static void selection() => _emit(HapticFeedback.selectionClick);
  static void action() => _emit(HapticFeedback.lightImpact);
  static void emphasis() => _emit(HapticFeedback.mediumImpact);

  static void _emit(Future<void> Function() feedback) {
    if (defaultTargetPlatform != TargetPlatform.iOS &&
        defaultTargetPlatform != TargetPlatform.android) {
      return;
    }
    final now = _clock.elapsedMilliseconds;
    if (_lastPulse != null && now - _lastPulse! < 80) return;
    _lastPulse = now;
    unawaited(feedback());
  }

  /// Preserve disabled controls and run actions without waiting for the device.
  static VoidCallback? wrap(VoidCallback? callback,
      {bool selection = false, bool emphasized = false}) {
    if (callback == null) return null;
    return () {
      if (selection) {
        AppHaptics.selection();
      } else if (emphasized) {
        emphasis();
      } else {
        action();
      }
      callback();
    };
  }
}
