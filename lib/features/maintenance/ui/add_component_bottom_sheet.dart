import 'package:bikesetupapp/common/ui/command_feedback.dart';
import 'package:bikesetupapp/app/app_dependencies.dart';
import 'package:bikesetupapp/common/ui/adaptive_modal.dart';
import 'package:bikesetupapp/common/ui/app_components.dart';
import 'package:bikesetupapp/common/theme/theme_data.dart';
import 'package:bikesetupapp/features/maintenance/models/component_type.dart';
import 'package:bikesetupapp/features/maintenance/ui/service_status.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

Future<void> showAddComponentSheet(
  BuildContext context, {
  required User user,
  required String uBikeID,
  required double? currentMileageKm,
}) {
  return showAdaptiveModal<void>(
    context: context,
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
  final double? currentMileageKm;

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
  bool _saving = false;
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

  Future<void> _onSave() async {
    if (_saving || _selectedType == null) return;
    final name = _nameController.text.trim();
    final interval = int.tryParse(_intervalController.text.trim()) ?? 0;
    if (name.isEmpty || interval <= 0) return;
    setState(() => _saving = true);
    final db = AppDependencies.of(context).forUser(widget.user.uid);
    final saved = await presentCommand(
        context,
        () => db.maintenance.createComponent(
            bikeId: widget.uBikeID,
            type: _selectedType!,
            name: name,
            serviceIntervalKm: interval,
            currentMileageKm: widget.currentMileageKm));
    if (!mounted) return;
    if (saved) {
      Navigator.of(context).pop();
    } else {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: EdgeInsets.only(
        left: 22,
        right: 22,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppSheetHandle(),
            const SizedBox(height: 22),
            Row(
              children: [
                Icon(Icons.build_rounded, size: 15, color: p.inkMuted),
                const SizedBox(width: 8),
                Text('Add component'),
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
                  onPressed: _saving ? null : _onSave,
                  child: Text(
                    'ADD COMPONENT',
                    style: AppTextStyles.inter(
                      size: 13,
                      weight: FontWeight.w800,
                      color: p.accentInk,
                      letterSpacing: 1,
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
  const _TypeChip(
      {required this.type, required this.selected, required this.onTap});

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
            color: selected ? p.accentText : p.border,
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
              color: selected ? p.accentText : p.inkMuted,
            ),
            const SizedBox(width: 6),
            Text(
              type.label,
              style: AppTextStyles.inter(
                size: 11.5,
                weight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? p.accentText : p.ink,
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
    return AppTextField(
        controller: controller,
        hint: hint,
        keyboardType: keyboardType,
        onChanged: onChanged);
  }
}
