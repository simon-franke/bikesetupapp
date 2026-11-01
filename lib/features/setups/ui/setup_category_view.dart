import 'package:bikesetupapp/common/ui/app_haptics.dart';
import '../models/unit_system.dart';
import '../models/setup_configuration.dart';
import 'package:bikesetupapp/common/ui/app_components.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bikesetupapp/app/app_dependencies.dart';
import 'package:bikesetupapp/common/theme/theme_data.dart';
import 'control_panel_grid.dart';
import 'add_field_bottom_sheet.dart';
import 'field_meta.dart';
import 'setup_overview.dart';

/// Category content stays inside the workspace, preserving its bottom navigation.
class SetupCategoryView extends StatelessWidget {
  const SetupCategoryView(
      {super.key,
      required this.user,
      required this.bike,
      required this.setup,
      required this.category,
      this.configuration});
  final User user;
  final String bike, setup, category;
  final SetupConfiguration? configuration;
  @override
  Widget build(BuildContext context) {
    final categories =
        category == 'Tires' ? ['FrontTire', 'RearTire'] : [category];
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
                    Text(categoryLabel(category), style: AppTextStyles.label),
                    const SizedBox(height: 8),
                    _CategoryRows(
                        key: ValueKey(category),
                        uid: user.uid,
                        bike: bike,
                        setup: setup,
                        category: category,
                        configuredFields: configuration?.fields[category],
                        onEdit: (key, value, family) {
                          showSettingStepperSheet(context,
                              user: user,
                              uBikeID: bike,
                              uSetupID: setup,
                              category: category,
                              settingKey: key,
                              currentValue: value,
                              familyOverride: family,
                              canDelete: true);
                        }),
                    AppAddButton(
                      label: 'Add setting',
                      tooltip:
                          'Add ${categoryLabel(category).toLowerCase()} setting',
                      onPressed: () => showAddFieldSheet(context,
                          user: user,
                          uBikeID: bike,
                          uSetupID: setup,
                          category: category),
                    ),
                  ],
                )),
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
  final void Function(String, String, UnitFamily?) onEdit;
  final List<String>? configuredFields;
  @override
  State<_CategoryRows> createState() => _CategoryRowsState();
}

class _CategoryRowsState extends State<_CategoryRows> {
  late final stream = AppDependencies.of(context)
      .forUser(widget.uid)
      .setups
      .getSettings(widget.bike, widget.category, widget.setup);
  late final metadataStream = AppDependencies.of(context)
      .forUser(widget.uid)
      .setups
      .getSettingsMeta(widget.bike, widget.category, widget.setup);
  @override
  Widget build(BuildContext context) => StreamBuilder<Map<String, dynamic>>(
      stream: metadataStream,
      builder: (context, metadata) {
        if (metadata.hasError) return const Text('Could not load settings.');
        if (!metadata.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        return StreamBuilder<Map<String, dynamic>>(
            stream: stream,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Text('Could not load settings.');
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final values = snapshot.data!;
              final keys = [
                ...?(widget.configuredFields ??
                    kDefaultFieldKeys[widget.category]),
                ...values.keys.where((key) => !(widget.configuredFields ??
                        kDefaultFieldKeys[widget.category] ??
                        [])
                    .contains(key))
              ].where(
                  (key) => values[key]?.toString().trim().isNotEmpty == true);
              return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final key in keys)
                      _SettingRow(
                        label: key,
                        value: values[key]?.toString() ?? '',
                        onTap: () => widget.onEdit(
                            key,
                            values[key]?.toString() ?? '',
                            unitFamilyFromName(
                                metadata.data![key]?.toString() ?? '')),
                      ),
                  ]);
            });
      });
}

/// Every setting uses the same label/value hierarchy and full-width tap target.
class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label, value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      button: true,
      child: InkWell(
        onTap: AppHaptics.wrap(onTap),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTextStyles.label.copyWith(color: p.ink)),
              const SizedBox(height: 6),
              Text(value,
                  style: AppTextStyles.body.copyWith(color: p.inkMuted)),
            ],
          ),
        ),
      ),
    );
  }
}
