import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../common/ui/app_components.dart';
import '../../../common/ui/app_sheet.dart';
import '../models/setup_configuration.dart';
import 'setup_overview.dart';

const _categories = [
  'Tires',
  'Fork',
  'Shock',
  'Cockpit',
  'Saddle',
  'Frame',
  'GeneralSettings'
];

Future<String?> showAddCategorySheet(
    BuildContext context, Set<String> active) async {
  ModalRoute<dynamic>? route;
  final result = await showAppSheet<String>(
      context: context,
      builder: (context) {
        route = ModalRoute.of(context);
        return _AddCategorySheet(active: active);
      });
  await route?.completed;
  return result;
}

class _AddCategorySheet extends StatefulWidget {
  const _AddCategorySheet({required this.active});
  final Set<String> active;
  @override
  State<_AddCategorySheet> createState() => _AddCategorySheetState();
}

class _AddCategorySheetState extends State<_AddCategorySheet> {
  final name = TextEditingController();
  bool custom = false;
  String? error;
  List<String> get suggestions => _categories
      .where((key) => key == 'Tires'
          ? !widget.active.contains('FrontTire') ||
              !widget.active.contains('RearTire')
          : !widget.active.contains(key))
      .toList();
  @override
  void dispose() {
    name.dispose();
    super.dispose();
  }

  void add() {
    final value = name.text.trim();
    final existing = {
      ...widget.active,
      ..._categories,
      'FrontTire',
      'RearTire',
      'Front tire',
      'Rear tire',
      'Bike fit'
    };
    if (!SetupConfiguration.isValidCategoryName(value)) {
      setState(() => error = value.isEmpty
          ? 'Enter a category name.'
          : 'Choose a shorter name without special characters.');
    } else if (existing
        .any((key) => key.toLowerCase() == value.toLowerCase())) {
      setState(() => error = 'This category already exists.');
    } else {
      Navigator.pop(context, value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final showForm = custom || suggestions.isEmpty;
    return SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
              22, 12, 22, MediaQuery.viewInsetsOf(context).bottom + 28),
          child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const AppSheetHandle(),
                const SizedBox(height: 18),
                Row(children: [
                  if (custom && suggestions.isNotEmpty)
                    IconButton(
                        tooltip: 'Back',
                        icon: const Icon(CupertinoIcons.chevron_left, size: 20),
                        onPressed: () => setState(() => custom = false)),
                  Expanded(
                      child: Text(showForm ? 'New category' : 'Add category',
                          style: const TextStyle(
                              fontSize: 22, fontWeight: FontWeight.w600))),
                ]),
                const SizedBox(height: 22),
                if (!showForm) ...[
                  for (final category in suggestions)
                    AppSuggestionTile(
                        label: categoryLabel(category),
                        onTap: () => Navigator.pop(context, category)),
                  AppSuggestionTile(
                      label: 'Add new',
                      isNew: true,
                      onTap: () => setState(() => custom = true)),
                ] else ...[
                  AppTextField(
                      controller: name,
                      hint: 'Category name',
                      autofocus: true,
                      errorText: error,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => add(),
                      onChanged: (_) => setState(() => error = null)),
                  const SizedBox(height: 24),
                  AppActionButton(label: 'Add category', onPressed: add),
                ],
              ]),
        ));
  }
}
