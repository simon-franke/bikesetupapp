import '../controllers/setting_save_controller.dart';
import 'dart:math' as math;

import 'package:bikesetupapp/common/theme/theme_data.dart';
import 'package:bikesetupapp/common/ui/app_components.dart';
import 'package:bikesetupapp/features/setups/ui/field_meta.dart';
import 'package:bikesetupapp/features/setups/ui/setting_value_editor.dart';
import 'package:bikesetupapp/features/setups/models/unit_system.dart';
import 'package:flutter/material.dart';

/// The tablet's persistent ruler editor with automatic, ordered saves.
class InlineSettingEditor extends StatefulWidget {
  final String name;
  final String value;
  final UnitFamily? familyOverride;
  final Future<void> Function(String value) onSave;
  final VoidCallback? onManage;
  final SettingWriteQueue? writes;

  const InlineSettingEditor(
      {super.key,
      required this.name,
      required this.value,
      required this.onSave,
      this.familyOverride,
      this.onManage,
      this.writes});

  @override
  State<InlineSettingEditor> createState() => _InlineSettingEditorState();
}

class _InlineSettingEditorState extends State<InlineSettingEditor> {
  late UnitFamily _family;
  late UnitDef _unit;
  late double _number;
  late TextEditingController _text;
  late TextEditingController _numericText;
  late final SettingSaveController _save;
  bool _editingNumber = false;
  int _rulerVersion = 0;
  String? _inputError;

  bool get _isText => _family == UnitFamily.freeText;
  FieldMeta? get _meta => kFieldMeta[widget.name];

  @override
  void initState() {
    super.initState();
    _save = SettingSaveController(writes: widget.writes)
      ..addListener(_saveChanged);
    _load(widget.value);
    _text = TextEditingController(text: _isText ? widget.value : '');
    _numericText =
        TextEditingController(text: formatNumber(_number, _unit.decimals));
  }

  void _saveChanged() {
    if (mounted) setState(() {});
  }

  void _load(String value) {
    final parsed = SettingValue.parse(value == '--' ? '' : value,
        fallbackFamily: _meta?.family, fallbackUnit: _meta?.defaultUnit);
    _family = widget.familyOverride ??
        _meta?.family ??
        parsed.family ??
        (parsed.isText ? UnitFamily.freeText : UnitFamily.count);
    final units = kUnitFamilies[_family] ?? [];
    _unit = parsed.unit != null && units.any((u) => u.id == parsed.unit!.id)
        ? parsed.unit!
        : units.isNotEmpty
            ? units.first
            : const UnitDef(id: '', label: '', toCanonical: 1);
    _number = parsed.number ?? 0;
    _rulerVersion++;
  }

  @override
  void didUpdateWidget(InlineSettingEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A stream echo must not replace a newer draft while it is saving.
    if (oldWidget.value != widget.value &&
        !_save.saving &&
        !_save.failed &&
        !_editingNumber &&
        !_save.dirty) {
      _load(widget.value);
      _text.text = _isText ? widget.value : '';
      _numericText.text = formatNumber(_number, _unit.decimals);
    }
  }

  @override
  void dispose() {
    _save.dispose();
    _text.dispose();
    _numericText.dispose();
    super.dispose();
  }

  String get _stored => _isText
      ? _text.text.trim()
      : SettingValue.numeric(_number, _family, _unit).format();

  void _persist() {
    _save.save(_stored, widget.onSave);
  }

  double get _step => math.pow(10, -_unit.decimals).toDouble();

  double get _minimum => _meta != null && _meta!.family == _family
      ? math.min(
          _number,
          (convertValue(_meta!.min, _meta!.defaultUnit, _unit) / _step)
                  .floor() *
              _step)
      : math.min(0, _number);
  double get _maximum => _meta != null && _meta!.family == _family
      ? math.max(
          _number,
          (convertValue(_meta!.max, _meta!.defaultUnit, _unit) / _step).ceil() *
              _step)
      : math.max(100, _number);

