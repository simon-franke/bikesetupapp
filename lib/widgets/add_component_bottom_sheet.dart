import 'package:bikesetupapp/app_services/theme_data.dart';
import 'package:bikesetupapp/bike_enums/component_type.dart';
import 'package:bikesetupapp/database_service/service_database.dart';
import 'package:bikesetupapp/models/service_component.dart';
import 'package:bikesetupapp/models/service_entry.dart';
import 'package:bikesetupapp/widgets/service_status.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

Future<void> showAddComponentSheet(
  BuildContext context, {
  required User user,
  required String uBikeID,
  required double currentMileageKm,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.palette.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (ctx) => _AddComponentSheet(
      user: user,
      uBikeID: uBikeID,
      currentMileageKm: currentMileageKm,
    ),
  );
}

class _AddComponentSheet extends StatefulWidget {
  final User user;
  final String uBikeID;
  final double currentMileageKm;

  const _AddComponentSheet({
    required this.user,
    required this.uBikeID,
    required this.currentMileageKm,
  });

  @override
  State<_AddComponentSheet> createState() => _AddComponentSheetState();
}

class _AddComponentSheetState extends State<_AddComponentSheet> {
  ComponentType? _selectedType;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _intervalController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _intervalController.dispose();
    super.dispose();
  }

  void _onTypeSelected(ComponentType type) {
    setState(() {
      _selectedType = type;
      _nameController.text = type.label;
      if (type.defaultIntervalKm > 0) {
        _intervalController.text = type.defaultIntervalKm.toString();
      } else {
        _intervalController.clear();
      }
    });
  }

  void _onSave() {
    if (_selectedType == null) return;
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    final interval = int.tryParse(_intervalController.text.trim()) ?? 0;
    if (interval <= 0) return;
    final double mileage = widget.currentMileageKm;

    final componentId = const Uuid().v4();
    final entryId = const Uuid().v4();
    final now = DateTime.now().toUtc();

    final component = ServiceComponent(
      id: componentId,
      bikeId: widget.uBikeID,
      type: _selectedType!,
      name: name,
      serviceIntervalKm: interval,
      createdAt: now,
    );

    final entry = ServiceEntry(
      id: entryId,
      componentId: componentId,
      mileageAtServiceKm: mileage,
      date: now,
      note: 'Initial setup',
    );

    final db = ServiceDatabaseService(widget.user.uid);
    db.addComponent(component);
    db.addServiceEntry(componentId, entry);

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: EdgeInsets.only(
        left: 22, right: 22, top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      child: SingleChildScrollView(
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
                Icon(Icons.build_rounded, size: 15, color: p.inkMuted),
                const SizedBox(width: 8),
                Text(
                  'ADD COMPONENT',
                  style: AppTextStyles.inter(
                    size: 11, weight: FontWeight.w800,
                    color: p.inkMuted, letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final type in ComponentType.values)
                  _TypeChip(
                    type: type,
                    selected: _selectedType == type,
                    onTap: () => _onTypeSelected(type),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            if (_selectedType != null) ...[
              _TextField(
                controller: _nameController,
                hint: 'Component name',
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 10),
              _TextField(
                controller: _intervalController,
                hint: 'Service interval (km)',
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 22),
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
                  onPressed: _onSave,
                  child: Text(
                    'ADD COMPONENT',
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
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  final ComponentType type;
  final bool selected;
  final VoidCallback onTap;
  const _TypeChip({required this.type, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? p.accent.withValues(alpha: 0.15) : p.surface2,
          border: Border.all(
            color: selected ? p.accent : p.border,
            width: selected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              iconForComponent(type.icon),
              size: 13,
              color: selected ? p.accent : p.inkMuted,
            ),
            const SizedBox(width: 6),
            Text(
              type.label,
              style: AppTextStyles.inter(
                size: 11.5,
                weight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? p.accent : p.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  const _TextField({
    required this.controller,
    required this.hint,
    this.keyboardType,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
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
