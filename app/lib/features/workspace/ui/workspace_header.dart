import 'package:bikesetupapp/common/ui/app_haptics.dart';
import 'package:bikesetupapp/common/ui/app_glass_surface.dart';
import 'package:flutter/cupertino.dart';
import 'workspace_activity_title.dart';
import 'package:bikesetupapp/common/theme/theme_data.dart';
import 'package:bikesetupapp/features/workspace/ui/view_toggle.dart';

import 'package:flutter/material.dart';

class WorkspaceHeader extends StatelessWidget implements PreferredSizeWidget {
  const WorkspaceHeader(
      {super.key,
      required this.height,
      required this.uid,
      required this.bikeId,
      required this.bikeName,
      required this.setupName,
      required this.mileageKm,
      required this.activeView,
      required this.onChooseBike,
      required this.onRideActivity,
      required this.onSettings});

  final double height;
  final String? uid;
  final String bikeId, bikeName, setupName;
  final double? mileageKm;
  final ActiveView activeView;
  final VoidCallback onChooseBike, onRideActivity, onSettings;

  @override
  Size get preferredSize => Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return PreferredSize(
      preferredSize: Size.fromHeight(height),
      child: Stack(
        clipBehavior: Clip.none,
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [p.bg, p.bg, p.bg.withValues(alpha: 0)],
                    stops: const [0, .7, 1],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
              bottom: false,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Align(
                  alignment: Alignment.center,
                  child: AppGlassSurface(
                      child: Row(children: [
                    Expanded(
                        child: Material(
                      color: p.ink.withValues(alpha: .07),
                      borderRadius: BorderRadius.circular(25),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(25),
                        onTap: AppHaptics.wrap(onChooseBike),
                        child: Semantics(
                          button: true,
                          label: activeView == ActiveView.services
                              ? 'Choose bike'
                              : 'Choose bike and setup',
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            child: ConstrainedBox(
                                constraints: BoxConstraints(
                                    minHeight: MediaQuery.textScalerOf(context)
                                                .scale(24) *
                                            1.4 +
                                        MediaQuery.textScalerOf(context)
                                                .scale(12) *
                                            1.4 +
                                        2),
                                child: Row(children: [
                                  Expanded(
                                      child: WorkspaceActivityTitle(
                                    key: ValueKey('activity_$uid/$bikeId'),
                                    uid: uid,
                                    bikeId: bikeId,
                                    mileageKm: mileageKm,
                                    bikeName: bikeName,
                                    setupName: setupName,
                                    bikeOnly: activeView == ActiveView.services,
                                  )),
                                  const SizedBox(width: 8),
                                  Icon(CupertinoIcons.chevron_down,
                                      color: p.inkMuted,
                                      size: AppIconSizes.compact),
                                ])),
                          ),
                        ),
                      ),
                    )),
                    TweenAnimationBuilder<double>(
                      tween:
                          Tween(end: activeView == ActiveView.services ? 1 : 0),
                      duration: MediaQuery.disableAnimationsOf(context)
                          ? Duration.zero
                          : const Duration(milliseconds: 280),
                      curve: Curves.easeInOutCubic,
                      builder: (context, progress, child) => ClipRect(
                        child: Align(
                          widthFactor: progress,
                          heightFactor: 1,
                          child: IgnorePointer(
                            ignoring: activeView != ActiveView.services,
                            child: ExcludeSemantics(
                              excluding: activeView != ActiveView.services,
                              child: Opacity(
                                  opacity: progress,
                                  child: Transform.scale(
                                      scale: .8 + .2 * progress, child: child)),
                            ),
                          ),
                        ),
                      ),
                      child: IconButton(
                        tooltip: 'Ride activity',
                        icon: Icon(Icons.auto_stories_outlined,
                            size: AppIconSizes.control, color: p.inkMuted),
                        onPressed: onRideActivity,
                      ),
                    ),
                    Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: IconButton(
                          tooltip: 'Settings',
                          icon: const Icon(CupertinoIcons.gear_alt,
                              size: AppIconSizes.control),
                          onPressed: onSettings,
                        )),
                  ])),
                ),
              )),
        ],
      ),
    );
  }
}
