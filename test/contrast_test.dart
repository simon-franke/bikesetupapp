import 'package:bikesetupapp/common/theme/theme_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

double contrast(Color a, Color b) {
  final x = a.computeLuminance();
  final y = b.computeLuminance();
  return x > y ? (x + .05) / (y + .05) : (y + .05) / (x + .05);
}

void main() {
  for (final entry
      in {'dark': AppPalette.dark, 'light': AppPalette.light}.entries) {
    final p = entry.value;
    test('${entry.key} text remains readable on base and selected surfaces',
        () {
      final surfaces = [
        p.bg,
        p.surface,
        p.surface2,
        Color.alphaBlend(p.accent.withValues(alpha: .15), p.surface2)
      ];
      for (final background in surfaces) {
        for (final foreground in [
          p.ink,
          p.inkMuted,
          p.inkDim,
          p.accentText,
          p.green,
          p.amber,
          p.red
        ]) {
          expect(contrast(foreground, background), greaterThanOrEqualTo(4.5),
              reason: '$foreground on $background');
        }
      }
      expect(contrast(p.accentInk, p.accent), greaterThanOrEqualTo(4.5));
      expect(contrast(p.cardInk, p.card), greaterThanOrEqualTo(4.5));
      for (final background in [p.surface, p.surface2]) {
        expect(contrast(p.borderStrong, background), greaterThanOrEqualTo(3));
      }
    });
  }
  test('bike and hotspots contrast with the open canvas in both themes', () {
    for (final p in [AppPalette.dark, AppPalette.light]) {
      expect(contrast(p.inkMuted, p.bg), greaterThanOrEqualTo(4.5));
      expect(contrast(p.accentText, p.bg), greaterThanOrEqualTo(3));
      expect(contrast(p.borderStrong, p.bg), greaterThanOrEqualTo(3));
      expect(contrast(p.ink, p.surface), greaterThanOrEqualTo(4.5));
    }
  });
  test('custom filled actions have a readable foreground', () {
    for (final color in [
      AppPalette.dark.red,
      AppPalette.light.red,
      AppColors.blueDeep
    ]) {
      expect(
          contrast(AppColors.onColor(color), color), greaterThanOrEqualTo(4.5));
    }
  });
}
