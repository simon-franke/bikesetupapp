import 'package:bikesetupapp/common/theme/theme_data.dart';
import '../models/service_icon.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/component_type.dart';

/// Component silhouettes shared by the picker and service overview.
class ServiceComponentIcon extends StatelessWidget {
  const ServiceComponentIcon(
      {super.key,
      required this.type,
      required this.color,
      this.customIcon,
      this.size = AppIconSizes.control});
  final ComponentType type;
  final ServiceIcon? customIcon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final asset = switch (customIcon ?? ServiceIcon.forType(type)) {
      ServiceIcon.tools => null,
      ServiceIcon.chain => 'service-chain',
      ServiceIcon.brakes => 'service-brake',
      ServiceIcon.wheel => 'service-wheel',
      ServiceIcon.fork => 'service-fork',
      ServiceIcon.shock => 'spring',
      ServiceIcon.bearing => 'service-bearing',
      ServiceIcon.headset => 'service-headset',
      ServiceIcon.crank => 'service-crank',
      ServiceIcon.saddle => 'seat',
      ServiceIcon.handlebar => 'service-handlebar',
      ServiceIcon.pedal => 'service-pedal',
      ServiceIcon.cassette => 'service-cassette',
      ServiceIcon.derailleur => 'service-derailleur',
      ServiceIcon.dropper => 'service-dropper',
      ServiceIcon.rotor => 'service-rotor',
      ServiceIcon.bottle => 'service-bottle',
      ServiceIcon.bolt => 'service-bolt',
    };
    if (asset == null) {
      return Icon(CupertinoIcons.wrench, size: size, color: color);
    }
    return SvgPicture.asset('assets/icons/$asset.svg',
        width: size,
        height: size,
        excludeFromSemantics: true,
        colorFilter: ColorFilter.mode(color, BlendMode.srcIn));
  }
}
