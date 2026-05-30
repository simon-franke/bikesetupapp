enum UnitFamily {
  pressure,
  length,
  weight,
  angle,
  torque,
  springRate,
  distance,
  count,
  freeText,
}

class UnitDef {
  final String id;
  final String label;
  final double toCanonical;
  final int decimals;
  const UnitDef({
    required this.id,
    required this.label,
    required this.toCanonical,
    this.decimals = 0,
  });
}

const Map<UnitFamily, List<UnitDef>> kUnitFamilies = {
  UnitFamily.pressure: [
    UnitDef(id: 'psi', label: 'psi', toCanonical: 1.0, decimals: 0),
    UnitDef(id: 'bar', label: 'bar', toCanonical: 14.5038, decimals: 1),
  ],
  UnitFamily.length: [
    UnitDef(id: 'mm', label: 'mm', toCanonical: 1.0, decimals: 0),
    UnitDef(id: 'cm', label: 'cm', toCanonical: 10.0, decimals: 1),
    UnitDef(id: 'in', label: 'in', toCanonical: 25.4, decimals: 2),
  ],
  UnitFamily.weight: [
    UnitDef(id: 'kg', label: 'kg', toCanonical: 1.0, decimals: 1),
    UnitDef(id: 'lbs', label: 'lbs', toCanonical: 0.453592, decimals: 1),
  ],
  UnitFamily.angle: [
    UnitDef(id: 'deg', label: '°', toCanonical: 1.0, decimals: 1),
  ],
  UnitFamily.torque: [
    UnitDef(id: 'Nm', label: 'Nm', toCanonical: 1.0, decimals: 1),
    UnitDef(id: 'lb-ft', label: 'lb-ft', toCanonical: 1.35582, decimals: 1),
  ],
  UnitFamily.springRate: [
    UnitDef(id: 'N/mm', label: 'N/mm', toCanonical: 1.0, decimals: 1),
    UnitDef(id: 'lbs/in', label: 'lbs/in', toCanonical: 0.175127, decimals: 0),
  ],
  UnitFamily.distance: [
    UnitDef(id: 'km', label: 'km', toCanonical: 1.0, decimals: 0),
    UnitDef(id: 'mi', label: 'mi', toCanonical: 1.60934, decimals: 0),
  ],
  UnitFamily.count: [
    UnitDef(id: 'clicks', label: 'clicks', toCanonical: 1.0, decimals: 0),
    UnitDef(id: 'turns', label: 'turns', toCanonical: 1.0, decimals: 0),
    UnitDef(id: 'count', label: '', toCanonical: 1.0, decimals: 0),
  ],
  UnitFamily.freeText: [],
};

UnitFamily? unitFamilyFromName(String name) {
  for (final f in UnitFamily.values) {
    if (f.name == name) return f;
  }
  return null;
}

UnitDef unitDefById(UnitFamily family, String id) {
  final list = kUnitFamilies[family] ?? const [];
  for (final u in list) {
    if (u.id == id) return u;
  }
  return list.isNotEmpty ? list.first : const UnitDef(id: '', label: '', toCanonical: 1.0);
}

/// Returns (family, unit) for a unit id, or null if unknown.
({UnitFamily family, UnitDef unit})? lookupUnitId(String id) {
  for (final entry in kUnitFamilies.entries) {
    for (final u in entry.value) {
      if (u.id == id) return (family: entry.key, unit: u);
    }
  }
  return null;
}

double convertValue(double value, UnitDef from, UnitDef to) {
  if (identical(from, to) || from.id == to.id) return value;
  final canonical = value * from.toCanonical;
  return canonical / to.toCanonical;
}

String formatNumber(double value, int decimals) {
  if (decimals <= 0) return value.round().toString();
  return value.toStringAsFixed(decimals);
}

/// Parsed representation of a setting value stored in Firestore.
///
/// Storage format: `"<number> <unitId>"` (e.g. `"180 psi"`), `"<number>"` for
/// unitless numerics, or arbitrary text for free-text fields. Legacy values
/// without a unit suffix fall back to a caller-provided default unit.
class SettingValue {
  final double? number;
  final UnitDef? unit;
  final UnitFamily? family;
  final String? text;

  const SettingValue._({this.number, this.unit, this.family, this.text});

  bool get isText => text != null;
  bool get isEmpty => number == null && (text == null || text!.isEmpty);

  factory SettingValue.numeric(double value, UnitFamily family, UnitDef unit) =>
      SettingValue._(number: value, unit: unit, family: family);

  factory SettingValue.unitlessNumber(double value) =>
      SettingValue._(number: value);

  factory SettingValue.freeText(String text) =>
      SettingValue._(text: text, family: UnitFamily.freeText);

  /// Parses a stored string. [fallbackFamily] and [fallbackUnit] are used when
  /// the stored value is just a number (legacy data or unitless field).
  factory SettingValue.parse(
    String raw, {
    UnitFamily? fallbackFamily,
    UnitDef? fallbackUnit,
  }) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      if (fallbackFamily == UnitFamily.freeText) {
        return SettingValue.freeText('');
      }
      return const SettingValue._();
    }

    // Try "<number> <unit>"
    final twoPart = RegExp(r'^(-?\d+(?:\.\d+)?)\s+(\S.*)$').firstMatch(trimmed);
    if (twoPart != null) {
      final n = double.tryParse(twoPart.group(1)!);
      final unitId = twoPart.group(2)!.trim();
      final lookup = lookupUnitId(unitId);
      if (n != null && lookup != null) {
        return SettingValue.numeric(n, lookup.family, lookup.unit);
      }
      // Unknown unit suffix → treat whole thing as free text.
      return SettingValue.freeText(trimmed);
    }

    // Try just "<number>"
    final n = double.tryParse(trimmed);
    if (n != null) {
      if (fallbackUnit != null && fallbackFamily != null) {
        return SettingValue.numeric(n, fallbackFamily, fallbackUnit);
      }
      return SettingValue.unitlessNumber(n);
    }

    return SettingValue.freeText(trimmed);
  }

  /// Serializes back to the storage format.
  String format() {
    if (isText) return text!;
    if (number == null) return '';
    final decimals = unit?.decimals ?? 0;
    final numStr = formatNumber(number!, decimals);
    if (unit == null || unit!.id.isEmpty) return numStr;
    return '$numStr ${unit!.id}';
  }

  /// Returns the number formatted to its unit's decimals (no unit suffix).
  String displayNumber() {
    if (isText) return text ?? '';
    if (number == null) return '';
    return formatNumber(number!, unit?.decimals ?? 0);
  }

  /// Human-facing unit label (e.g. "°" not "deg"). Empty for unitless/freeText.
  String displayUnit() => unit?.label ?? '';

  SettingValue convertTo(UnitFamily targetFamily, UnitDef targetUnit) {
    if (number == null || unit == null) return this;
    final converted = convertValue(number!, unit!, targetUnit);
    return SettingValue.numeric(converted, targetFamily, targetUnit);
  }
}
