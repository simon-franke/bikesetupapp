import 'package:bikesetupapp/common/ui/delete_confirmation_sheet.dart';
import 'setting_unit_selector.dart';

import 'package:flutter/cupertino.dart';
import 'package:bikesetupapp/common/ui/command_feedback.dart';
import 'package:bikesetupapp/common/models/command_result.dart';
import 'package:bikesetupapp/app/app_dependencies.dart';
import 'package:bikesetupapp/common/ui/app_sheet.dart';
import 'package:bikesetupapp/common/ui/app_components.dart';
import 'dart:math' as math;

import 'package:bikesetupapp/common/theme/theme_data.dart';
import 'package:bikesetupapp/features/setups/ui/field_meta.dart';
import 'package:bikesetupapp/features/setups/ui/setting_value_editor.dart';
import 'package:bikesetupapp/features/setups/models/unit_system.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<void> showSettingStepperSheet(
  BuildContext context, {
  User? user,
  Future<CommandResult<void>> Function(String)? onSave,
  required String uBikeID,
  required String category,
  required String uSetupID,
  required String settingKey,
  required String currentValue,
  required bool canDelete,
  UnitFamily? familyOverride,
  String? saveLabel,
  bool optimistic = false,
  VoidCallback? onClear,
}) {
  final knownMeta = kFieldMeta[settingKey];
  final rawForParse = currentValue == '--' ? '' : currentValue;
  final parsed = SettingValue.parse(
    rawForParse,
    fallbackFamily: knownMeta?.family,
    fallbackUnit: knownMeta?.defaultUnit,
  );

  final UnitFamily? predetermined = familyOverride ?? knownMeta?.family;

  late UnitFamily family;
  late UnitDef unit;
  late bool isFreeText;

  if (predetermined != null) {
    family = predetermined;
    if (family == UnitFamily.freeText) {
      isFreeText = true;
      unit = const UnitDef(id: '', label: '', toCanonical: 1.0);
    } else {
      isFreeText = false;
      final familyUnits = kUnitFamilies[family] ?? const <UnitDef>[];
      final parsedUnit = parsed.unit;
      if (parsedUnit != null && familyUnits.any((u) => u.id == parsedUnit.id)) {
        unit = parsedUnit;
      } else if (knownMeta != null && knownMeta.family == family) {
        unit = knownMeta.defaultUnit;
      } else if (familyUnits.isNotEmpty) {
        unit = familyUnits.first;
      } else {
        unit = const UnitDef(id: '', label: '', toCanonical: 1.0);
      }
    }
  } else if (parsed.isText) {
    family = UnitFamily.freeText;
    unit = const UnitDef(id: '', label: '', toCanonical: 1.0);
    isFreeText = true;
  } else if (parsed.unit != null && parsed.family != null) {
    family = parsed.family!;
    unit = parsed.unit!;
    isFreeText = false;
  } else {
    family = UnitFamily.count;
    unit = unitDefById(UnitFamily.count, 'count');
    isFreeText = false;
  }

  final setups = onSave == null
      ? AppDependencies.of(context).forUser(user!.uid).setups
      : null;
  final save = onSave ??
      (String value) =>
          setups!.setSetting(settingKey, value, uBikeID, category, uSetupID);
  final feedbackContext = Navigator.of(context, rootNavigator: true).context;
  final messenger = ScaffoldMessenger.of(context);
  Future<void> saveOptimistically(String value) async {
    await presentCommand(feedbackContext, () => save(value),
        onFailure: (message) {
      if (!messenger.mounted) return;

      messenger.showSnackBar(SnackBar(
        content: Text('$settingKey: $value wasn’t saved. $message'),
        duration: const Duration(seconds: 12),
        action: context.mounted
            ? SnackBarAction(
                label: 'Review',
                onPressed: () {
                  if (!context.mounted) return;

                  showSettingStepperSheet(context,
                      user: user,
                      onSave: onSave,
                      uBikeID: uBikeID,
                      category: category,
                      uSetupID: uSetupID,
                      settingKey: settingKey,
                      currentValue: value,
                      canDelete: canDelete,
                      familyOverride: familyOverride,
                      saveLabel: saveLabel,
                      onClear: onClear,
                      optimistic: optimistic);
                })
            : null,
      ));
    });
  }

  return showAppSheet<void>(
    context: context,
    builder: (ctx) => _StepperSheetContent(
      user: user,
      onSave: save,
      optimisticSave: optimistic || onSave == null ? saveOptimistically : null,
      saveLabel: saveLabel ?? (onSave == null ? 'Save' : 'Save to experiment'),
      onClear: onClear,
      uBikeID: uBikeID,
      category: category,
      uSetupID: uSetupID,
      settingKey: settingKey,
      iconAsset: knownMeta?.iconAsset ?? kDefaultFieldMeta.iconAsset,
      family: family,
      initialUnit: unit,
      initialNumeric: parsed.number ?? 0,
      initialText: isFreeText ? rawForParse : parsed.text ?? '',
      knownMeta: knownMeta,
      isFreeText: isFreeText,
      canDelete: canDelete,
    ),
  );
}

