import 'app_haptics.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:bikesetupapp/common/theme/theme_data.dart';

/// One full-width target for dates, settings and supporting service tools.
class AppValueButton extends StatelessWidget {
  const AppValueButton(
      {super.key,
      required this.label,
      required this.onTap,
      this.value,
      this.icon,
      this.leading});
  final String label;
  final String? value;
  final IconData? icon;
  final Widget? leading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => TextButton(
      onPressed: AppHaptics.wrap(onTap),
      style: TextButton.styleFrom(
          foregroundColor: context.palette.ink,
          backgroundColor: context.palette.surface2,
          padding: const EdgeInsets.all(16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
      child: Row(children: [
        if (leading != null || icon != null) ...[
          leading ?? Icon(icon, size: 20),
          const SizedBox(width: 12)
        ],
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: AppTextStyles.inter(size: 16, color: context.palette.ink)),
          if (value != null) ...[
            const SizedBox(height: 4),
            Text(value!,
                style: AppTextStyles.inter(
                    size: 14, color: context.palette.inkMuted))
          ],
        ])),
        const SizedBox(width: 12),
        Icon(CupertinoIcons.chevron_right,
            size: 16, color: context.palette.inkMuted),
      ]));
}
