import 'package:bikesetupapp/common/ui/app_loading.dart';
import 'package:bikesetupapp/common/ui/app_date_sheet.dart';
import 'package:bikesetupapp/common/ui/app_value_button.dart';
import 'package:flutter/cupertino.dart';
import 'hour_service_sheet.dart';
import 'package:bikesetupapp/app/app_dependencies.dart';
import 'package:bikesetupapp/common/ui/app_sheet.dart';
import 'package:bikesetupapp/common/ui/app_components.dart';
import 'package:bikesetupapp/common/theme/theme_data.dart';
import 'package:bikesetupapp/common/models/command_result.dart';
import 'package:bikesetupapp/common/ui/failure_message.dart';
import '../controllers/service_editor_controller.dart';
import '../models/service_component.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

final NumberFormat _kmFormat = NumberFormat('#,###');

Future<void> showLogServiceSheet(
        {required BuildContext context,
        required String userID,
        required ServiceComponent component,
        required double currentMileageKm,
        String? stravaGearId}) =>
    showAppSheet<void>(
        context: context,
        builder: (_) => component.usesHours
            ? HourServiceSheet(uid: userID, component: component)
            : _LogServiceForm(
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
  final _note = TextEditingController();

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
    _note.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    if (_controller.saving) return;
    final picked = await pickAppDate(context, initial: _selectedDate);
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
          await _controller.logService(date: _selectedDate, note: _note.text);
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
    final mileageError = _controller.mileageError;
    final scopeError = mileageError is AppFailure &&
        mileageError.code == FailureCode.insufficientActivityScope;
    final saveError = _controller.saveError;

    return Padding(
        padding: appSheetPadding(context),
        child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppSheetHeader(
                  title: 'Log service', subtitle: widget.component.name),
              AppFormField(
                  label: 'Date',
                  child: AppValueButton(
                      label: DateFormat.yMMMd().format(_selectedDate),
                      icon: CupertinoIcons.calendar,
                      onTap: _controller.saving ? null : _pickDate)),
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
              const SizedBox(height: 20),
              AppFormField(
                  label: 'Note (optional)',
                  child: IgnorePointer(
                      ignoring: _controller.saving,
                      child: AppTextField(
                          controller: _note,
                          hint: 'What was done?',
                          maxLines: 3))),
              const SizedBox(height: 24),
              AppFormFooter(
                  label: 'Log service',
                  isLoading: _controller.saving,
                  error: saveError == null
                      ? null
                      : saveError is AppFailure &&
                              saveError.code != FailureCode.saveFailed
                          ? failureMessage(saveError)
                          : 'Could not save service. Try again.',
                  onPressed: _controller.fetchingMileage ? null : _save),
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
    return const AppLoadingContent(label: 'Fetching from Strava…');
  }

  if (mileageError == 'scope') {
    return Row(
      children: [
        Icon(CupertinoIcons.exclamationmark_triangle,
            size: AppIconSizes.compact, color: p.red),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            'Re-connect Strava in settings to fetch mileage',
            style: AppTextStyles.label.copyWith(color: p.red),
          ),
        ),
      ],
    );
  }

  if (mileageError == 'error') {
    return Row(
      children: [
        Icon(CupertinoIcons.xmark, size: AppIconSizes.compact, color: p.red),
        const SizedBox(width: 6),
        Expanded(
            child: Text(
          'Could not fetch mileage from Strava',
          style: AppTextStyles.label.copyWith(color: p.red),
        )),
      ],
    );
  }

  if (fetchedMileage != null) {
    return Row(
      children: [
        Icon(CupertinoIcons.map, size: AppIconSizes.compact, color: p.amber),
        const SizedBox(width: 6),
        Text(
          '${_kmFormat.format(fetchedMileage.round())} km at service',
          style: AppTextStyles.label.copyWith(color: p.amber),
        ),
      ],
    );
  }

  return const SizedBox.shrink();
}
