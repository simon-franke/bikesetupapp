import 'package:bikesetupapp/app/app_dependencies.dart';
import 'package:bikesetupapp/common/ui/adaptive_modal.dart';
import 'package:bikesetupapp/common/ui/app_components.dart';
import 'package:bikesetupapp/common/theme/theme_data.dart';
import 'package:bikesetupapp/common/models/command_result.dart';
import 'package:bikesetupapp/common/ui/failure_message.dart';
import '../controllers/service_editor_controller.dart';
import '../models/service_component.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

final NumberFormat _kmFormat = NumberFormat('#,###');

Future<void> showLogServiceSheet(
        {required BuildContext context,
        required String userID,
        required ServiceComponent component,
        required double currentMileageKm,
        String? stravaGearId}) =>
    showAdaptiveModal<void>(
        context: context,
        builder: (_) => _LogServiceForm(
            userId: userID,
            component: component,
            mileageKm: currentMileageKm,
            gearId: stravaGearId));

class _LogServiceForm extends StatefulWidget {
  const _LogServiceForm(
      {required this.userId,
      required this.component,
      required this.mileageKm,
      this.gearId});
  final String userId;
  final ServiceComponent component;
  final double mileageKm;
  final String? gearId;
  @override
  State<_LogServiceForm> createState() => _LogServiceFormState();
}

class _LogServiceFormState extends State<_LogServiceForm> {
  late final ServiceEditorController _controller;
  DateTime _selectedDate = DateTime.now();
  String _note = '';
  @override
  void initState() {
    super.initState();
    final dependencies = AppDependencies.of(context);
    _controller = ServiceEditorController(
        dependencies.forUser(widget.userId).maintenance,
        dependencies.stravaConnection,
        component: widget.component,
        currentMileageKm: widget.mileageKm,
        gearId: widget.gearId)
      ..addListener(_changed);
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    if (_controller.saving) return;
    final picked = await showDatePicker(
        context: context,
        initialDate: _selectedDate,
        firstDate: DateTime(2000),
        lastDate: DateTime.now());
    if (!mounted || picked == null || _controller.saving) return;
    setState(() => _selectedDate = picked);
    try {
      await _controller.fetchMileage(picked);
    } catch (error, stack) {
      FlutterError.reportError(
          FlutterErrorDetails(exception: error, stack: stack));
    }
  }

  Future<void> _save() async {
    try {
      final result =
          await _controller.logService(date: _selectedDate, note: _note);
      if (!mounted || !result.isSuccess) return;
      HapticFeedback.lightImpact();
      Navigator.of(context).pop();
    } catch (error, stack) {
      FlutterError.reportError(
          FlutterErrorDetails(exception: error, stack: stack));
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final mileageError = _controller.mileageError;
    final scopeError = mileageError is AppFailure &&
        mileageError.code == FailureCode.insufficientActivityScope;
    final saveError = _controller.saveError;
    return Padding(
        padding: EdgeInsets.fromLTRB(
            20, 16, 20, MediaQuery.viewInsetsOf(context).bottom + 24),
        child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppSheetHandle(),
              const SizedBox(height: 18),
              Text('LOG SERVICE',
                  style: AppTextStyles.eyebrow(color: p.inkDim)),
              const SizedBox(height: 14),
              const AppFieldLabel('Date'),
              const SizedBox(height: 6),
              _SheetDateField(date: _selectedDate, onTap: _pickDate),
              if (widget.gearId != null) ...[
                const SizedBox(height: 10),
                _buildMileageStatus(
                    context,
                    _controller.fetchingMileage,
                    _controller.mileageKm,
                    mileageError == null
                        ? null
                        : scopeError
                            ? 'scope'
                            : 'error'),
              ],
              const SizedBox(height: 14),
              const AppFieldLabel('Note'),
              const SizedBox(height: 6),
              TextFormField(
                  initialValue: _note,
                  onChanged: (value) => _note = value,
                  enabled: !_controller.saving,
                  cursorColor: p.accent,
                  style: AppTextStyles.inter(size: 13, color: p.ink),
                  decoration: const InputDecoration(
                      hintText: 'Optional — e.g. new chain, cleaned only')),
              if (saveError != null) ...[
                const SizedBox(height: 10),
                Text(
                    saveError is AppFailure &&
                            saveError.code != FailureCode.saveFailed
                        ? failureMessage(saveError)
                        : 'Could not save service. Try again.',
                    style: TextStyle(color: p.red)),
              ],
              const SizedBox(height: 22),
              SizedBox(
                  width: double.infinity,
                  child: AppActionButton(
                      label: _controller.saving ? 'Saving…' : 'Log service',
                      onPressed:
                          _controller.saving || _controller.fetchingMileage
                              ? null
                              : _save)),
            ]));
  }
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
