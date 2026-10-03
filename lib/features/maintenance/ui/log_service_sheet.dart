import 'package:bikesetupapp/app/app_dependencies.dart';
import 'package:bikesetupapp/common/ui/adaptive_modal.dart';
import 'package:bikesetupapp/common/ui/app_components.dart';
import 'package:bikesetupapp/common/theme/theme_data.dart';
import 'package:bikesetupapp/features/strava/models/strava_exception.dart';
import 'package:bikesetupapp/features/maintenance/models/service_component.dart';
import 'package:bikesetupapp/features/maintenance/models/service_entry.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

final NumberFormat _kmFormat = NumberFormat('#,###');

Future<void> showLogServiceSheet({
  required BuildContext context,
  required String userID,
  required ServiceComponent component,
  required double currentMileageKm,
  String? stravaGearId,
}) {
  final db = AppDependencies.of(context).forUser(userID);
  final noteController = TextEditingController();
  DateTime selectedDate = DateTime.now();

  double? fetchedMileage = stravaGearId != null ? currentMileageKm : null;
  bool fetchingMileage = false;
  String? mileageError; // 'scope' | 'error' | null
  int fetchGeneration = 0;

  Future<void> fetchMileage(DateTime date, StateSetter setSheetState) async {
    if (stravaGearId == null) return;

    final gen = ++fetchGeneration;
    setSheetState(() {
      fetchingMileage = true;
      fetchedMileage = null;
      mileageError = null;
    });

    final now = DateTime.now();
    final isToday =
        date.year == now.year && date.month == now.month && date.day == now.day;

    if (isToday) {
      if (gen == fetchGeneration) {
        setSheetState(() {
          fetchingMileage = false;
          fetchedMileage = currentMileageKm;
        });
      }
      return;
    }

    try {
      final km =
          await AppDependencies.of(context).stravaConnection.mileageAtDate(
                gearId: stravaGearId,
                date: date,
                currentTotalKm: currentMileageKm,
              );
      if (gen != fetchGeneration) return;

      if (km == null) {
        setSheetState(() {
          fetchingMileage = false;
          mileageError = 'error';
        });
        return;
      }

      setSheetState(() {
        fetchingMileage = false;
        fetchedMileage = km;
      });
    } on StravaInsufficientScopeException {
      if (gen != fetchGeneration) return;
      setSheetState(() {
        fetchingMileage = false;
        mileageError = 'scope';
      });
    }
  }

  return showAdaptiveModal<void>(
    context: context,
    builder: (ctx) {
      final p = ctx.palette;
      return StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
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
              Text(
                'LOG SERVICE',
                style: AppTextStyles.eyebrow(color: p.inkDim),
              ),
              const SizedBox(height: 14),
              _SheetFieldLabel(label: 'Date'),
              const SizedBox(height: 6),
              _SheetDateField(
                date: selectedDate,
                onTap: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: selectedDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    setSheetState(() => selectedDate = picked);
                    fetchMileage(picked, setSheetState);
                  }
                },
              ),
              if (stravaGearId != null) ...[
                const SizedBox(height: 10),
                _buildMileageStatus(
                    ctx, fetchingMileage, fetchedMileage, mileageError),
              ],
              const SizedBox(height: 14),
              _SheetFieldLabel(label: 'Note'),
              const SizedBox(height: 6),
              TextField(
                controller: noteController,
                cursorColor: p.accent,
                style: AppTextStyles.inter(size: 13, color: p.ink),
                decoration: InputDecoration(
                    hintText: 'Optional — e.g. new chain, cleaned only'),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: _SheetPrimaryButton(
                      label: 'Log service',
                      enabled: !fetchingMileage,
                      onPressed: () {
                        final note = noteController.text.trim();
                        final entry = ServiceEntry(
                          id: const Uuid().v4(),
                          componentId: component.id,
                          mileageAtServiceKm: fetchedMileage,
                          date: selectedDate.toUtc(),
                          note: note.isNotEmpty ? note : null,
                        );
                        db.maintenance.addServiceEntry(component.id, entry);
                        HapticFeedback.lightImpact();
                        Navigator.of(ctx).pop();
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}

Widget _buildMileageStatus(
  BuildContext ctx,
  bool fetchingMileage,
  double? fetchedMileage,
  String? mileageError,
) {
  final p = ctx.palette;
  if (fetchingMileage) {
    return Row(
      children: [
        const SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator.adaptive(strokeWidth: 2),
        ),
        const SizedBox(width: 8),
        Text(
          'Fetching from Strava…',
          style: AppTextStyles.inter(size: 11, color: p.inkMuted),
        ),
      ],
    );
  }

  if (mileageError == 'scope') {
    return Row(
      children: [
        Icon(Icons.warning_amber_rounded, size: 14, color: p.red),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            'Re-connect Strava in settings to fetch mileage',
            style: AppTextStyles.inter(
              size: 11,
              weight: FontWeight.w600,
              color: p.red,
            ),
          ),
        ),
      ],
    );
  }

  if (mileageError == 'error') {
    return Row(
      children: [
        Icon(Icons.close_rounded, size: 14, color: p.red),
        const SizedBox(width: 6),
        Text(
          'Could not fetch mileage from Strava',
          style: AppTextStyles.inter(
            size: 11,
            weight: FontWeight.w600,
            color: p.red,
          ),
        ),
      ],
    );
  }

  if (fetchedMileage != null) {
    return Row(
      children: [
        Icon(Icons.route_rounded, size: 14, color: p.amber),
        const SizedBox(width: 6),
        Text(
          '${_kmFormat.format(fetchedMileage.round())} km at service',
          style: AppTextStyles.mono(
            size: 11,
            weight: FontWeight.w700,
            color: p.amber,
          ),
        ),
      ],
    );
  }

  return const SizedBox.shrink();
}

class _SheetFieldLabel extends StatelessWidget {
  final String label;
  const _SheetFieldLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return AppFieldLabel(label);
  }
}

class _SheetDateField extends StatelessWidget {
  final DateTime date;
  final VoidCallback onTap;
  const _SheetDateField({required this.date, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Material(
      color: p.surface2,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: p.borderStrong),
          ),
          child: Row(
            children: [
              Icon(Icons.calendar_today_rounded, size: 14, color: p.inkMuted),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  DateFormat('MMM d, yyyy').format(date),
                  style: AppTextStyles.inter(
                    size: 13,
                    weight: FontWeight.w600,
                    color: p.ink,
                  ),
                ),
              ),
              Icon(Icons.expand_more_rounded, size: 16, color: p.inkDim),
            ],
          ),
        ),
      ),
    );
  }
}

class _SheetPrimaryButton extends StatelessWidget {
  final String label;
  final bool enabled;
  final VoidCallback onPressed;
  const _SheetPrimaryButton({
    required this.label,
    required this.enabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AppActionButton(label: label, onPressed: enabled ? onPressed : null);
  }
}
