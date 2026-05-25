import 'package:bikesetupapp/app_services/theme_data.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MileageBanner extends StatelessWidget {
  final double? mileageKm;
  final DateTime? lastSyncTime;
  final bool isLoading;
  final bool isConnected;
  final VoidCallback onSync;
  final VoidCallback? onConnect;

  const MileageBanner({
    super.key,
    required this.mileageKm,
    this.lastSyncTime,
    this.isLoading = false,
    this.isConnected = false,
    required this.onSync,
    this.onConnect,
  });

  String _formatSyncTime() {
    if (lastSyncTime == null) return 'Never synced';
    final diff = DateTime.now().toUtc().difference(lastSyncTime!);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return 'Last sync ${diff.inMinutes} min ago';
    if (diff.inHours < 24) return 'Last sync ${diff.inHours}h ago';
    return 'Last sync ${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 240),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SizeTransition(
          sizeFactor: animation,
          axisAlignment: -1,
          child: child,
        ),
      ),
      layoutBuilder: (currentChild, previousChildren) => Stack(
        alignment: Alignment.topCenter,
        children: [
          ...previousChildren,
          if (currentChild != null) currentChild,
        ],
      ),
      child: isConnected
          ? KeyedSubtree(
              key: const ValueKey('connected'),
              child: _buildConnected(context),
            )
          : _NotConnectedBanner(
              key: const ValueKey('not_connected'),
              onConnect: onConnect,
            ),
    );
  }

  Widget _buildConnected(BuildContext context) {
    final p = context.palette;
    final formatter = NumberFormat('#,###');
    final mileageText =
        mileageKm != null ? formatter.format(mileageKm!.round()) : '--';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: p.surface,
        border: Border.all(color: p.border),
        borderRadius: BorderRadius.circular(18),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            top: 0, left: 0, right: 0, height: 28,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      p.accent.withValues(alpha: 0.18),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 16, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.local_fire_department_rounded,
                              size: 14, color: p.accent),
                          const SizedBox(width: 5),
                          Text(
                            'Total mileage · synced'.toUpperCase(),
                            style: AppTextStyles.inter(
                              size: 9,
                              weight: FontWeight.w700,
                              color: p.inkDim,
                              letterSpacing: 1.4,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            mileageText,
                            style: AppTextStyles.mono(
                              size: 36,
                              weight: FontWeight.w700,
                              color: p.ink,
                              letterSpacing: -1.5,
                              height: 1,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'km',
                            style: AppTextStyles.inter(
                              size: 13,
                              weight: FontWeight.w600,
                              color: p.inkMuted,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatSyncTime(),
                        style: AppTextStyles.inter(
                          size: 10,
                          color: p.inkDim,
                        ),
                      ),
                    ],
                  ),
                ),
                _SyncButton(loading: isLoading, onTap: onSync),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SyncButton extends StatelessWidget {
  final bool loading;
  final VoidCallback onTap;
  const _SyncButton({required this.loading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Material(
      color: p.accent,
      borderRadius: BorderRadius.circular(9),
      child: InkWell(
        onTap: loading ? null : onTap,
        borderRadius: BorderRadius.circular(9),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (loading)
                SizedBox(
                  width: 12, height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(p.accentInk),
                  ),
                )
              else
                Icon(Icons.refresh_rounded, size: 13, color: p.accentInk),
              const SizedBox(width: 5),
              Text(
                'SYNC',
                style: AppTextStyles.inter(
                  size: 11,
                  weight: FontWeight.w700,
                  color: p.accentInk,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotConnectedBanner extends StatelessWidget {
  final VoidCallback? onConnect;
  const _NotConnectedBanner({super.key, this.onConnect});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      padding: const EdgeInsets.fromLTRB(18, 16, 16, 16),
      decoration: BoxDecoration(
        color: p.surface,
        border: Border.all(color: p.border),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Connect Strava to track mileage',
                  style: AppTextStyles.inter(
                    size: 13,
                    weight: FontWeight.w600,
                    color: p.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Automatically sync your ride distance',
                  style: AppTextStyles.inter(size: 11, color: p.inkDim),
                ),
              ],
            ),
          ),
          if (onConnect != null)
            Material(
              color: p.accent,
              borderRadius: BorderRadius.circular(9),
              child: InkWell(
                onTap: onConnect,
                borderRadius: BorderRadius.circular(9),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Text(
                    'CONNECT',
                    style: AppTextStyles.inter(
                      size: 11,
                      weight: FontWeight.w700,
                      color: p.accentInk,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
