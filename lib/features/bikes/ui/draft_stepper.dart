import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:bikesetupapp/common/theme/theme_data.dart';
import 'package:bikesetupapp/common/ui/app_components.dart';
import '../../setups/models/unit_system.dart';
import '../../setups/ui/field_meta.dart';

class DraftStepper extends StatefulWidget {
  const DraftStepper(
      {super.key,
      required this.field,
      required this.value,
      required this.onChanged,
      this.stepSize});
  final String field, value;
  final double? stepSize;
  final ValueChanged<String> onChanged;
  @override
  State<DraftStepper> createState() => DraftStepperState();
}

class DraftStepperState extends State<DraftStepper> {
  final input = TextEditingController();
  bool editing = false;
  String? error;
  FieldMeta get meta => widget.field == 'Travel'
      ? kTravelFieldMeta
      : kFieldMeta[widget.field] ?? kDefaultFieldMeta;
  SettingValue get parsed => SettingValue.parse(widget.value,
      fallbackFamily: meta.family, fallbackUnit: meta.defaultUnit);
  UnitDef get unit => parsed.unit ?? meta.defaultUnit;
  double get minimum => convertValue(meta.min, meta.defaultUnit, unit);
  double get maximum => convertValue(meta.max, meta.defaultUnit, unit);
  double get increment =>
      widget.stepSize ?? math.pow(10, -unit.decimals).toDouble();
  String get label =>
      widget.field == 'Seat Height' ? 'Saddle height' : widget.field;
  @override
  void dispose() {
    input.dispose();
    super.dispose();
  }

  void save(double number) => widget
      .onChanged(SettingValue.numeric(number, meta.family, unit).format());
  bool accept() {
    if (!editing) return true;
    if (input.text.trim().isEmpty) {
      widget.onChanged('');
    } else {
      final value = double.tryParse(input.text.trim().replaceAll(',', '.'));
      if (value == null ||
          !value.isFinite ||
          value < minimum ||
          value > maximum) {
        setState(() => error =
            'Enter ${formatNumber(minimum, unit.decimals)} to ${formatNumber(maximum, unit.decimals)}.');
        return false;
      }
      save(value);
    }
    setState(() {
      editing = false;
      error = null;
    });
    return true;
  }

  void change(int direction) {
    final typed = editing
        ? double.tryParse(input.text.trim().replaceAll(',', '.'))
        : null;
    if (!accept()) return;
    final number = (typed ?? parsed.number ?? minimum) + direction * increment;
    save(number.clamp(minimum, maximum));
  }

  @override
  Widget build(BuildContext context) {
    final controls = Row(mainAxisSize: MainAxisSize.min, children: [
      AppTactileButton(
          compact: true,
          tooltip: 'Decrease $label',
          onPressed: parsed.number != null && parsed.number! <= minimum
              ? null
              : () => change(-1),
          child: const Icon(CupertinoIcons.minus, size: AppIconSizes.compact)),
      SizedBox(
          width: 88,
          child: TextButton(
              onPressed: () => setState(() {
                    input.text = parsed.number == null
                        ? ''
                        : formatNumber(parsed.number!, unit.decimals);
                    editing = true;
                  }),
              child: Text(formatNumber(parsed.number ?? minimum, unit.decimals),
                  textAlign: TextAlign.center,
                  style: AppTextStyles.heading
                      .copyWith(color: context.palette.ink)))),
      AppTactileButton(
          compact: true,
          tooltip: 'Increase $label',
          onPressed: parsed.number != null && parsed.number! >= maximum
              ? null
              : () => change(1),
          child: const Icon(CupertinoIcons.plus, size: AppIconSizes.compact)),
    ]);
    final name =
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: AppTextStyles.label.copyWith(color: context.palette.ink)),
      if (unit.label.isNotEmpty) ...[
        const SizedBox(height: 4),
        Text(unit.label,
            style:
                AppTextStyles.caption.copyWith(color: context.palette.inkMuted))
      ],
    ]);
    return Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
            color: context.palette.bg, borderRadius: BorderRadius.circular(14)),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          LayoutBuilder(
              builder: (context, constraints) => constraints.maxWidth >= 310 &&
                      MediaQuery.textScalerOf(context).scale(14) < 20
                  ? Row(children: [
                      Expanded(child: name),
                      const SizedBox(width: 8),
                      controls
                    ])
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                          name,
                          const SizedBox(height: 8),
                          Align(
                              alignment: Alignment.centerRight, child: controls)
                        ])),
          if (editing) ...[
            const SizedBox(height: 10),
            AppTextField(
                controller: input,
                hint: 'Enter value',
                suffix: unit.label,
                errorText: error,
                autofocus: true,
                keyboardType: TextInputType.numberWithOptions(
                    decimal: true, signed: minimum < 0),
                onSubmitted: (_) => accept())
          ],
        ]));
  }
}
