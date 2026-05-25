import 'package:bikesetupapp/app_pages/settings_page.dart';
import 'package:bikesetupapp/app_services/app_routes.dart';
import 'package:bikesetupapp/app_services/theme_data.dart';
import 'package:bikesetupapp/bike_enums/new_bike_mode.dart';
import 'package:bikesetupapp/bike_enums/bike_type.dart';
import 'package:bikesetupapp/widgets/drawer_bike_list.dart';
import 'package:bikesetupapp/widgets/new_bike_bottom_sheet.dart';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SidebarContent extends StatelessWidget {
  final String bikeName;
  final BikeType bikeType;
  final String chosenSetup;
  final User? user;
  final bool isInDrawer;
  final void Function(String, String, BikeType, String, String) onBikeSelected;

  const SidebarContent({
    super.key,
    required this.bikeName,
    required this.bikeType,
    required this.chosenSetup,
    required this.user,
    required this.onBikeSelected,
    this.isInDrawer = false,
  });

  String _initials() {
    final u = user;
    if (u == null) return '?';
    final name = u.displayName?.trim() ?? '';
    if (name.isEmpty) return u.isAnonymous ? 'AN' : '?';
    final parts = name.split(' ').where((s) => s.isNotEmpty).toList();
    if (parts.length == 1) {
      return parts.first.substring(0, parts.first.length.clamp(0, 2)).toUpperCase();
    }
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      color: p.surface,
      child: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, isInDrawer ? 14 : 12, 16, 14),
              child: Row(
                children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [p.accent, const Color(0xFFE0522A)],
                      ),
                      image: (user?.photoURL != null)
                          ? DecorationImage(image: NetworkImage(user!.photoURL!), fit: BoxFit.cover)
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: (user?.photoURL == null)
                        ? Text(
                            _initials(),
                            style: AppTextStyles.inter(
                              size: 13, weight: FontWeight.w800,
                              color: p.accentInk,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          user?.displayName ?? (user?.isAnonymous == true ? 'Anonymous' : 'Bike Setup'),
                          style: AppTextStyles.inter(
                            size: 13, weight: FontWeight.w700, color: p.ink,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (user?.email != null)
                          Text(
                            user!.email!,
                            style: AppTextStyles.inter(size: 11, color: p.inkMuted),
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Divider(height: 1, color: p.border),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 4, 10, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 14, 4, 10),
                    child: _MiniSectionLabel(text: 'My garage'),
                  ),
                  Expanded(
                    child: BikeList(
                      user: user,
                      bikeName: bikeName,
                      onBikeSelected: onBikeSelected,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Divider(height: 1, color: p.border),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Row(
                children: [
                  Expanded(
                    child: _PrimaryFooterButton(
                      icon: Icons.add_rounded,
                      label: 'New bike',
                      onTap: () {
                        if (user != null) {
                          if (isInDrawer) Navigator.of(context).pop();
                          showNewBikeSheet(
                            context, user!, NewBikeMode.newBike,
                            onBikeSelected: onBikeSelected,
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('No User logged in')),
                          );
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  _IconFooterButton(
                    icon: Icons.settings_rounded,
                    tooltip: 'Settings',
                    onTap: () {
                      Navigator.of(context).push(AppRoutes.fadeSlide(SettingsPage(
                        bikeName: bikeName,
                        bikeType: bikeType,
                        chosenSetup: chosenSetup,
                      )));
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniSectionLabel extends StatelessWidget {
  final String text;
  const _MiniSectionLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Row(
      children: [
        Container(width: 10, height: 1, color: p.borderStrong),
        const SizedBox(width: 8),
        Text(
          text.toUpperCase(),
          style: AppTextStyles.eyebrow(color: p.inkDim),
        ),
        const SizedBox(width: 8),
        Expanded(child: Container(height: 1, color: p.border)),
      ],
    );
  }
}

class _PrimaryFooterButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _PrimaryFooterButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Material(
      color: p.accent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: p.accentInk),
              const SizedBox(width: 8),
              Text(
                label,
                style: AppTextStyles.inter(
                  size: 13, weight: FontWeight.w700, color: p.accentInk,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconFooterButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  const _IconFooterButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Material(
      color: p.surface2,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Tooltip(
          message: tooltip,
          child: Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: p.border),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 18, color: p.inkMuted),
          ),
        ),
      ),
    );
  }
}
