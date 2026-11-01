import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color blue = Color(0xFF4D7EA8);

  static const Color darkBg = Color(0xFF111E32);
  static const Color darkSurface = Color(0xFF203550);
  static const Color darkSurface2 = Color(0xFF2A405B);
  static const Color darkCard = Color(0xFFEDF5FF);
  static const Color darkCardInk = Color(0xFF172D46);
  static const Color darkInk = Color(0xFFF1F7FC);
  static const Color darkInkMuted = Color(0xFFC8D8EB);
  static const Color darkInkDim = Color(0xFFC8D8EB);
  static const Color darkBorder = Color(0xFF405B79);
  static const Color darkBorderStrong = Color(0xFF9EB9D6);

  static const Color lightBg = Color(0xFFEFF4FA);
  static const Color lightSurface = Color(0xFFFAFCFF);
  static const Color lightSurface2 = Color(0xFFE0EAF5);
  static const Color lightCard = Color(0xFF172D46);
  static const Color lightCardInk = Color(0xFFEDF5FF);
  static const Color lightInk = Color(0xFF172D46);
  static const Color lightInkMuted = Color(0xFF4A6078);
  static const Color lightInkDim = Color(0xFF4A6078);
  static const Color lightBorder = Color(0xFFC8D7E8);
  static const Color lightBorderStrong = Color(0xFF607B98);

  static const Color accent = Color(0xFF7CCBFF);
  static const Color accentInk = Color(0xFF102D43);
  static const Color green = Color(0xFF5BB97A);
  static const Color amber = Color(0xFFD9A23A);
  static const Color red = Color(0xFFE0654C);

  /// Foreground for a solid fill; choose the higher-contrast neutral.
  static Color onColor(Color color) {
    final luminance = color.computeLuminance();
    return (luminance + 0.05) / 0.05 >= 1.05 / (luminance + 0.05)
        ? const Color(0xFF000000)
        : const Color(0xFFFFFFFF);
  }
}

extension AppColorsX on BuildContext {
  AppPalette get palette => Theme.of(this).extension<AppPalette>()!;
}

@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  final Color bg;
  final Color surface;
  final Color surface2;
  final Color card;
  final Color cardInk;
  final Color ink;
  final Color inkMuted;
  final Color inkDim;
  final Color border;
  final Color borderStrong;
  final Color accent;
  final Color accentInk;
  final Color green;
  final Color amber;
  final Color red;

  /// Use a deeper glacier blue for readable accent text on light surfaces.
  Color get accentText => bg.computeLuminance() < 0.5
      ? const Color(0xFF91D4FF)
      : const Color(0xFF1D5F8A);

  /// Tangerine adds warmth to ride feedback without replacing semantic colors.
  Color get playful => const Color(0xFFFFAB61);
  Color get playfulText => bg.computeLuminance() < 0.5
      ? const Color(0xFFFFCD9D)
      : const Color(0xFF854500);

  const AppPalette({
    required this.bg,
    required this.surface,
    required this.surface2,
    required this.card,
    required this.cardInk,
    required this.ink,
    required this.inkMuted,
    required this.inkDim,
    required this.border,
    required this.borderStrong,
    required this.accent,
    required this.accentInk,
    required this.green,
    required this.amber,
    required this.red,
  });

  static const AppPalette dark = AppPalette(
    bg: AppColors.darkBg,
    surface: AppColors.darkSurface,
    surface2: AppColors.darkSurface2,
    card: AppColors.darkCard,
    cardInk: AppColors.darkCardInk,
    ink: AppColors.darkInk,
    inkMuted: AppColors.darkInkMuted,
    inkDim: AppColors.darkInkDim,
    border: AppColors.darkBorder,
    borderStrong: AppColors.darkBorderStrong,
    accent: AppColors.accent,
    accentInk: AppColors.accentInk,
    green: Color(0xFFA8EFC5),
    amber: Color(0xFFFFD989),
    red: Color(0xFFFFD5CD),
  );

  static const AppPalette light = AppPalette(
    bg: AppColors.lightBg,
    surface: AppColors.lightSurface,
    surface2: AppColors.lightSurface2,
    card: AppColors.lightCard,
    cardInk: AppColors.lightCardInk,
    ink: AppColors.lightInk,
    inkMuted: AppColors.lightInkMuted,
    inkDim: AppColors.lightInkDim,
    border: AppColors.lightBorder,
    borderStrong: AppColors.lightBorderStrong,
    accent: AppColors.accent,
    accentInk: AppColors.accentInk,
    green: Color(0xFF2A623D),
    amber: Color(0xFF794F00),
    red: Color(0xFFA52E20),
  );

  @override
  AppPalette copyWith({
    Color? bg,
    Color? surface,
    Color? surface2,
    Color? card,
    Color? cardInk,
    Color? ink,
    Color? inkMuted,
    Color? inkDim,
    Color? border,
    Color? borderStrong,
    Color? accent,
    Color? accentInk,
    Color? green,
    Color? amber,
    Color? red,
  }) =>
      AppPalette(
        bg: bg ?? this.bg,
        surface: surface ?? this.surface,
        surface2: surface2 ?? this.surface2,
        card: card ?? this.card,
        cardInk: cardInk ?? this.cardInk,
        ink: ink ?? this.ink,
        inkMuted: inkMuted ?? this.inkMuted,
        inkDim: inkDim ?? this.inkDim,
        border: border ?? this.border,
        borderStrong: borderStrong ?? this.borderStrong,
        accent: accent ?? this.accent,
        accentInk: accentInk ?? this.accentInk,
        green: green ?? this.green,
        amber: amber ?? this.amber,
        red: red ?? this.red,
      );

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      bg: Color.lerp(bg, other.bg, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surface2: Color.lerp(surface2, other.surface2, t)!,
      card: Color.lerp(card, other.card, t)!,
      cardInk: Color.lerp(cardInk, other.cardInk, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      inkMuted: Color.lerp(inkMuted, other.inkMuted, t)!,
      inkDim: Color.lerp(inkDim, other.inkDim, t)!,
      border: Color.lerp(border, other.border, t)!,
      borderStrong: Color.lerp(borderStrong, other.borderStrong, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentInk: Color.lerp(accentInk, other.accentInk, t)!,
      green: Color.lerp(green, other.green, t)!,
      amber: Color.lerp(amber, other.amber, t)!,
      red: Color.lerp(red, other.red, t)!,
    );
  }
}