  void _submitNumber() {
    final value =
        double.tryParse(_numericText.text.trim().replaceAll(',', '.'));
    if (value == null ||
        !value.isFinite ||
        value < _minimum ||
        value > _maximum) {
      setState(() => _inputError =
          'Enter a value between ${formatNumber(_minimum, _unit.decimals)} and ${formatNumber(_maximum, _unit.decimals)}.');
      return;
    }
    setState(() {
      _number = value;
      _editingNumber = false;
      _inputError = null;
      _rulerVersion++;
    });
    _persist();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final units = kUnitFamilies[_family] ?? [];
    final unitSelector = Wrap(spacing: 8, runSpacing: 8, children: [
      for (final unit in units)
        ChoiceChip(
            label: Text(unit.label.isEmpty ? unit.id : unit.label),
            selected: unit.id == _unit.id,
            showCheckmark: false,
            onSelected: _editingNumber
                ? null
                : (_) {
                    if (unit.id == _unit.id) return;
                    setState(() {
                      _number = convertValue(_number, _unit, unit);
                      _unit = unit;
                      _rulerVersion++;
                      _save.dirty = true;
                    });
                    _persist();
                  }),
    ]);
    return Material(
      color: p.surface,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: p.border)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Row(children: [
            Expanded(
                child: Text(widget.name,
                    style: Theme.of(context).textTheme.titleMedium)),
            const SizedBox(width: 8),
            SizedBox(
                width: 16,
                height: 16,
                child: _save.saving
                    ? const CircularProgressIndicator(
                        strokeWidth: 2, semanticsLabel: 'Saving setting')
                    : null),
            if (widget.onManage != null)
              IconButton(
                  tooltip: 'More options for ${widget.name}',
                  onPressed: widget.onManage,
                  icon: const Icon(Icons.more_horiz)),
          ]),
          const SizedBox(height: 8),
          if (_isText) ...[
            AppTextField(
                controller: _text,
                hint: 'Enter value',
                onChanged: (_) => setState(() {
                      _save.dirty = true;
                    }),
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _persist()),
            const SizedBox(height: 12),
            Align(
                alignment: Alignment.centerRight,
                child: AppActionButton(label: 'Done', onPressed: _persist)),
          ] else if (_editingNumber) ...[
            AppTextField(
                controller: _numericText,
                hint: 'Value',
                suffix: _unit.label,
                errorText: _inputError,
                keyboardType: const TextInputType.numberWithOptions(
                    decimal: true, signed: true),
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submitNumber()),
            const SizedBox(height: 12),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              TextButton(
                  onPressed: () => setState(() {
                        _editingNumber = false;
                        _inputError = null;
                      }),
                  child: const Text('Cancel')),
              AppActionButton(label: 'Done', onPressed: _submitNumber),
            ]),
          ] else ...[
            NotificationListener<ScrollEndNotification>(
              onNotification: (_) {
                if (_save.dirty) _persist();
                return false;
              },
              child: SettingValueEditor(
                  key: ValueKey(_rulerVersion),
                  compact: true,
                  valueAccessory: units.length > 1 ? unitSelector : null,
                  initialValue: _number,
                  min: _minimum,
                  max: _maximum,
                  step: _step,
                  decimals: _unit.decimals,
                  unitLabel: _unit.label,
                  onValueTap: () => setState(() {
                        _numericText.text =
                            formatNumber(_number, _unit.decimals);
                        _editingNumber = true;
                      }),
                  onChanged: (value) => setState(() {
                        _number = value;
                        _save.dirty = true;
                      })),
            ),
          ],
          if (_save.failed) ...[
            const SizedBox(height: 8),
            Row(children: [
              Expanded(
                  child: Text('Could not save. Your change is still here.',
                      style: TextStyle(color: p.red))),
              TextButton(onPressed: _persist, child: const Text('Retry')),
            ]),
          ],
        ]),
      ),
    );
  }
}
