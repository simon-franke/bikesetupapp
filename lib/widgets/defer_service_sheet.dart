import 'package:bikesetupapp/widgets/adaptive_modal.dart';
import 'package:bikesetupapp/widgets/app_components.dart';
import 'package:bikesetupapp/app_services/theme_data.dart';
import 'package:bikesetupapp/database_service/service_database.dart';
import 'package:bikesetupapp/models/service_component.dart';
import 'package:bikesetupapp/models/service_entry.dart';
import 'package:bikesetupapp/widgets/setting_value_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';

const int _kDeferDefaultKm = 50;

Future<void> showDeferServiceSheet({
  required BuildContext context,
  required String userID,
  required ServiceComponent component,
  required double currentMileageKm,
}) {
  final db = ServiceDatabaseService(userID);
  int extendKm = _kDeferDefaultKm;

  return showAdaptiveModal<void>(
    context: context,
    builder: (ctx) {
      final p = ctx.palette;
      return Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 16,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppSheetHandle(),
            const SizedBox(height: 18),
            Center(
              child: Text(
                'STILL GOOD FOR',
                style: AppTextStyles.eyebrow(color: p.inkDim),
              ),
            ),
            const SizedBox(height: 8),
            SettingValueEditor(
              initialValue: _kDeferDefaultKm.toDouble(),
              min: 10,
              max: 500,
              step: 1,
              decimals: 0,
              unitLabel: 'km',
              onChanged: (v) => extendKm = v.round(),
            ),
            const SizedBox(height: 22),
            _DeferPrimaryButton(
              label: 'Save',
              onPressed: () {
                final newMileage =
                    (currentMileageKm + extendKm - component.serviceIntervalKm)
                        .clamp(0.0, double.infinity);
                final entry = ServiceEntry(
                  id: const Uuid().v4(),
                  componentId: component.id,
                  mileageAtServiceKm: newMileage,
                  date: DateTime.now().toUtc(),
                  note: 'Checked — still good for $extendKm km',
                );
                db.addServiceEntry(component.id, entry);
                HapticFeedback.lightImpact();
                Navigator.of(ctx).pop();
              },
            ),
          ],
        ),
      );
    },
  );
}

class _DeferPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  const _DeferPrimaryButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
        width: double.infinity,
        child: AppActionButton(label: label, onPressed: onPressed));
  }
}
