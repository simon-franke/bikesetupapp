import 'package:bikesetupapp/common/ui/app_components.dart';
import 'package:bikesetupapp/features/setups/models/setup_configuration.dart';
import 'package:bikesetupapp/app/app_dependencies.dart';
import 'package:bikesetupapp/common/ui/app_sheet.dart';
import 'package:bikesetupapp/common/theme/theme_data.dart';
import 'package:bikesetupapp/features/bikes/models/new_bike_mode.dart';
import 'package:bikesetupapp/features/bikes/ui/new_bike_bottom_sheet.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

Future<void> showBikeInfoSheet(
  BuildContext context,
  User user,
  String uBikeID,
  String uSetupID,
  String setupName,
  String bikeName, {
  required void Function(String, String, String, String) onBikeSelected,
}) {
  return showAppSheet<void>(
    context: context,
    builder: (_) => _BikeInfoSheetContent(
      user: user,
      uBikeID: uBikeID,
      uSetupID: uSetupID,
      setupName: setupName,
      bikeName: bikeName,
      onBikeSelected: onBikeSelected,
    ),
  );
}

class _BikeInfoSheetContent extends StatelessWidget {
  final User user;
  final String uBikeID;
  final String uSetupID;
  final String setupName;
  final String bikeName;

  final void Function(String, String, String, String) onBikeSelected;

  const _BikeInfoSheetContent({
    required this.user,
    required this.uBikeID,
    required this.uSetupID,
    required this.setupName,
    required this.bikeName,
    required this.onBikeSelected,
  });

  List<(String, String)> _buildRows(Map<String, dynamic> data) {
    final config = SetupConfiguration.fromInformation(data);
    final fork = config?.fields.containsKey('Fork') ??
        (data['fork'] != null && data['fork'] != 'None');
    final shock = config?.fields.containsKey('Shock') ??
        (data['shock'] != null && data['shock'] != 'None');
    String value(String key, [String unit = '']) {
      final raw = data[key]?.toString().trim() ?? '';
      return raw.isEmpty ? '' : '$raw$unit';
    }

    return [
      if (fork) ...[
        ('Fork', value('fork')),
        ('Fork model', value('fork_model')),
        ('Fork travel', value('front_travel', ' mm')),
      ],
      if (shock) ...[
        ('Shock', value('shock')),
        ('Shock model', value('shock_model')),
        ('Rear wheel travel', value('rear_travel', ' mm')),
      ],
      ('Front wheel', value('front_wheel_size')),
      ('Rear wheel', value('rear_wheel_size')),
      if (data['frame_reach']?.toString().isNotEmpty == true)
        ('Frame reach', value('frame_reach', ' mm')),
      if (data['frame_stack']?.toString().isNotEmpty == true)
        ('Frame stack', value('frame_stack', ' mm')),
    ].where((row) => row.$2.isNotEmpty).toList();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 12),
        const AppSheetHandle(),
        const SizedBox(height: 18),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 12, 0),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bikeName,
                      style: AppTextStyles.inter(
                        size: 12,
                        weight: FontWeight.w700,
                        color: p.inkDim,
                        letterSpacing: 1.4,
                      ),
                    ),
                    Text(
                      setupName,
                      style: AppTextStyles.inter(
                        size: 20,
                        weight: FontWeight.w700,
                        color: p.ink,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
              ),
              AppObjectMenu(
                tooltip: 'Setup options',
                title: setupName,
                onRename: () {
                  Navigator.of(context).pop();
                  showNewBikeSheet(
                    context,
                    user,
                    NewBikeMode.editSetup,
                    uBikeID: uBikeID,
                    bikeName: bikeName,
                    uSetupID: uSetupID,
                    setupName: setupName,
                    onBikeSelected: onBikeSelected,
                  );
                },
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: FutureBuilder(
            future: AppDependencies.of(context)
                .forUser(user.uid)
                .setups
                .getSetupInformation(uBikeID, uSetupID),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator.adaptive()),
                );
              }
              if (snapshot.hasError || snapshot.data == null) {
                return Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Text(
                      'Failed to load',
                      style: AppTextStyles.inter(size: 13, color: p.red),
                    ),
                  ),
                );
              }
              final data = snapshot.data!;
              final rows = _buildRows(data);
              return Container(
                decoration: BoxDecoration(
                  color: p.surface,
                  border: Border.all(color: p.border),
                  borderRadius: BorderRadius.circular(14),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (int i = 0; i < rows.length; i++) ...[
                      _InfoRow(label: rows[i].$1, value: rows[i].$2),
                      if (i < rows.length - 1)
                        Divider(height: 1, color: p.border),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.inter(
              size: 12,
              weight: FontWeight.w700,
              color: p.inkDim,
              letterSpacing: 0,
            ),
          ),
          Text(
            value,
            style: AppTextStyles.inter(
              size: 14,
              weight: FontWeight.w600,
              color: p.ink,
            ),
          ),
        ],
      ),
    );
  }
}
