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
    backgroundColor: Theme.of(context).cardTheme.color,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
    final suggestions = _suggestions;
    return Padding(
      padding: EdgeInsets.only(
        left: 32,
        right: 32,
        top: 28,
        bottom: MediaQuery.of(context).viewInsets.bottom + 28,
      ),
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
            'ADD FIELD',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  letterSpacing: 1.5,
                  fontSize: 11,
                ),
          ),
          const SizedBox(height: 16),
          if (_loading)
            const Center(child: CircularProgressIndicator.adaptive())
          else ...[
            if (suggestions.isNotEmpty) ...[
              DropdownButtonFormField<String>(
                initialValue: _nameController.text.isEmpty ? _selectedChip : null,
                hint: Text(
                  'Suggested fields',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                decoration: InputDecoration(
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      width: 2,
                      color: Theme.of(context).textTheme.labelMedium?.color ?? Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      width: 2,
                      color: Theme.of(context).textTheme.labelMedium?.color ?? Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
                items: suggestions
                    .map((k) => DropdownMenuItem(value: k, child: Text(k)))
                    .toList(),
                onChanged: (k) {
                  if (k == null) return;
                  setState(() {
                    _selectedChip = k;
                    _nameController.clear();
                  });
                },
              ),
              const SizedBox(height: 16),
            ],
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: 'Custom field name',
                hintStyle: Theme.of(context).textTheme.labelSmall,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    width: 2,
                    color: Theme.of(context).textTheme.labelMedium?.color ?? Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    width: 2,
                    color: Theme.of(context).textTheme.labelMedium?.color ?? Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 20),
            if (_resolvedKey.isNotEmpty) ...[
              Row(
                children: [
                  Icon(
                    _resolvedMeta.icon,
                    size: 18,
                    color: Theme.of(context)
                        .iconTheme
                        .color
                        ?.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _resolvedKey.toUpperCase(),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          letterSpacing: 1.5,
                          fontSize: 11,
                        ),
                  ),
                  if (_resolvedMeta.unit.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Text(
                      '(${_resolvedMeta.unit})',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 20),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _LocalStepButton(
                  icon: Icons.remove_rounded,
                  onTap: () =>
                      setState(() => _value = (_value - 1).clamp(0, 999)),
                ),
                Column(
                  children: [
                    Text(
                      '$_value',
                      style: Theme.of(context).textTheme.displayMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _resolvedMeta.unit,
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
                ),
                _LocalStepButton(
                  icon: Icons.add_rounded,
                  onTap: () =>
                      setState(() => _value = (_value + 1).clamp(0, 999)),
                ),
              ],
            ),
            const SizedBox(height: 32),
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
                onPressed: _resolvedKey.isEmpty ? null : _onAdd,
                child: Text(
                  'Add',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LocalStepButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _LocalStepButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: Theme.of(context)
              .floatingActionButtonTheme
              .backgroundColor
              ?.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: 30),
      ),
    );
  }
}
