import 'package:bikesetupapp/common/ui/app_haptics.dart';
import 'package:flutter/material.dart';
import 'package:bikesetupapp/common/theme/theme_data.dart';

class SetupCard extends StatelessWidget {
  const SetupCard(
      {super.key, required this.child, this.padding = 20, this.onTap});

  final double padding;
  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
          color: context.palette.surface,
          borderRadius: BorderRadius.circular(19),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
              onTap: AppHaptics.wrap(onTap),
              child: Padding(padding: EdgeInsets.all(padding), child: child))));
}
