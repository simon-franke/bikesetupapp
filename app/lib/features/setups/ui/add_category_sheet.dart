import 'package:bikesetupapp/common/theme/theme_data.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../common/ui/app_components.dart';
import '../../../common/ui/app_sheet.dart';
import '../models/setup_configuration.dart';
import 'field_meta.dart';

// Tires is a single presentation group for the two stored tire categories.
final _categories = [
  'Tires',
  ...categoryPresets.keys
      .where((key) => key != 'FrontTire' && key != 'RearTire'),
];

Future<String?> showAddCategorySheet(BuildContext context, Set<String> active,
    {Set<String> retained = const {}}) async {
  ModalRoute<dynamic>? route;
  final result = await showAppSheet<String>(
      context: context,
      builder: (context) {
        route = ModalRoute.of(context);
        return _AddCategorySheet(active: active, retained: retained);
      });
  await route?.completed;
  return result;
}

class _AddCategorySheet extends StatefulWidget {
  const _AddCategorySheet({required this.active, required this.retained});

  final Set<String> active;
  final Set<String> retained;

  @override
  State<_AddCategorySheet> createState() => _AddCategorySheetState();
}

class _AddCategorySheetState extends State<_AddCategorySheet> {
  final name = TextEditingController();
  bool custom = false;
  String? error;

  List<String> get suggestions => {
        ..._categories,
        ...widget.retained
            .where((key) => key != 'FrontTire' && key != 'RearTire')
      }
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
      ...widget.retained,
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
                        icon: const Icon(CupertinoIcons.chevron_left,
                            size: AppIconSizes.compact),
                        onPressed: () => setState(() => custom = false)),
                  Expanded(
                      child: Text(showForm ? 'New category' : 'Add category',
                          style: AppTextStyles.heading)),
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

/// Asked only when the rider adds suspension, before anything is saved.
Future<String?> showSuspensionTypeSheet(
        BuildContext context, String category) =>
    showAppSheet<String>(
      context: context,
      builder: (sheet) => Padding(
        padding: appSheetPadding(sheet),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppSheetHeader(
                title: category == 'Fork'
                    ? 'What kind of fork?'
                    : 'What kind of rear shock?'),
            for (final type in ['Air', 'Coil'])
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(type, style: AppTextStyles.label),
                subtitle: Text(
                    type == 'Air'
                        ? 'Pressure and tokens'
                        : 'Spring rate and preload',
                    style: AppTextStyles.caption
                        .copyWith(color: sheet.palette.inkMuted)),
                trailing: Icon(CupertinoIcons.chevron_right,
                    size: AppIconSizes.compact, color: sheet.palette.inkMuted),
                onTap: () => Navigator.pop(sheet, type),
              ),
          ],
        ),
      ),
    );
