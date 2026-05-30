import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class FieldIcon extends StatelessWidget {
  final String asset;
  final double size;
  final Color color;

  const FieldIcon({
    super.key,
    required this.asset,
    required this.size,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      asset,
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
  }
}
