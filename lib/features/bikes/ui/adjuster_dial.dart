import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:bikesetupapp/common/theme/theme_data.dart';

/// Matching vector glyphs keep knob geometry fixed across selection states.
class AdjusterDial extends StatelessWidget {
  const AdjusterDial({super.key, required this.selected, required this.count});
  final bool selected;
  final int count;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<Color?>(
    tween: ColorTween(end: selected ? context.palette.accentText : context.palette.inkMuted),
    duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 220),
    curve: Curves.easeOutCubic,
    builder: (context, color, _) => SvgPicture.asset(
      'assets/icons/adjuster-${count == 0 ? 'none' : count == 1 ? 'single' : 'dual'}.svg',
      width: 76, height: 44,
      colorFilter: ColorFilter.mode(color ?? context.palette.inkMuted, BlendMode.srcIn),
      excludeFromSemantics: true,
    ),
  );
}
