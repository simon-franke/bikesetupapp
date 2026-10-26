import '../models/setup_configuration.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bikesetupapp/app/app_dependencies.dart';
import 'package:bikesetupapp/common/layout/responsive_layout.dart';
import 'package:bikesetupapp/common/theme/theme_data.dart';
import 'package:bikesetupapp/common/ui/app_components.dart';
import 'package:bikesetupapp/common/ui/command_feedback.dart';
import 'control_panel_grid.dart';
import 'add_field_bottom_sheet.dart';
import 'field_meta.dart';
import 'inline_setting_editor.dart';
import 'setup_overview.dart';

/// Category content stays inside the workspace, preserving its bottom navigation.
class SetupCategoryView extends StatefulWidget {
  const SetupCategoryView(
      {super.key,
      required this.user,
      required this.bike,
      required this.setup,
      required this.category,
      this.configuration,
      required this.onTest});
  final User user;
  final String bike, setup, category;
  final VoidCallback onTest;
  final SetupConfiguration? configuration;
  @override
  State<SetupCategoryView> createState() => _SetupCategoryViewState();
}

class _SetupCategoryViewState extends State<SetupCategoryView> {
  (String, String, String)? selected;
  @override
  Widget build(BuildContext context) {
    final categories = widget.category == 'Tires'
        ? ['FrontTire', 'RearTire']
        : [widget.category];
    return ListView(
        padding: EdgeInsets.fromLTRB(
            20, 18, 20, MediaQuery.paddingOf(context).bottom + 24),
        children: [
          for (final category in categories)
            SetupCard(
                padding: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (categories.length > 1)
                      Row(children: [
                        Expanded(child: Text(categoryLabel(category),
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600))),
                        IconButton(
                            tooltip: 'Add ${categoryLabel(category).toLowerCase()} setting',
                            icon: const Icon(CupertinoIcons.plus, size: 19),
                            onPressed: () => showAddFieldSheet(context,
                                user: widget.user, uBikeID: widget.bike,
                                uSetupID: widget.setup, category: category)),
                      ]),
                    _CategoryRows(
                        key: ValueKey(category),
                        uid: widget.user.uid,
                        bike: widget.bike,
                        setup: widget.setup,
                        category: category,
                        configuredFields: widget.configuration?.fields[category],
                        onEdit: (key, value) {
                          if (ResponsiveLayout.isWide(context)) {
                            setState(() => selected = (category, key, value));
                          } else {
                            showSettingStepperSheet(context,
                                user: widget.user, uBikeID: widget.bike,
                                uSetupID: widget.setup, category: category,
                                settingKey: key, currentValue: value,
                                isDefault: isDefaultField(category, key));
                          }
                        }),
                    if (categories.length == 1)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                            icon: const Icon(CupertinoIcons.plus, size: 16),
                            label: const Text('Add setting'),
                            onPressed: () => showAddFieldSheet(context,
                                user: widget.user, uBikeID: widget.bike,
                                uSetupID: widget.setup, category: category))),
                  ],
                )),
          if (selected case final field?)
            Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: InlineSettingEditor(
                    key: ValueKey('${field.$1}/${field.$2}'),
                    name: field.$2,
                    value: field.$3,
                    onSave: (value) async {
                      await presentCommand(
                          context,
                          () => AppDependencies.of(context)
                              .forUser(widget.user.uid)
                              .setups
                              .setSetting(field.$2, value, widget.bike,
                                  field.$1, widget.setup));
                    })),
          if (widget.category == 'Fork' || widget.category == 'Shock')
            Padding(
                padding: const EdgeInsets.only(bottom: 18),
                child: Text('Click counts are measured from fully closed.',
                    style: TextStyle(
                        fontSize: 12, color: context.palette.inkMuted))),
          AppActionButton(label: 'Test a new setup', outlined: true,
              icon: CupertinoIcons.lab_flask, onPressed: widget.onTest),
        ]);
  }
}

class _CategoryRows extends StatefulWidget {
  const _CategoryRows(
      {super.key,
      required this.uid,
      required this.bike,
      required this.setup,
      required this.category,
      required this.onEdit,
      this.configuredFields});
  final String uid, bike, setup, category;
  final void Function(String, String) onEdit;
  final List<String>? configuredFields;
  @override
  State<_CategoryRows> createState() => _CategoryRowsState();
}

class _CategoryRowsState extends State<_CategoryRows> {
  late final stream = AppDependencies.of(context)
      .forUser(widget.uid)
      .setups
      .getSettings(widget.bike, widget.category, widget.setup);
  @override
  Widget build(BuildContext context) => StreamBuilder<Map<String, dynamic>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Text('Could not load settings.');
        if (!snapshot.hasData) return const LinearProgressIndicator();
        final values = snapshot.data!;
        final keys = [
          ...?(widget.configuredFields ?? kDefaultFieldKeys[widget.category]),
          ...values.keys.where((key) =>
              !(widget.configuredFields ?? kDefaultFieldKeys[widget.category] ?? []).contains(key))
        ];
        final groups = widget.category == 'GeneralSettings'
            ? ['Cockpit', 'Saddle', 'Frame geometry', 'Other settings'] : [''];
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          for (final group in groups)
            if (keys.any((key) => group.isEmpty || fitGroupFor(key) == group)) ...[
              if (group.isNotEmpty) Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 4),
                  child: Text(group, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600))),

          for (final key in keys.where((key) => group.isEmpty || fitGroupFor(key) == group)) ...[
            if (key != keys.first)
              Divider(height: 1, color: context.palette.border),
            InkWell(
                onTap: () => widget.onEdit(key, values[key]?.toString() ?? ''),
                child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 17),
                    child: Row(children: [
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text(
                                key,
                                style: const TextStyle(fontSize: 13)),
                          ])),
                      const SizedBox(width: 12),
                      ConstrainedBox(
                          constraints: BoxConstraints(
                              maxWidth: MediaQuery.sizeOf(context).width * .3),
                          child: Text(
                              values[key]?.toString().isNotEmpty == true
                                  ? values[key].toString()
                                  : 'Add',
                              textAlign: TextAlign.end,
                              style: AppTextStyles.mono(
                                  size: 14,
                                  weight: FontWeight.w500,
                                  color: context.palette.ink))),
                    ]))),
          ],
            ],
        ]);
      });
}
