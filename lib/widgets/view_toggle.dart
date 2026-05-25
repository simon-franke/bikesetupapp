import 'package:bikesetupapp/app_services/theme_data.dart';
import 'package:flutter/material.dart';

enum ActiveView { setup, services }

/// Segmented Setup/Service toggle that lives in the top bar.
/// `surface-2` capsule with two pills; the active pill flips to the paper-white card colour.
class ViewToggle extends StatelessWidget {
  final ActiveView activeView;
  final ValueChanged<ActiveView> onChanged;
  final bool showServiceAlert;

  const ViewToggle({
    super.key,
    required this.activeView,
    required this.onChanged,
    this.showServiceAlert = false,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: p.surface2,
        border: Border.all(color: p.border),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Pill(
            label: 'Setup',
            icon: Icons.tune_rounded,
            isActive: activeView == ActiveView.setup,
            onTap: () => onChanged(ActiveView.setup),
          ),
          const SizedBox(width: 2),
          _Pill(
            label: 'Service',
            icon: Icons.build_rounded,
            isActive: activeView == ActiveView.services,
            showAlert: showServiceAlert,
            onTap: () => onChanged(ActiveView.services),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final bool showAlert;
  final VoidCallback onTap;

  const _Pill({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.onTap,
    this.showAlert = false,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final bg = isActive ? p.card : Colors.transparent;
    final fg = isActive ? p.cardInk : p.inkMuted;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 13, color: fg),
                const SizedBox(width: 6),
                Text(
                  label.toUpperCase(),
                  style: AppTextStyles.inter(
                    size: 11,
                    weight: FontWeight.w700,
                    color: fg,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
            if (showAlert)
              Positioned(
                top: -3,
                right: -3,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: p.red,
                    shape: BoxShape.circle,
                    border: Border.all(color: p.bg, width: 1.5),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
