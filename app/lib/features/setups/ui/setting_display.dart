import '../models/unit_system.dart';
import 'field_meta.dart';

/// Uses the field's unit for legacy numbers without changing saved data.
String settingDisplayValue(String field, String raw,
    {UnitFamily? familyOverride}) {
  final meta = kFieldMeta[field];
  final family = familyOverride ?? meta?.family;
  final value = SettingValue.parse(raw,
      fallbackFamily: family,
      fallbackUnit: family == meta?.family ? meta?.defaultUnit : null);
  if (value.isText) return value.text!;
  return [value.displayNumber(), value.displayUnit()]
      .where((part) => part.isNotEmpty)
      .join(' ');
}
