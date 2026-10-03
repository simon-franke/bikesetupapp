import '../models/active_view.dart';
import 'package:bikesetupapp/common/theme/theme_data.dart';
import 'package:flutter/material.dart';

export '../models/active_view.dart';

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
    return Material(
      color: p.surface2,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: Row(
          children: [
            Expanded(
              child: _Tab(
                label: 'Setup',
                icon: Icons.tune_rounded,
                isActive: activeView == ActiveView.setup,
                onTap: () => onChanged(ActiveView.setup),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: _Tab(
                label: 'Service',
                icon: Icons.build_outlined,
                isActive: activeView == ActiveView.services,
                showAlert: showServiceAlert,
                onTap: () => onChanged(ActiveView.services),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final bool showAlert;
  final VoidCallback onTap;

  const _Tab({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.onTap,
    this.showAlert = false,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final fg = isActive ? p.cardInk : p.inkMuted;
    return Semantics(
      button: true,
      selected: isActive,
      label: showAlert ? '$label, maintenance due' : label,
      onTap: onTap,
      excludeSemantics: true,
      child: Material(
        color: isActive ? p.card : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 17, color: fg),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      label,
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                            fontSize: 14,
                            fontWeight:
                                isActive ? FontWeight.w600 : FontWeight.w500,
                            color: fg,
                          ),
                    ),
                  ),
                  if (showAlert) ...[
                    const SizedBox(width: 6),
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: p.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