class _StepperSheetContent extends StatefulWidget {
  final Future<void> Function(String)? optimisticSave;
  final String? saveLabel;
  final VoidCallback? onClear;
  final User? user;
  final Future<CommandResult<void>> Function(String)? onSave;
  final String uBikeID;
  final String category;
  final String uSetupID;
  final String settingKey;
  final String iconAsset;
  final UnitFamily family;
  final UnitDef initialUnit;
  final double initialNumeric;
  final String initialText;
  final FieldMeta? knownMeta;
  final bool isFreeText;
  final bool canDelete;

  const _StepperSheetContent({
    required this.user,
    this.onSave,
    this.optimisticSave,
    this.saveLabel,
    this.onClear,
    required this.uBikeID,
    required this.category,
    required this.uSetupID,
    required this.settingKey,
    required this.iconAsset,
    required this.family,
    required this.initialUnit,
    required this.initialNumeric,
    required this.initialText,
    required this.knownMeta,
    required this.isFreeText,
    required this.canDelete,
  });

  @override
  State<_StepperSheetContent> createState() => _StepperSheetContentState();
}

class _StepperSheetContentState extends State<_StepperSheetContent> {
  late UnitDef _unit;
  late double _value;
  late TextEditingController _textController;
  final _numberController = TextEditingController();
  bool _editingNumber = false;
  String? _numberError;

  @override
  void initState() {
    super.initState();
    _unit = widget.initialUnit;
    _value = widget.initialNumeric;
    _textController = TextEditingController(text: widget.initialText);
  }

