import 'package:flutter/material.dart';

class FieldMeta {
  final IconData icon;
  final String unit;
  final int min;
  final int max;
  const FieldMeta(this.icon, this.unit, {this.min = 0, this.max = 100});
}

const FieldMeta kDefaultFieldMeta = FieldMeta(Icons.tune_rounded, '');

const Map<String, FieldMeta> kFieldMeta = {
  'Pressure':              FieldMeta(Icons.speed_rounded,                    'psi',    min: 15,  max: 200),
  'Rebound':               FieldMeta(Icons.unfold_more_rounded,              'clicks', min: 0,   max: 30),
  'High Speed Rebound':    FieldMeta(Icons.unfold_more_rounded,              'clicks', min: 0,   max: 30),
  'Low Speed Rebound':     FieldMeta(Icons.unfold_more_rounded,              'clicks', min: 0,   max: 30),
  'Compression':           FieldMeta(Icons.unfold_less_rounded,              'clicks', min: 0,   max: 30),
  'High Speed Compression':FieldMeta(Icons.unfold_less_rounded,              'clicks', min: 0,   max: 30),
  'Low Speed Compression': FieldMeta(Icons.unfold_less_rounded,              'clicks', min: 0,   max: 30),
  'Tokens':                FieldMeta(Icons.radio_button_unchecked_rounded,   'count',  min: 0,   max: 10),
  'Spring Rate':           FieldMeta(Icons.compress_rounded,                 'N/mm',   min: 200, max: 700),
  'Preload':               FieldMeta(Icons.density_medium_rounded,           'mm',     min: 0,   max: 30),
  'Reach':                 FieldMeta(Icons.straighten_rounded,               'mm',     min: 380, max: 550),
  'Stack Height':          FieldMeta(Icons.height_rounded,                   'mm',     min: 580, max: 680),
  'Seat Height':           FieldMeta(Icons.airline_seat_recline_normal,      'mm',     min: 600, max: 850),
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
