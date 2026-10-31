import 'package:cupertino_liquid_glass/cupertino_liquid_glass.dart';
import 'package:flutter/material.dart';
import '../theme/theme_data.dart';

/// Shared floating surface for the workspace navigation and header.
class AppGlassSurface extends StatelessWidget {
  const AppGlassSurface(
      {super.key,
      required this.child,
      this.showShadow = true,
      this.tintColor,
      this.tintOpacity = .78});
  final Widget child;
  final bool showShadow;
  final Color? tintColor;
  final double tintOpacity;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return CupertinoLiquidGlass(
      theme: (dark ? LiquidGlassThemeData.dark() : LiquidGlassThemeData.light())
          .copyWith(
              tintColor: tintColor ?? context.palette.surface,
              tintOpacity: tintOpacity,
              shadows: showShadow ? null : const <BoxShadow>[]),
      borderRadius: BorderRadius.circular(30),
      padding: const EdgeInsets.all(5),
      effectIntensity: .25,
      child: Material(color: Colors.transparent, child: child),
    );
  }
}