  @override
  void dispose() {
    _numberController.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _onChipTap(UnitDef target) {
    if (target.id == _unit.id) return;
    if (_editingNumber && !_readNumber()) return;
    _editingNumber = false;
    setState(() {
      _value = convertValue(_value, _unit, target);
      _unit = target;
    });
  }

  bool _readNumber() {
    final number = double.tryParse(_numberController.text.replaceAll(',', '.'));
    if (number == null || !number.isFinite || number < 0 || number > 10000) {
      setState(() => _numberError = 'Enter a number between 0 and 10000.');
      return false;
    }
    _value = number;
    return true;
  }

  bool _saving = false;

  Future<void> _onSave() async {
    if (_saving) return;

    if (_editingNumber && !_readNumber()) return;

    setState(() => _saving = true);
    final stored = widget.isFreeText
        ? _textController.text.trim()
        : SettingValue.numeric(_value, widget.family, _unit).format();
    if (widget.optimisticSave != null) {
      final save = widget.optimisticSave!;
      Navigator.of(context).pop();
      await save(stored);
      return;
    }

    final saved = await presentCommand(
        context,
        () => widget.onSave != null
            ? widget.onSave!(stored)
            : AppDependencies.of(context)
                .forUser(widget.user!.uid)
                .setups
                .setSetting(widget.settingKey, stored, widget.uBikeID,
                    widget.category, widget.uSetupID));
    if (!mounted) return;

    if (saved) {
      Navigator.of(context).pop();
    } else {
      setState(() => _saving = false);
    }
  }

  Future<void> _onDelete() async {
    final confirmed = await showDeleteConfirmationSheet(
      context,
      title: 'Delete ${widget.settingKey}?',
      message: 'This permanently removes this setting.',
    );
    if (confirmed == true && mounted && !_saving) {
      setState(() => _saving = true);
      final db = AppDependencies.of(context).forUser(widget.user!.uid);
      final deleted = await presentCommand(
          context,
          () => db.setups.deleteField(widget.settingKey, widget.uBikeID,
              widget.category, widget.uSetupID));
      if (!mounted) return;

      if (deleted) {
        Navigator.of(context).pop();
      } else {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _showOptions() async {
    final action = await showAppOptionsSheet(
      context: context,
      title: 'Setting options',
      entries: const [
        AppSheetOption(
            value: 'delete',
            label: 'Delete field',
            icon: CupertinoIcons.trash,
            destructive: true),
      ],
    );
    if (action == 'delete' && mounted && !_saving) await _onDelete();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Padding(
      padding: appSheetPadding(context),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppSheetHeader(
              title:
                  '${categoryLabel(widget.category)} ${widget.settingKey.toLowerCase()}',
              action: widget.canDelete
                  ? IconButton(
                      tooltip: 'Setting options',
                      onPressed: _saving ? null : _showOptions,
                      icon: const Icon(CupertinoIcons.ellipsis))
                  : null),
          if (widget.isFreeText)
            _FreeTextField(controller: _textController)
          else
            _buildEditor(),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: AppTactileButton(
              onPressed: _saving ? null : _onSave,
              child: Text(widget.saveLabel ??
                  (widget.onSave == null ? 'Save' : 'Save to experiment')),
            ),
          ),
          if (widget.onClear != null) ...[
            const SizedBox(height: 6),
            TextButton(
              onPressed: _saving
                  ? null
                  : () {
                      widget.onClear!();
                      Navigator.of(context).pop();
                    },
              child: Text('Clear value',
                  style: AppTextStyles.label.copyWith(color: p.red)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEditor() {
    if (_editingNumber) {
      return TextField(
          controller: _numberController,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textAlign: TextAlign.center,
          style: AppTextStyles.value.copyWith(color: context.palette.ink),
          decoration: InputDecoration(
              labelText: widget.settingKey,
              suffixIcon: SettingUnitSelector(
                  family: widget.family, unit: _unit, onChanged: _onChipTap),
              errorText: _numberError),
          onSubmitted: (_) {
            if (_readNumber()) setState(() => _editingNumber = false);
          });
    }

    final knownMeta = widget.knownMeta;
    double minInActive;
    double maxInActive;
    if (knownMeta != null) {
      final defaultUnit = knownMeta.defaultUnit;
      minInActive = convertValue(knownMeta.min, defaultUnit, _unit);
      maxInActive = convertValue(knownMeta.max, defaultUnit, _unit);
    } else {
      minInActive = 0;
      maxInActive = 100;
    }

    final step =
        _unit.decimals <= 0 ? 1.0 : math.pow(10, -_unit.decimals).toDouble();

    return SettingValueEditor(
      key: ValueKey('${widget.settingKey}-${_unit.id}'),
      initialValue: _value,
      centerValueAccessory: true,
      onValueTap: () => setState(() {
        _numberController.text = formatNumber(_value, _unit.decimals);
        _numberController.selection = TextSelection(
            baseOffset: 0, extentOffset: _numberController.text.length);
        _editingNumber = true;
        _numberError = null;
      }),
      min: minInActive,
      max: maxInActive,
      step: step,
      decimals: _unit.decimals,
      unitLabel: _unit.label,
      valueAccessory: SettingUnitSelector(
          family: widget.family, unit: _unit, onChanged: _onChipTap),
      onChanged: (v) => _value = v,
    );
  }
}

class _FreeTextField extends StatelessWidget {
  final TextEditingController controller;

  const _FreeTextField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AppTextField(
        controller: controller, hint: 'Enter value', autofocus: true);
  }
}
