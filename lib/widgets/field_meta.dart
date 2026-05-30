import 'package:bikesetupapp/widgets/unit_system.dart';

class FieldMeta {
  final String iconAsset;
  final UnitFamily family;
  final String defaultUnitId;
  final double min;
  final double max;

  const FieldMeta({
    required this.iconAsset,
    required this.family,
    required this.defaultUnitId,
    this.min = 0,
    this.max = 100,
  });

  UnitDef get defaultUnit => unitDefById(family, defaultUnitId);
  String get defaultUnitLabel => defaultUnit.label;
}

const String _kIconBase = 'assets/icons';
const String _kIconGeneric = '$_kIconBase/generic.svg';

const FieldMeta kDefaultFieldMeta = FieldMeta(
  iconAsset: _kIconGeneric,
  family: UnitFamily.count,
  defaultUnitId: 'count',
);

const Map<String, FieldMeta> kFieldMeta = {
  'Pressure': FieldMeta(
    iconAsset: '$_kIconBase/pressure.svg',
    family: UnitFamily.pressure,
    defaultUnitId: 'psi',
    min: 15,
    max: 200,
  ),
  'Rebound': FieldMeta(
    iconAsset: '$_kIconBase/rebound.svg',
    family: UnitFamily.count,
    defaultUnitId: 'clicks',
    min: 0,
    max: 30,
  ),
  'High Speed Rebound': FieldMeta(
    iconAsset: '$_kIconBase/rebound.svg',
    family: UnitFamily.count,
    defaultUnitId: 'clicks',
    min: 0,
    max: 30,
  ),
  'Low Speed Rebound': FieldMeta(
    iconAsset: '$_kIconBase/rebound.svg',
    family: UnitFamily.count,
    defaultUnitId: 'clicks',
    min: 0,
    max: 30,
  ),
  'Compression': FieldMeta(
    iconAsset: '$_kIconBase/compression.svg',
    family: UnitFamily.count,
    defaultUnitId: 'clicks',
    min: 0,
    max: 30,
  ),
  'High Speed Compression': FieldMeta(
    iconAsset: '$_kIconBase/compression.svg',
    family: UnitFamily.count,
    defaultUnitId: 'clicks',
    min: 0,
    max: 30,
  ),
  'Low Speed Compression': FieldMeta(
    iconAsset: '$_kIconBase/compression.svg',
    family: UnitFamily.count,
    defaultUnitId: 'clicks',
    min: 0,
    max: 30,
  ),
  'Tokens': FieldMeta(
    iconAsset: '$_kIconBase/tokens.svg',
    family: UnitFamily.count,
    defaultUnitId: 'count',
    min: 0,
    max: 10,
  ),
  'Spring Rate': FieldMeta(
    iconAsset: '$_kIconBase/spring.svg',
    family: UnitFamily.springRate,
    defaultUnitId: 'N/mm',
    min: 30,
    max: 150,
  ),
  'Preload': FieldMeta(
    iconAsset: '$_kIconBase/preload.svg',
    family: UnitFamily.count,
    defaultUnitId: 'turns',
    min: 0,
    max: 30,
  ),
  'Reach': FieldMeta(
    iconAsset: '$_kIconBase/reach.svg',
    family: UnitFamily.length,
    defaultUnitId: 'mm',
    min: 380,
    max: 550,
  ),
  'Stack Height': FieldMeta(
    iconAsset: '$_kIconBase/stack.svg',
    family: UnitFamily.length,
    defaultUnitId: 'mm',
    min: 580,
    max: 680,
  ),
  'Seat Height': FieldMeta(
    iconAsset: '$_kIconBase/seat.svg',
    family: UnitFamily.length,
    defaultUnitId: 'mm',
    min: 600,
    max: 850,
  ),
};

// Single source of truth for per-category field configuration.
// defaultKeys doubles as requiredKeys — required fields cannot be deleted.
class _CategoryConfig {
  final List<String> defaultKeys;
  final List<String> suggestedKeys;
  const _CategoryConfig({required this.defaultKeys, this.suggestedKeys = const []});
}

const Map<String, _CategoryConfig> _kCategoryConfigs = {
  'Fork': _CategoryConfig(
    defaultKeys:   ['Pressure', 'Rebound', 'Compression', 'Tokens'],
    suggestedKeys: ['High Speed Rebound', 'Low Speed Rebound', 'High Speed Compression', 'Low Speed Compression', 'Spring Rate'],
  ),
  'Shock': _CategoryConfig(
    defaultKeys:   ['Pressure', 'Preload', 'Spring Rate', 'Rebound', 'Compression', 'Tokens'],
    suggestedKeys: ['High Speed Rebound', 'Low Speed Rebound', 'High Speed Compression', 'Low Speed Compression'],
  ),
  'FrontTire':       _CategoryConfig(defaultKeys: ['Pressure']),
  'RearTire':        _CategoryConfig(defaultKeys: ['Pressure']),
  'GeneralSettings': _CategoryConfig(defaultKeys: ['Reach', 'Stack Height', 'Seat Height']),
};

// Public derived views — callers use these unchanged.
final Map<String, List<String>> kDefaultFieldKeys = {
  for (final e in _kCategoryConfigs.entries) e.key: e.value.defaultKeys,
};

final Map<String, List<String>> kSuggestedFieldKeys = {
  for (final e in _kCategoryConfigs.entries) e.key: e.value.suggestedKeys,
};

bool isDefaultField(String category, String key) =>
    _kCategoryConfigs[category]?.defaultKeys.contains(key) ?? false;

/// A required field cannot be deleted. Currently identical to [isDefaultField].
bool isRequiredField(String category, String key) => isDefaultField(category, key);
