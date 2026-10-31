import 'package:bikesetupapp/features/setups/ui/setting_unit_selector.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:bikesetupapp/common/ui/app_components.dart';
import 'package:bikesetupapp/features/setups/models/unit_system.dart';
import 'package:bikesetupapp/features/setups/ui/field_meta.dart';
import 'package:bikesetupapp/features/setups/ui/setting_value_editor.dart';

/// Edits a local onboarding value. Opening a ruler never seeds a saved value.
class DraftValueEditor extends StatefulWidget {
  const DraftValueEditor(
      {super.key,
      required this.field,
      required this.value,
      required this.onChanged,
      this.previewValue});
  final String field, value;
  final double? previewValue;
  final ValueChanged<String> onChanged;
  @override
  State<DraftValueEditor> createState() => DraftValueEditorState();
}

class DraftValueEditorState extends State<DraftValueEditor> {
  late UnitDef unit;
  late double number;
  late bool hasValue;
  bool typing = false;
  int version = 0;
  String? error;
  final input = TextEditingController();
  FieldMeta get meta => kFieldMeta[widget.field] ?? kDefaultFieldMeta;
  double get minimum => convertValue(meta.min, meta.defaultUnit, unit);
  double get maximum => convertValue(meta.max, meta.defaultUnit, unit);
  @override
  void initState() {
    super.initState();
    final parsed = SettingValue.parse(widget.value,
        fallbackFamily: meta.family, fallbackUnit: meta.defaultUnit);
    unit = parsed.unit ?? meta.defaultUnit;
    hasValue = widget.value.isNotEmpty;
    number = parsed.number ??
        convertValue(widget.previewValue ?? meta.min, meta.defaultUnit, unit);
  }

  @override
  void dispose() {
    input.dispose();
    super.dispose();
  }

  void save(double value) {
    setState(() {
      number = value;
      hasValue = true;
    });
    widget.onChanged(SettingValue.numeric(value, meta.family, unit).format());
  }

  bool submit() {
    final value = double.tryParse(input.text.trim().replaceAll(',', '.'));
    if (value == null ||
        !value.isFinite ||
        value < minimum ||
        value > maximum) {
      setState(() => error =
          'Enter ${formatNumber(minimum, unit.decimals)} to ${formatNumber(maximum, unit.decimals)} ${unit.label}.');
      return false;
    }
    save(value);
    setState(() {
      typing = false;
      version++;
      error = null;
    });
    FocusScope.of(context).unfocus();
    return true;
  }

  bool accept() {
    if (typing) return submit();
    save(number);
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final selector = SettingUnitSelector(
        family: meta.family,
        unit: unit,
        onChanged: (value) {
          if (typing && !submit()) return;
          setState(() {
            number = convertValue(number, unit, value);
            unit = value;
            version++;
          });
          if (hasValue) {
            widget.onChanged(
                SettingValue.numeric(number, meta.family, unit).format());
          }
        });
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (typing) ...[
        AppTextField(
            controller: input,
            hint: 'Enter value',
            suffixWidget: selector,
            errorText: error,
            autofocus: true,
            keyboardType: TextInputType.numberWithOptions(
                decimal: true, signed: minimum < 0),
            onSubmitted: (_) => submit()),
        TextButton(onPressed: submit, child: const Text('Apply')),
      ] else
        SettingValueEditor(
          key: ValueKey('${widget.field}/$version'),
          initialValue: number,
          min: minimum,
          max: maximum,
          step: math.pow(10, -unit.decimals).toDouble(),
          decimals: unit.decimals,
          unitLabel: unit.label,
          valueAccessory: selector,
          onChanged: save,
          onValueTap: () => setState(() {
            input.text = hasValue ? formatNumber(number, unit.decimals) : '';
            typing = true;
          }),
        ),
    ]);
  }
}
