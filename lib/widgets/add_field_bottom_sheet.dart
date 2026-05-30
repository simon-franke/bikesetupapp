import 'dart:math' as math;

import 'package:bikesetupapp/app_services/theme_data.dart';
import 'package:bikesetupapp/database_service/database.dart';
import 'package:bikesetupapp/widgets/field_icon.dart';
import 'package:bikesetupapp/widgets/field_meta.dart';
import 'package:bikesetupapp/widgets/setting_value_editor.dart';
import 'package:bikesetupapp/widgets/unit_system.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

Future<void> showAddFieldSheet(
  BuildContext context, {
  required User user,
  required String uBikeID,
  required String category,
  required String uSetupID,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.palette.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (ctx) => _AddFieldSheet(
      user: user,
      uBikeID: uBikeID,
      category: category,
      uSetupID: uSetupID,
    ),
  );
}

class _AddFieldSheet extends StatefulWidget {
  final User user;
  final String uBikeID;
  final String category;
  final String uSetupID;

  const _AddFieldSheet({
    required this.user,
    required this.uBikeID,
    required this.category,
    required this.uSetupID,
  });

  @override
  State<_AddFieldSheet> createState() => _AddFieldSheetState();
}

const Map<UnitFamily, String> _kFamilyLabel = {
  UnitFamily.pressure: 'Pressure',
  UnitFamily.length: 'Length',
  UnitFamily.weight: 'Weight',
  UnitFamily.angle: 'Angle',
  UnitFamily.torque: 'Torque',
  UnitFamily.springRate: 'Spring rate',
  UnitFamily.distance: 'Distance',
  UnitFamily.count: 'Count',
  UnitFamily.freeText: 'Free text',
};

class _AddFieldSheetState extends State<_AddFieldSheet> {
  Set<String> _existingKeys = {};
  bool _loading = true;
  String? _selectedChip;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _textValueController = TextEditingController();

  UnitFamily _family = UnitFamily.count;
  UnitDef _unit = unitDefById(UnitFamily.count, 'count');
  double _value = 0;

  @override
  void initState() {
    super.initState();
    DatabaseService(widget.user.uid)
        .getSettings(widget.uBikeID, widget.category, widget.uSetupID)
        .first
        .then((snap) {
      if (mounted) {
        final data = snap.data() as Map<String, dynamic>? ?? {};
        setState(() {
          _existingKeys = data.keys.toSet();
          _loading = false;
        });
      }
    }).catchError((_) {
      if (mounted) setState(() => _loading = false);
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _textValueController.dispose();
    super.dispose();
  }

  String get _resolvedKey {
    final text = _nameController.text.trim();
    if (text.isNotEmpty) return text;
    return _selectedChip ?? '';
  }

  bool get _isKnownKey => kFieldMeta.containsKey(_resolvedKey);
  FieldMeta? get _knownMeta => kFieldMeta[_resolvedKey];

  void _syncFamilyFromKey() {
    final meta = _knownMeta;
    if (meta != null) {
      _family = meta.family;
      _unit = meta.defaultUnit;
      _value = meta.min.clamp(meta.min, meta.max).toDouble();
    } else {
      final units = kUnitFamilies[_family] ?? const <UnitDef>[];
      _unit = units.isNotEmpty ? units.first : _unit;
    }
  }

  void _onFamilyChange(UnitFamily? f) {
    if (f == null) return;
    setState(() {
      _family = f;
      final units = kUnitFamilies[f] ?? const <UnitDef>[];
      _unit = units.isNotEmpty
          ? units.first
          : const UnitDef(id: '', label: '', toCanonical: 1.0);
      _value = 0;
    });
  }

  void _onUnitTap(UnitDef u) {
    if (u.id == _unit.id) return;
    setState(() {
      _value = convertValue(_value, _unit, u);
      _unit = u;
    });
  }

  void _onAdd() {
    final key = _resolvedKey;
    if (key.isEmpty) return;
    if (_existingKeys.contains(key)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"$key" already exists in this category.')),
      );
      return;
    }
    String stored;
    if (_family == UnitFamily.freeText) {
      stored = _textValueController.text.trim();
      if (stored.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter a value for the field.')),
        );
        return;
      }
    } else {
      stored = SettingValue.numeric(_value, _family, _unit).format();
    }
    Navigator.of(context).pop();
    final db = DatabaseService(widget.user.uid);
    db.setSetting(
      key,
      stored,
      widget.uBikeID,
      widget.category,
      widget.uSetupID,
    );
    if (!_isKnownKey) {
      db.setSettingMeta(
        key,
        _family.name,
        widget.uBikeID,
        widget.category,
        widget.uSetupID,
      );
    }
  }