/// The five text roles used throughout the phone UI. Keep size, weight and
/// spacing here; callers may adapt color and numeric alignment only.
abstract final class AppTextStyles {
  static const heading = TextStyle(
      fontFamily: 'Sora',
      fontSize: 24,
      fontWeight: FontWeight.w600,
      height: 1.25,
      letterSpacing: -0.3);
  static const label = TextStyle(
      fontFamily: 'Sora',
      fontSize: 16,
      fontWeight: FontWeight.w600,
      height: 1.35,
      letterSpacing: 0);
  static const body = TextStyle(
      fontFamily: 'Sora',
      fontSize: 16,
      fontWeight: FontWeight.w400,
      height: 1.45,
      letterSpacing: 0);
  static const caption = TextStyle(
      fontFamily: 'Sora',
      fontSize: 12,
      fontWeight: FontWeight.w500,
      height: 1.4,
      letterSpacing: 0);
  static const value = TextStyle(
      fontFamily: 'Sora',
      fontSize: 48,
      fontWeight: FontWeight.w600,
      height: 1.1,
      letterSpacing: -0.5,
      fontFeatures: [FontFeature.tabularFigures()]);
}

/// Visible icon sizes; interactive targets remain at least 48 logical pixels.
abstract final class AppIconSizes {
  static const compact = 16.0;
  static const control = 20.0;
  static const navigation = 24.0;
}

class AppTheme {
  AppTheme._();

