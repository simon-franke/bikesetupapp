import 'package:bikesetupapp/common/ui/app_haptics.dart';
import '../models/unit_system.dart';
import '../models/setup_configuration.dart';
import 'package:flutter/cupertino.dart';
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
                    Row(children: [
                      Expanded(
                          child: Text(categoryLabel(category),
                              style: const TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w600))),
                      IconButton(
                          tooltip:
                              'Add ${categoryLabel(category).toLowerCase()} setting',
                          icon: const Icon(CupertinoIcons.plus, size: 19),
                          onPressed: () => showAddFieldSheet(context,
                              user: user,
                              uBikeID: bike,
                              uSetupID: setup,
                              category: category)),
                    ]),
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
                              isDefault: isDefaultField(category, key));
                        }),
                  ],
                )),
          if (category == 'Fork' || category == 'Shock')
            Padding(
                padding: const EdgeInsets.only(bottom: 18),
                child: Text('Click counts are measured from fully closed.',
                    style: TextStyle(
                        fontSize: 12, color: context.palette.inkMuted))),
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
              final values = snapshot.data ?? <String, dynamic>{};
              final keys = [
                ...?(widget.configuredFields ??
                    kDefaultFieldKeys[widget.category]),
                ...values.keys.where((key) => !(widget.configuredFields ??
                        kDefaultFieldKeys[widget.category] ??
                        [])
                    .contains(key))
              ];
              return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final key in keys) ...[
                      if (key != keys.first)
                        Divider(height: 1, color: context.palette.border),
                      InkWell(
                          onTap: AppHaptics.wrap(() => widget.onEdit(
                              key,
                              values[key]?.toString() ?? '',
                              unitFamilyFromName(
                                  metadata.data![key]?.toString() ?? ''))),
                          child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 17),
                              child: Row(children: [
                                Expanded(
                                    child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                      Text(key,
                                          style: const TextStyle(fontSize: 13)),
                                    ])),
                                const SizedBox(width: 12),
                                ConstrainedBox(
                                    constraints: BoxConstraints(
                                        maxWidth:
                                            MediaQuery.sizeOf(context).width *
                                                .3),
                                    child: Text(
                                        values[key]?.toString().isNotEmpty ==
                                                true
                                            ? values[key].toString()
                                            : snapshot.hasData
                                                ? 'Add'
                                                : '…',
                                        textAlign: TextAlign.end,
                                        style: AppTextStyles.mono(
                                            size: 14,
                                            weight: FontWeight.w500,
                                            color: context.palette.ink))),
                              ]))),
                    ],
                  ]);
            });
      });
}
