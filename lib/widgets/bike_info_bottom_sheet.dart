import 'package:bikesetupapp/app_services/theme_data.dart';
import 'package:bikesetupapp/bike_enums/bike_type.dart';
import 'package:bikesetupapp/bike_enums/new_bike_mode.dart';
import 'package:bikesetupapp/database_service/database.dart';
import 'package:bikesetupapp/widgets/new_bike_bottom_sheet.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

Future<void> showBikeInfoSheet(
  BuildContext context,
  User user,
  String uBikeID,
  String uSetupID,
  String setupName,
  String bikeName,
  BikeType bikeType, {
  required void Function(String, String, BikeType, String, String) onBikeSelected,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: context.palette.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (_) => _BikeInfoSheetContent(
      user: user,
      uBikeID: uBikeID,
      uSetupID: uSetupID,
      setupName: setupName,
      bikeName: bikeName,
      bikeType: bikeType,
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
  final BikeType bikeType;
  final void Function(String, String, BikeType, String, String) onBikeSelected;

  const _BikeInfoSheetContent({
    required this.user,
    required this.uBikeID,
    required this.uSetupID,
    required this.setupName,
    required this.bikeName,
    required this.bikeType,
    required this.onBikeSelected,
  });

  List<(String, String)> _buildRows(Map<String, dynamic> data) {
    return [
      if (bikeType.hasFork) ('Fork', data['fork']?.toString() ?? '—'),
      if (bikeType.hasShock) ('Shock', data['shock']?.toString() ?? '—'),
      if (bikeType.hasFork)
        ('Front travel', '${data['front_travel']?.toString() ?? '—'} mm'),
      if (bikeType.hasShock)
        ('Rear travel', '${data['rear_travel']?.toString() ?? '—'} mm'),
      ('Front wheel', '${data['front_wheel_size']?.toString() ?? '—'}"'),
      ('Rear wheel', '${data['rear_wheel_size']?.toString() ?? '—'}"'),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 12),
        Center(
          child: Container(
            width: 36, height: 4,
            decoration: BoxDecoration(
              color: p.borderStrong,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
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
                      bikeType.bikeType.toUpperCase(),
                      style: AppTextStyles.inter(
                        size: 10, weight: FontWeight.w700,
                        color: p.inkDim, letterSpacing: 1.4,
                      ),
                    ),
                    Text(
                      setupName,
                      style: AppTextStyles.inter(
                        size: 20, weight: FontWeight.w700,
                        color: p.ink, letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.edit_outlined, color: p.ink),
                onPressed: () {
                  Navigator.of(context).pop();
                  showNewBikeSheet(
                    context, user, NewBikeMode.editSetup,
                    bikeType: bikeType,
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
            future: DatabaseService(user.uid).getSetupInformation(uBikeID, uSetupID),
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
              final data = snapshot.data!.data() as Map<String, dynamic>;
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
            label.toUpperCase(),
            style: AppTextStyles.inter(
              size: 10, weight: FontWeight.w700,
              color: p.inkDim, letterSpacing: 1.2,
            ),
          ),
          Text(
            value,
            style: AppTextStyles.inter(
              size: 14, weight: FontWeight.w600, color: p.ink,
            ),
          ),
        ],
      ),
    );
  }
}
