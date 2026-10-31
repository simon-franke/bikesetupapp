import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Lucide bicycle glyph, with a stroke weight matching our outline controls.
class BikeIcon extends StatelessWidget {
  const BikeIcon({super.key, this.size, this.color});

  final double? size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = IconTheme.of(context);
    return SvgPicture.asset(
      'assets/icons/bike.svg',
      width: size ?? theme.size ?? 24,
      height: size ?? theme.size ?? 24,
      colorFilter: ColorFilter.mode(color ?? theme.color ?? Colors.black, BlendMode.srcIn),
      excludeFromSemantics: true,
    );
  }
}
