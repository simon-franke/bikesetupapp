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

  static const _activeColor = Color(0xFFD4883A);
  static const _alertColor = Color(0xFFE05545);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ToggleIcon(
            icon: Icons.settings,
            isActive: activeView == ActiveView.setup,
            onTap: () => onChanged(ActiveView.setup),
          ),
          const SizedBox(width: 2),
          Stack(
            clipBehavior: Clip.none,
            children: [
              _ToggleIcon(
                icon: Icons.build,
                isActive: activeView == ActiveView.services,
                onTap: () => onChanged(ActiveView.services),
              ),
              if (showServiceAlert)
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: _alertColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(context).primaryColor,
                        width: 2,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ToggleIcon extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _ToggleIcon({
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 32,
        height: 28,
        decoration: BoxDecoration(
          color: isActive ? ViewToggle._activeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Icon(
          icon,
          size: 16,
          color: isActive
              ? Colors.black87
              : Colors.white.withValues(alpha: 0.3),
        ),
      ),
    );
  }
}
