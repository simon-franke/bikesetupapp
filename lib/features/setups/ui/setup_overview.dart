import 'package:bikesetupapp/common/ui/app_components.dart';
import 'package:bikesetupapp/common/ui/app_haptics.dart';
import '../models/setup_configuration.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bikesetupapp/app/app_dependencies.dart';
import 'package:bikesetupapp/common/theme/theme_data.dart';
import 'field_meta.dart';
import '../models/unit_system.dart';

String categoryLabel(String category) => switch (category) {
      'FrontTire' => 'Front tire',
      'RearTire' => 'Rear tire',
      'GeneralSettings' => 'Bike fit',
      _ => category,
    };

class SetupCard extends StatelessWidget {
  const SetupCard(
      {super.key, required this.child, this.padding = 20, this.onTap});
  final double padding;
  final Widget child;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
          color: context.palette.surface,
          borderRadius: BorderRadius.circular(19),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
              onTap: AppHaptics.wrap(onTap),
              child: Padding(padding: EdgeInsets.all(padding), child: child))));
}

class SetupOverview extends StatelessWidget {
  const SetupOverview(
      {super.key,
      required this.user,
      required this.bike,
      required this.setup,
      required this.configuration,
      this.onAddCategory,
      required this.onCategory});
  final User user;
  final String bike, setup;

  final SetupConfiguration configuration;
  final ValueChanged<String> onCategory;
  final VoidCallback? onAddCategory;
  @override
  Widget build(BuildContext context) => ListView(
          padding: EdgeInsets.fromLTRB(
              20,
              MediaQuery.paddingOf(context).top + 12,
              20,
              MediaQuery.paddingOf(context).bottom + 24),
          children: [
            if (configuration.fields.keys
                .any((key) => ['FrontTire', 'RearTire'].contains(key)))
              SetupCard(
                  padding: 17,
                  onTap: () => onCategory('Tires'),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(children: [
                          Expanded(
                              child: Text('Tires', style: AppTextStyles.label)),
                          Icon(CupertinoIcons.chevron_right,
                              size: AppIconSizes.compact)
                        ]),
                        const SizedBox(height: 16),
                        IntrinsicHeight(
                            child: Row(children: [
                          for (final c in ['FrontTire', 'RearTire'].where(
                              (c) => configuration.fields.containsKey(c))) ...[
                            if (c == 'RearTire' &&
                                (configuration.fields
                                    .containsKey('FrontTire'))) ...[
                              VerticalDivider(
                                  width: 38,
                                  thickness: 1,
                                  color: context.palette.border),
                            ],
                            Expanded(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                  Text(c == 'FrontTire' ? 'Front' : 'Rear',
                                      style: AppTextStyles.caption.copyWith(
                                          color: context.palette.inkMuted)),
                                  _Values(
                                      user: user,
                                      bike: bike,
                                      setup: setup,
                                      category: c,
                                      pressureOnly: true),
                                ])),
                          ],
                        ])),
                      ])),
            for (final category in (configuration.fields.keys.toList()).where(
                (category) => !['FrontTire', 'RearTire'].contains(category)))
              SetupCard(
                  padding: 17,
                  onTap: () => onCategory(category),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Expanded(
                              child: Text(categoryLabel(category),
                                  style: AppTextStyles.label)),
                          const Icon(CupertinoIcons.chevron_right,
                              size: AppIconSizes.compact)
                        ]),
                        if (category != 'GeneralSettings') ...[
                          _Values(
                              user: user,
                              bike: bike,
                              setup: setup,
                              category: category,
                              topPadding: 16,
                              pressureOnly:
                                  category == 'Fork' || category == 'Shock'),
                        ],
                      ])),
            if (onAddCategory != null)
              AppAddButton(label: 'Add category', onPressed: onAddCategory),
          ]);
}

class _Values extends StatefulWidget {
  const _Values(
      {required this.user,
      required this.bike,
      required this.setup,
      required this.category,
      this.pressureOnly = false,
      this.topPadding = 0});
  final User user;
  final String bike, setup, category;
  final bool pressureOnly;
  final double topPadding;
  @override
  State<_Values> createState() => _ValuesState();
}

