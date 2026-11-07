import 'package:flutter/cupertino.dart';
import 'package:bikesetupapp/common/theme/theme_data.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MileageBanner extends StatelessWidget {
  final double? mileageKm;
  final EdgeInsetsGeometry margin;
  final DateTime? lastSyncTime;
  final bool isLoading;
  final bool isConnected;
  final VoidCallback onSync;
  final VoidCallback? onConnect;

  const MileageBanner({
    super.key,
    required this.mileageKm,
    this.margin = const EdgeInsets.fromLTRB(14, 8, 14, 12),
    this.lastSyncTime,
    this.isLoading = false,
    this.isConnected = false,
    required this.onSync,
    this.onConnect,
  });

  String _syncLabel() {
    if (isLoading) return 'Syncing mileage…';
    if (!isConnected) return 'Connect Strava to track ride distance.';
    if (mileageKm == null) {
      return 'Link this bike to a Strava bike in Settings.';
    }
    if (lastSyncTime == null) return 'Mileage from Strava';
    return 'Synced ${DateFormat.MMMd().add_Hm().format(lastSyncTime!.toLocal())}';
  }

  @override
  Widget build(BuildContext context) {
    final ink = context.palette.ink;
    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Bike mileage', style: AppTextStyles.body.copyWith(color: ink)),
        const SizedBox(height: 4),
        Text(
          mileageKm == null
              ? 'Not available'
              : '${NumberFormat('#,###').format(mileageKm!.round())} km',
          style: AppTextStyles.heading.copyWith(color: ink),
        ),
        const SizedBox(height: 4),
        Text(_syncLabel(),
            style:
                AppTextStyles.body.copyWith(color: context.palette.inkMuted)),
      ],
    );
    final action = TextButton.icon(
      onPressed: isLoading ? null : (isConnected ? onSync : onConnect),
      style: TextButton.styleFrom(
        foregroundColor: context.palette.accentText,
        disabledForegroundColor: ink,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        minimumSize: const Size(0, 44),
        textStyle: AppTextStyles.label,
      ),
      icon: isLoading
          ? SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: ink))
          : Icon(
              isConnected
                  ? CupertinoIcons.arrow_2_circlepath
                  : CupertinoIcons.link,
              size: AppIconSizes.compact),
      label: Text(isLoading
          ? 'Syncing'
          : isConnected
              ? 'Sync Strava'
              : 'Connect Strava'),
    );
    return Container(
      width: double.infinity,
      margin: margin,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: context.palette.surface,
          borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        details,
        const SizedBox(height: 16),
        action,
      ]),
    );
  }
}