  static ThemeData _build(
      {required Brightness brightness, required AppPalette p}) {
    final textTheme = TextTheme(
      displayLarge: AppTextStyles.value,
      displayMedium: AppTextStyles.value,
      displaySmall: AppTextStyles.heading,
      headlineLarge: AppTextStyles.heading,
      headlineMedium: AppTextStyles.heading,
      headlineSmall: AppTextStyles.heading,
      titleLarge: AppTextStyles.heading,
      titleMedium: AppTextStyles.label,
      titleSmall: AppTextStyles.label,
      bodyLarge: AppTextStyles.body,
      bodyMedium: AppTextStyles.body,
      bodySmall: AppTextStyles.caption,
      labelLarge: AppTextStyles.label,
      labelMedium: AppTextStyles.label,
      labelSmall: AppTextStyles.caption,
    ).apply(bodyColor: p.ink, displayColor: p.ink);

    return ThemeData(
      brightness: brightness,
      fontFamily: 'Sora',
      splashFactory: NoSplash.splashFactory,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      primaryColor: p.accentText,
      scaffoldBackgroundColor: p.bg,
      canvasColor: p.bg,
      cardColor: p.surface,
      dividerColor: p.border,
      colorScheme: brightness == Brightness.dark
          ? ColorScheme.dark(
              primary: p.accentText,
              onPrimary: p.accentInk,
              secondary: p.playful,
              onSecondary: AppColors.onColor(p.playful),
              surface: p.surface,
              onSurface: p.ink,
              error: p.red,
              onError: AppColors.onColor(p.red),
            )
          : ColorScheme.light(
              primary: p.accentText,
              onPrimary: Colors.white,
              secondary: p.playful,
              onSecondary: AppColors.onColor(p.playful),
              surface: p.surface,
              onSurface: p.ink,
              error: p.red,
              onError: AppColors.onColor(p.red),
            ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: p.bg,
        foregroundColor: p.ink,
        iconTheme: IconThemeData(color: p.ink, size: AppIconSizes.control),
        titleTextStyle: AppTextStyles.heading.copyWith(color: p.ink),
      ),
      cardTheme: CardThemeData(
        color: p.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: p.border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.surface2,
        hintStyle: AppTextStyles.body.copyWith(color: p.inkMuted),
        labelStyle: AppTextStyles.label.copyWith(color: p.inkMuted),
        floatingLabelStyle: AppTextStyles.label.copyWith(color: p.accentText),
        suffixStyle: AppTextStyles.body.copyWith(color: p.inkMuted),
        errorStyle: AppTextStyles.body.copyWith(color: p.red),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: UnderlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
        enabledBorder: UnderlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
        focusedBorder: UnderlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: p.accentText, width: 2)),
        errorBorder: UnderlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: p.red)),
        focusedErrorBorder: UnderlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: p.red, width: 2)),
      ),
      filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
        iconSize: AppIconSizes.control,
        backgroundColor: p.accent,
        foregroundColor: p.accentInk,
        disabledBackgroundColor: p.surface2,
        disabledForegroundColor: p.inkMuted,
        minimumSize: const Size(48, 48),
        textStyle: textTheme.labelLarge,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ).copyWith(overlayColor: _pressOverlay)),
      elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
        iconSize: AppIconSizes.control,
        backgroundColor: p.accent,
        foregroundColor: p.accentInk,
        elevation: 0,
        minimumSize: const Size(48, 48),
        textStyle: textTheme.labelLarge,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ).copyWith(overlayColor: _pressOverlay)),
      outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
        iconSize: AppIconSizes.control,
        foregroundColor: p.ink,
        side: BorderSide(color: p.borderStrong),
        minimumSize: const Size(48, 48),
        textStyle: textTheme.labelLarge,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ).copyWith(overlayColor: _pressOverlay)),
      textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
        iconSize: AppIconSizes.control,
        foregroundColor: p.accentText,
        minimumSize: const Size(48, 48),
        textStyle: textTheme.labelLarge,
      ).copyWith(overlayColor: _pressOverlay)),
      chipTheme: ChipThemeData(
        backgroundColor: p.surface,
        selectedColor: p.surface2,
        labelStyle: textTheme.labelLarge,
        side: BorderSide(color: p.borderStrong),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        showCheckmark: false,
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
          style: ButtonStyle(
        overlayColor: _pressOverlay,
        minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
        side: WidgetStatePropertyAll(BorderSide(color: p.borderStrong)),
        shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
        textStyle: WidgetStatePropertyAll(textTheme.labelLarge),
        backgroundColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? p.card
                : Colors.transparent),
        foregroundColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected) ? p.cardInk : p.inkMuted),
      )),
      iconButtonTheme: IconButtonThemeData(
          style: IconButton.styleFrom(
        foregroundColor: p.inkMuted,
        iconSize: AppIconSizes.control,
        minimumSize: const Size(48, 48),
      ).copyWith(overlayColor: _pressOverlay)),
      iconTheme: IconThemeData(color: p.ink, size: AppIconSizes.control),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        splashColor: Colors.transparent,
        highlightElevation: 0,
        backgroundColor: p.accent,
        foregroundColor: p.accentInk,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
      ),
      expansionTileTheme: ExpansionTileThemeData(
        iconColor: p.inkMuted,
        collapsedIconColor: p.inkMuted,
        textColor: p.ink,
        collapsedTextColor: p.ink,
      ),
      textTheme: textTheme,
      extensions: <ThemeExtension<dynamic>>[p],
    );
  }

  static ThemeData get lightTheme =>
      _build(brightness: Brightness.light, p: AppPalette.light);
  static ThemeData get darkTheme =>
      _build(brightness: Brightness.dark, p: AppPalette.dark);
}

// Suppress touch overlays while retaining the default keyboard focus feedback.
final _pressOverlay = WidgetStateProperty.resolveWith<Color?>((states) =>
    states.contains(WidgetState.pressed) ? Colors.transparent : null);
