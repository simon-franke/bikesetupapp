import 'package:bikesetupapp/bike_enums/component_type.dart';
import 'package:bikesetupapp/database_service/service_database.dart';
import 'package:bikesetupapp/models/service_component.dart';
import 'package:bikesetupapp/models/service_entry.dart';
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
    backgroundColor: Theme.of(context).cardTheme.color,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
  final TextEditingController _mileageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _mileageController.text = widget.currentMileageKm.round().toString();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _intervalController.dispose();
    _mileageController.dispose();
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
    final mileage =
        double.tryParse(_mileageController.text.trim()) ?? widget.currentMileageKm;

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
    return Padding(
      padding: EdgeInsets.only(
        left: 32,
        right: 32,
        top: 28,
        bottom: MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.color
                      ?.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'ADD COMPONENT',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    letterSpacing: 1.5,
                    fontSize: 11,
                  ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 110,
              child: GridView.builder(
                scrollDirection: Axis.horizontal,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 0.5,
                ),
                itemCount: ComponentType.values.length,
                itemBuilder: (context, index) {
                  final type = ComponentType.values[index];
                  final isSelected = _selectedType == type;
                  return GestureDetector(
                    onTap: () => _onTypeSelected(type),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFFD4883A).withValues(alpha: 0.2)
                            : Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFFD4883A)
                              : Colors.white.withValues(alpha: 0.1),
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          type.label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                            color: isSelected
                                ? const Color(0xFFD4883A)
                                : Colors.white.withValues(alpha: 0.7),
                          ),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            if (_selectedType != null) ...[
              _buildTextField('Component name', _nameController),
              const SizedBox(height: 12),
              _buildTextField('Service interval (km)', _intervalController,
                  keyboardType: TextInputType.number),
              const SizedBox(height: 12),
              _buildTextField(
                  'Mileage at last service (km)', _mileageController,
                  keyboardType: TextInputType.number),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context)
                        .floatingActionButtonTheme
                        .backgroundColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _onSave,
                  child: Text(
                    'Add Component',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String hint, TextEditingController controller,
      {TextInputType? keyboardType}) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: Theme.of(context).textTheme.labelSmall,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            width: 2,
            color: Theme.of(context).textTheme.labelMedium?.color ??
                Theme.of(context).colorScheme.onSurface,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            width: 2,
            color: Theme.of(context).textTheme.labelMedium?.color ??
                Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
      onChanged: (_) => setState(() {}),
    );
  }
}
