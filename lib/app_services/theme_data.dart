import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  AppColors._();

  static const Color blue = Color(0xFF4D7EA8);
  static const Color blueDeep = Color(0xFF3A546D);

  static const Color darkBg = Color(0xFF272932);
  static const Color darkSurface = Color(0xFF303B49);
  static const Color darkSurface2 = Color(0xFF3A546D);
  static const Color darkCard = Color(0xFFEDF3F8);
  static const Color darkCardInk = Color(0xFF233749);
  static const Color darkInk = Color(0xFFF2F3F5);
  static const Color darkInkMuted = Color(0xFFD5DDE6);
  static const Color darkInkDim = Color(0xFFD5DDE6);
  static const Color darkBorder = Color(0xFF45576A);
  static const Color darkBorderStrong = Color(0xFFA4B7C9);

  static const Color lightBg = Color(0xFFE7EEEB);
  static const Color lightSurface = Color(0xFFF8FAFB);
  static const Color lightSurface2 = Color(0xFFDDE7ED);
  static const Color lightCard = Color(0xFF233749);
  static const Color lightCardInk = Color(0xFFEDF3F8);
  static const Color lightInk = Color(0xFF233749);
  static const Color lightInkMuted = Color(0xFF53616D);
  static const Color lightInkDim = Color(0xFF53616D);
  static const Color lightBorder = Color(0xFFCDD9E0);
  static const Color lightBorderStrong = Color(0xFF6B7C8B);

  static const Color accent = Color(0xFFF4A259);
  static const Color accentInk = Color(0xFF362313);
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

  /// Orange for text/icons, distinct from the original orange button fill.
  Color get accentText => bg.computeLuminance() < 0.5
      ? const Color(0xFFFFD3A8)
      : const Color(0xFF854000);

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
    green: Color(0xFFA2E9BF),
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

class AppTextStyles {
  AppTextStyles._();

  static TextStyle mono({
    double size = 14,
    FontWeight weight = FontWeight.w700,
    Color? color,
    double letterSpacing = 0,
    double? height,
  }) =>
      GoogleFonts.jetBrainsMono(
        fontSize: size,
        fontWeight: weight,
        color: color,
        letterSpacing: letterSpacing,
        height: height,
      );

  static TextStyle inter({
    double size = 14,
    FontWeight weight = FontWeight.w500,
    Color? color,
    double letterSpacing = 0,
    double? height,
  }) =>
      GoogleFonts.inter(
        fontSize: size,
        fontWeight: weight,
        color: color,
        letterSpacing: letterSpacing,
        height: height,
      );

  static TextStyle eyebrow(
          {Color? color, double size = 10, double letterSpacing = 1.6}) =>
      GoogleFonts.inter(
        fontSize: size,
        fontWeight: FontWeight.w700,
        color: color,
        letterSpacing: letterSpacing,
      );
}

class AppTheme {
  AppTheme._();

  static ThemeData _build(
      {required Brightness brightness, required AppPalette p}) {
    final base =
        brightness == Brightness.dark ? ThemeData.dark() : ThemeData.light();
    final textTheme = GoogleFonts.interTextTheme(base.textTheme).copyWith(
      titleLarge: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: p.ink,
          letterSpacing: -0.3),
      titleMedium: GoogleFonts.inter(
          fontSize: 16, fontWeight: FontWeight.w700, color: p.ink),
      titleSmall: GoogleFonts.inter(
          fontSize: 13, fontWeight: FontWeight.w600, color: p.ink),
      bodyLarge: GoogleFonts.inter(fontSize: 15, color: p.ink),
      bodyMedium: GoogleFonts.inter(fontSize: 13, color: p.ink),
      bodySmall: GoogleFonts.inter(fontSize: 12, color: p.inkMuted),
      labelLarge: GoogleFonts.inter(
          fontSize: 14, fontWeight: FontWeight.w600, color: p.ink),
      labelMedium: GoogleFonts.inter(
          fontSize: 13, fontWeight: FontWeight.w600, color: p.inkMuted),
      labelSmall: GoogleFonts.inter(
          fontSize: 12, fontWeight: FontWeight.w600, color: p.inkDim),
      displayLarge: AppTextStyles.mono(
          size: 64, color: p.ink, letterSpacing: -3, height: 1),
      displayMedium: AppTextStyles.mono(
          size: 44, color: p.ink, letterSpacing: -1.8, height: 1),
      displaySmall: AppTextStyles.mono(
          size: 30, color: p.ink, letterSpacing: -1, height: 1),
    );

    return ThemeData(
      brightness: brightness,
      primaryColor: brightness == Brightness.dark
          ? const Color(0xFFA9CBE8)
          : AppColors.blueDeep,
      scaffoldBackgroundColor: p.bg,
      canvasColor: p.bg,
      cardColor: p.surface,
      dividerColor: p.border,
      colorScheme: brightness == Brightness.dark
          ? ColorScheme.dark(
              primary: const Color(0xFFA9CBE8),
              onPrimary: AppColors.darkBg,
              secondary: p.accent,
              onSecondary: p.accentInk,
              surface: p.surface,
              onSurface: p.ink,
              error: p.red,
              onError: AppColors.onColor(p.red),
            )
          : ColorScheme.light(
              primary: AppColors.blueDeep,
              onPrimary: Colors.white,
              secondary: p.accent,
              onSecondary: p.accentInk,
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
        iconTheme: IconThemeData(color: p.ink),
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: p.ink,
          letterSpacing: -0.3,
        ),
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
        hintStyle: TextStyle(color: p.inkMuted, fontSize: 14),
        labelStyle: TextStyle(color: p.inkMuted, fontSize: 14),
        floatingLabelStyle: TextStyle(color: p.accentText, fontSize: 14),
        suffixStyle: TextStyle(color: p.inkMuted, fontSize: 14),
        errorStyle: TextStyle(color: p.red, fontSize: 12),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: p.borderStrong)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: p.accentText, width: 2)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: p.red)),
        focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: p.red, width: 2)),
      ),
      filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
        backgroundColor: p.accent,
        foregroundColor: p.accentInk,
        disabledBackgroundColor: p.surface2,
        disabledForegroundColor: p.inkMuted,
        minimumSize: const Size(48, 48),
        textStyle: textTheme.labelLarge,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      )),
      elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
        backgroundColor: p.accent,
        foregroundColor: p.accentInk,
        elevation: 0,
        minimumSize: const Size(48, 48),
        textStyle: textTheme.labelLarge,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      )),
      outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
        foregroundColor: p.ink,
        side: BorderSide(color: p.borderStrong),
        minimumSize: const Size(48, 48),
        textStyle: textTheme.labelLarge,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      )),
      textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
        foregroundColor: p.accentText,
        minimumSize: const Size(48, 48),
        textStyle: textTheme.labelLarge,
      )),
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
        minimumSize: const Size(48, 48),
      )),
      iconTheme: IconThemeData(color: p.ink),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
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
      drawerTheme: DrawerThemeData(
        backgroundColor: p.surface,
        scrimColor: Colors.black.withValues(alpha: 0.5),
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

  static final ThemeData lightTheme =
      _build(brightness: Brightness.light, p: AppPalette.light);
  static final ThemeData darkTheme =
      _build(brightness: Brightness.dark, p: AppPalette.dark);
}