  List<String> get _suggestions {
    final suggested = kSuggestedFieldKeys[widget.category] ?? [];
    return suggested.where((k) => !_existingKeys.contains(k)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final suggestions = _suggestions;
    _syncFamilyFromKey();

    return Padding(
      padding: EdgeInsets.only(
        left: 22, right: 22, top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: p.borderStrong,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Icon(Icons.add_rounded, size: 15, color: p.inkMuted),
              const SizedBox(width: 8),
              Text(
                'ADD FIELD',
                style: AppTextStyles.inter(
                  size: 11, weight: FontWeight.w800,
                  color: p.inkMuted, letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (_loading)
            const Center(child: CircularProgressIndicator.adaptive())
          else ...[
            if (suggestions.isNotEmpty) ...[
              _Dropdown<String>(
                value: _nameController.text.isEmpty ? _selectedChip : null,
                hint: 'Suggested fields',
                items: suggestions
                    .map((k) => DropdownMenuItem<String>(
                          value: k,
                          child: Text(k,
                              style: AppTextStyles.inter(
                                  size: 13, color: p.ink)),
                        ))
                    .toList(),
                onChanged: (k) {
                  if (k == null) return;
                  setState(() {
                    _selectedChip = k;
                    _nameController.clear();
                    _value = 0;
                  });
                },
              ),
              const SizedBox(height: 12),
            ],
            _TextField(
              controller: _nameController,
              hint: 'Custom field name',
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 20),
            if (_resolvedKey.isNotEmpty) ...[
              Row(
                children: [
                  FieldIcon(
                    asset: _knownMeta?.iconAsset ??
                        kDefaultFieldMeta.iconAsset,
                    size: 16,
                    color: p.inkMuted,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _resolvedKey.toUpperCase(),
                    style: AppTextStyles.inter(
                      size: 11, weight: FontWeight.w800,
                      color: p.inkMuted, letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (!_isKnownKey)
                _FamilyDropdown(
                  value: _family,
                  onChanged: _onFamilyChange,
                ),
              if (!_isKnownKey) const SizedBox(height: 14),
              if (_family != UnitFamily.freeText &&
                  (kUnitFamilies[_family]?.length ?? 0) > 1) ...[
                _UnitChipsRow(
                  units: kUnitFamilies[_family]!,
                  selected: _unit,
                  onTap: _onUnitTap,
                ),
                const SizedBox(height: 14),
              ],
              if (_family == UnitFamily.freeText)
                _TextField(
                  controller: _textValueController,
                  hint: 'Value',
                )
              else
                _buildNumericEditor(),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: p.accent,
                  foregroundColor: p.accentInk,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                onPressed: _resolvedKey.isEmpty ? null : _onAdd,
                child: Text(
                  'ADD',
                  style: AppTextStyles.inter(
                    size: 13, weight: FontWeight.w800,
                    color: p.accentInk, letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNumericEditor() {
    final meta = _knownMeta;
    double minInActive, maxInActive;
    if (meta != null) {
      final defaultUnit = meta.defaultUnit;
      minInActive = convertValue(meta.min, defaultUnit, _unit);
      maxInActive = convertValue(meta.max, defaultUnit, _unit);
    } else {
      minInActive = 0;
      maxInActive = 100;
    }
    final step =
        _unit.decimals <= 0 ? 1.0 : math.pow(10, -_unit.decimals).toDouble();
    return SettingValueEditor(
      key: ValueKey('value-editor-$_resolvedKey-${_unit.id}'),
      initialValue: _value,
      min: minInActive,
      max: maxInActive,
      step: step,
      decimals: _unit.decimals,
      unitLabel: _unit.label,
      onChanged: (v) => _value = v,
    );
  }
}

class _UnitChipsRow extends StatelessWidget {
  final List<UnitDef> units;
  final UnitDef selected;
  final ValueChanged<UnitDef> onTap;

  const _UnitChipsRow({
    required this.units,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: units.map((u) {
        final isSelected = u.id == selected.id;
        return GestureDetector(
          onTap: () => onTap(u),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected ? p.accent : p.surface2,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isSelected ? p.accent : p.border),
            ),
            child: Text(
              u.label.isEmpty ? u.id : u.label,
              style: AppTextStyles.inter(
                size: 11,
                weight: FontWeight.w700,
                color: isSelected ? p.accentInk : p.inkMuted,
                letterSpacing: 0.5,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _FamilyDropdown extends StatelessWidget {
  final UnitFamily value;
  final ValueChanged<UnitFamily?> onChanged;
  const _FamilyDropdown({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return _Dropdown<UnitFamily>(
      value: value,
      hint: 'Field type',
      items: UnitFamily.values
          .map((f) => DropdownMenuItem<UnitFamily>(
                value: f,
                child: Text(
                  _kFamilyLabel[f] ?? f.name,
                  style: AppTextStyles.inter(
                      size: 13, color: context.palette.ink),
                ),
              ))
          .toList(),
      onChanged: onChanged,
    );
  }
}

class _TextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String>? onChanged;
  const _TextField({required this.controller, required this.hint, this.onChanged});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return TextField(
      controller: controller,
      style: AppTextStyles.inter(size: 13, color: p.ink),
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTextStyles.inter(size: 13, color: p.inkDim),
        filled: true,
        fillColor: p.surface2,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: p.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: p.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: p.accent),
        ),
      ),
    );
  }
}

class _Dropdown<T> extends StatelessWidget {
  final T? value;
  final String hint;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  const _Dropdown({
    required this.value,
    required this.hint,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return DropdownButtonFormField<T>(
      initialValue: value,
      hint: Text(hint, style: AppTextStyles.inter(size: 13, color: p.inkDim)),
      icon: Icon(Icons.keyboard_arrow_down_rounded, color: p.inkMuted),
      dropdownColor: p.surface,
      style: AppTextStyles.inter(size: 13, color: p.ink),
      decoration: InputDecoration(
        filled: true,
        fillColor: p.surface2,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: p.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: p.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: p.accent),
        ),
      ),
      items: items,
      onChanged: onChanged,
    );
  }
}
