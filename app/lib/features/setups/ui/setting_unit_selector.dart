import 'package:flutter/material.dart';
import 'package:bikesetupapp/common/ui/app_unit_selector.dart';
import '../models/unit_system.dart';

class SettingUnitSelector extends StatelessWidget {
  const SettingUnitSelector(
      {super.key,
      required this.family,
      required this.unit,
      required this.onChanged});
  final UnitFamily family;
  final UnitDef unit;
  final ValueChanged<UnitDef> onChanged;

  @override
  Widget build(BuildContext context) => AppUnitSelector(
        value: unit.id,
        options: [
          for (final item in kUnitFamilies[family] ?? [unit])
            AppUnitOption(item.id, item.label, _names[item.id] ?? item.label)
        ],
        onChanged: (id) => onChanged(unitDefById(family, id)),
      );
}

const _names = {
  'psi': 'psi',
  'bar': 'Bar',
  'mm': 'Millimetres',
  'cm': 'Centimetres',
  'in': 'Inches',
  'kg': 'Kilograms',
  'lbs': 'Pounds',
  'deg': 'Degrees',
  'Nm': 'Newton metres',
  'lb-ft': 'Pound feet',
  'N/mm': 'Newtons per millimetre',
  'lbs/in': 'Pounds per inch',
  'km': 'Kilometres',
  'mi': 'Miles',
  '%': 'Percent',
  'clicks': 'Clicks',
  'turns': 'Turns',
  'count': 'Count',
};
