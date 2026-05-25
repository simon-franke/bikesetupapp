import 'package:bikesetupapp/app_services/theme_data.dart';
import 'package:flutter/material.dart';

enum ActiveView { setup, services }

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
      child: Tooltip(
        message: label,
        child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(icon, size: 15, color: fg),
            Positioned(
              top: -3,
              right: -3,
              child: AnimatedScale(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutBack,
                scale: showAlert ? 1.0 : 0.0,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 180),
                  opacity: showAlert ? 1.0 : 0.0,
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
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }
}