class _ValuesState extends State<_Values> {
  late final stream = AppDependencies.of(context)
      .forUser(widget.user.uid)
      .setups
      .getSettings(widget.bike, widget.category, widget.setup);
  @override
  Widget build(BuildContext context) => StreamBuilder<Map<String, dynamic>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Padding(
            padding: EdgeInsets.only(top: widget.topPadding),
            child: const Text('Could not load settings'),
          );
        }
        if (!snapshot.hasData) return const SizedBox(height: 48);
        final values = snapshot.data!;
        bool hasValue(String key) =>
            values[key]?.toString().trim().isNotEmpty == true;
        if (widget.pressureOnly &&
            (widget.category == 'Fork' || widget.category == 'Shock') &&
            !hasValue('Pressure')) {
          return const SizedBox.shrink();
        }
        if (!widget.pressureOnly && !values.keys.any(hasValue)) {
          return Padding(
              padding: EdgeInsets.only(top: widget.topPadding),
              child: Text(
                  widget.category == 'GeneralSettings'
                      ? 'Add fit measurements'
                      : 'Add ${widget.category.toLowerCase()} settings',
                  style: AppTextStyles.body
                      .copyWith(color: context.palette.accentText)));
        }
        Widget value(String key, {bool large = false}) {
          final meta = kFieldMeta[key];
          final raw = values[key]?.toString() ?? '';
          final parsed = SettingValue.parse(raw,
              fallbackFamily: meta?.family, fallbackUnit: meta?.defaultUnit);
          final number = parsed.number == null
              ? (raw.isEmpty ? 'Add pressure' : raw)
              : formatNumber(parsed.number!, parsed.unit?.decimals ?? 0);
          return Text.rich(TextSpan(children: [
            if (!large)
              TextSpan(
                  text: '${switch (key) {
                    'Low Speed Rebound' => 'LSR',
                    'High Speed Rebound' => 'HSR',
                    'Low Speed Compression' => 'LSC',
                    'High Speed Compression' => 'HSC',
                    'Compression' => 'Comp.',
                    'Tokens' =>
                      widget.category == 'Shock' ? 'Spacers' : 'Tokens',
                    'Stack Height' => 'Stack',
                    'Seat Height' => 'Seat',
                    _ => key
                  }}  ',
                  style: AppTextStyles.caption
                      .copyWith(color: context.palette.inkMuted)),
            TextSpan(
                text: number,
                style: (large ? AppTextStyles.heading : AppTextStyles.label)
                    .copyWith(color: context.palette.ink)),
            if (large || key == 'Reach' || key.contains('Height'))
              TextSpan(
                  text: ' ${parsed.unit?.label ?? ''}',
                  style: AppTextStyles.caption
                      .copyWith(color: context.palette.inkMuted)),
          ]));
        }

        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(height: widget.topPadding),
          if (widget.pressureOnly)
            ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48, minWidth: 80),
                child: Align(
                    alignment: Alignment.centerLeft,
                    child: hasValue('Pressure')
                        ? value('Pressure', large: true)
                        : Text('Set pressure',
                            style: AppTextStyles.body
                                .copyWith(color: context.palette.accentText))))
          else if (hasValue('Pressure') || hasValue('Sag'))
            Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                children: [
                  if (hasValue('Pressure')) value('Pressure', large: true),
                  if (hasValue('Sag'))
                    Text('${values['Sag']} sag',
                        style: AppTextStyles.caption
                            .copyWith(color: context.palette.inkMuted)),
                ]),
          if (!widget.pressureOnly &&
              !hasValue('Pressure') &&
              !hasValue('Sag')) ...[
            Wrap(spacing: 16, runSpacing: 12, children: [
              for (final key in [
                ...?kDefaultFieldKeys[widget.category],
                ...values.keys.where((k) =>
                    !(kDefaultFieldKeys[widget.category] ?? []).contains(k))
              ].where(hasValue).take(2))
                value(key)
            ]),
          ]
        ]);
      });
}
