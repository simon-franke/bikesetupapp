import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:bikesetupapp/common/ui/bike_icon.dart';
import 'package:bikesetupapp/common/ui/app_components.dart';
import 'package:bikesetupapp/common/theme/theme_data.dart';

class StravaSettings extends StatelessWidget {
  final bool isConnected;
  final int bikeCount;
  final VoidCallback onConnect;
  final VoidCallback onDisconnect;
  final VoidCallback onManageBikes;

  const StravaSettings({
    super.key,
    required this.isConnected,
    required this.bikeCount,
    required this.onConnect,
    required this.onDisconnect,
    required this.onManageBikes,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: p.accent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: BikeIcon(size: AppIconSizes.compact, color: p.accentInk),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Strava',
                    style: AppTextStyles.label.copyWith(color: p.ink),
                  ),
                  Text(
                    isConnected
                        ? (bikeCount > 0
                            ? 'Connected with $bikeCount bike${bikeCount == 1 ? '' : 's'} synced'
                            : 'Connected')
                        : 'Not connected',
                    style: AppTextStyles.caption.copyWith(color: p.inkMuted),
                  ),
                ],
              ),
            ),
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: isConnected ? p.green : p.inkDim,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (isConnected) ...[
          SizedBox(
              width: double.infinity,
              child: AppActionButton(
                outlined: true,
                icon: CupertinoIcons.arrow_right_arrow_left,
                label: 'Manage Strava bikes',
                onPressed: onManageBikes,
              )),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: onDisconnect,
              child: Text(
                'Disconnect',
                style: AppTextStyles.caption.copyWith(color: p.red),
              ),
            ),
          ),
        ] else
          SizedBox(
            width: double.infinity,
            child: AppActionButton(
                label: 'Connect Strava',
                icon: CupertinoIcons.link,
                onPressed: onConnect),
          ),
      ],
    );
  }
}
