import 'package:bikesetupapp/app_services/theme_data.dart';
import 'package:bikesetupapp/database_service/database.dart';
import 'package:bikesetupapp/widgets/field_meta.dart';
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

class _AddFieldSheetState extends State<_AddFieldSheet> {
  Set<String> _existingKeys = {};
  bool _loading = true;
  String? _selectedChip;
  int _value = 0;
  final TextEditingController _nameController = TextEditingController();

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
    super.dispose();
  }

  String get _resolvedKey {
    final text = _nameController.text.trim();
    if (text.isNotEmpty) return text;
    return _selectedChip ?? '';
  }

  FieldMeta get _resolvedMeta => kFieldMeta[_resolvedKey] ?? kDefaultFieldMeta;

  List<String> get _suggestions {
    final suggested = kSuggestedFieldKeys[widget.category] ?? [];
    return suggested.where((k) => !_existingKeys.contains(k)).toList();
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
    Navigator.of(context).pop();
    DatabaseService(widget.user.uid).setSetting(
      key,
      '$_value',
      widget.uBikeID,
      widget.category,
      widget.uSetupID,
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final suggestions = _suggestions;
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
              _Dropdown(
                value: _nameController.text.isEmpty ? _selectedChip : null,
                hint: 'Suggested fields',
                items: suggestions,
                onChanged: (k) {
                  if (k == null) return;
                  setState(() {
                    _selectedChip = k;
                    _nameController.clear();
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
                  Icon(_resolvedMeta.icon, size: 16, color: p.inkMuted),
                  const SizedBox(width: 8),
                  Text(
                    _resolvedKey.toUpperCase(),
                    style: AppTextStyles.inter(
                      size: 11, weight: FontWeight.w800,
                      color: p.inkMuted, letterSpacing: 1.5,
                    ),
                  ),
                  if (_resolvedMeta.unit.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Text(
                      '(${_resolvedMeta.unit})',
                      style: AppTextStyles.inter(size: 11, color: p.inkDim),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 18),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _StepButton(
                  icon: Icons.remove_rounded,
                  onTap: () => setState(() => _value = (_value - 1).clamp(0, 999)),
                ),
                Column(
                  children: [
                    Text(
                      '$_value',
                      style: AppTextStyles.mono(
                        size: 56, weight: FontWeight.w700,
                        color: p.ink, letterSpacing: -2.5, height: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _resolvedMeta.unit,
                      style: AppTextStyles.inter(
                        size: 12, weight: FontWeight.w600, color: p.inkMuted,
                      ),
                    ),
                  ],
                ),
                _StepButton(
                  icon: Icons.add_rounded,
                  onTap: () => setState(() => _value = (_value + 1).clamp(0, 999)),
                ),
              ],
            ),
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

class _Dropdown extends StatelessWidget {
  final String? value;
  final String hint;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  const _Dropdown({
    required this.value,
    required this.hint,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return DropdownButtonFormField<String>(
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
      items: items
          .map((k) => DropdownMenuItem(
                value: k,
                child: Text(k, style: AppTextStyles.inter(size: 13, color: p.ink)),
              ))
          .toList(),
      onChanged: onChanged,
    );
  }
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _StepButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 60, height: 60,
        decoration: BoxDecoration(
          color: p.surface2,
          border: Border.all(color: p.border),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(icon, size: 24, color: p.ink),
      ),
    );
  }
}
