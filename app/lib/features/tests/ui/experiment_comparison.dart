import 'package:bikesetupapp/features/setups/ui/setup_card.dart';
import 'package:bikesetupapp/features/setups/ui/field_meta.dart';
import 'package:flutter/material.dart';
import 'package:bikesetupapp/common/theme/theme_data.dart';
import 'package:bikesetupapp/features/setups/ui/setting_display.dart';
import 'package:bikesetupapp/features/setups/models/unit_system.dart';
import '../models/setup_test.dart';

class ExperimentComparison extends StatelessWidget {
  const ExperimentComparison(
      {super.key,
      required this.test,
      required this.badge,
      this.showName = true});

  final SetupTest test;
  final String badge;
  final bool showName;

  @override
  Widget build(BuildContext context) => SetupCard(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(badge,
            style: AppTextStyles.label.copyWith(color: context.palette.ink)),
        if (showName) ...[
          const SizedBox(height: 18),
          Text(test.name, style: AppTextStyles.label)
        ],
        const SizedBox(height: 24),
        _values(context, test),
      ]));

  Widget _values(BuildContext context, SetupTest test) =>
      LayoutBuilder(builder: (context, constraints) {
        final p = context.palette;
        String value(TestChange change, {required bool before}) {
          final raw = before ? change.before : change.after;
          if (raw.isEmpty) return before ? 'No previous value' : 'Removed';
          return settingDisplayValue(change.field, raw,
              familyOverride: unitFamilyFromName(
                  test.fieldMetadata[change.category]?[change.field] ?? ''));
        }

        if (constraints.maxWidth < 290 ||
            MediaQuery.textScalerOf(context).scale(16) > 21) {
          Widget measurement(String label, String text,
                  {bool changed = false}) =>
              Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style:
                            AppTextStyles.caption.copyWith(color: p.inkMuted)),
                    const SizedBox(height: 4),
                    Text(text,
                        style: AppTextStyles.label
                            .copyWith(color: changed ? p.playfulText : p.ink)),
                  ]);

          return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < test.changes.length; i++) ...[
                  if (i > 0) const Divider(height: 32),
                  Text(
                      '${categoryLabel(test.changes[i].category)} ${test.changes[i].field.toLowerCase()}',
                      style: AppTextStyles.body),
                  const SizedBox(height: 12),
                  Wrap(spacing: 24, runSpacing: 12, children: [
                    measurement(
                        'Baseline', value(test.changes[i], before: true)),
                    measurement('New', value(test.changes[i], before: false),
                        changed: true),
                  ]),
                ],
              ]);
        }

        return Table(
            border: TableBorder(
                horizontalInside: BorderSide(color: context.palette.border)),
            columnWidths: const {
              0: FlexColumnWidth(2.2),
              1: FlexColumnWidth(),
              2: FlexColumnWidth()
            },
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            children: [
              TableRow(children: [
                Text('Setting',
                    style: AppTextStyles.caption.copyWith(color: p.inkMuted)),
                Text('Baseline',
                    textAlign: TextAlign.right,
                    style: AppTextStyles.caption.copyWith(color: p.inkMuted)),
                Text('New',
                    textAlign: TextAlign.right,
                    style: AppTextStyles.caption.copyWith(color: p.inkMuted))
              ]),
              for (final c in test.changes)
                TableRow(children: [
                  Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Text(
                          '${categoryLabel(c.category)} ${c.field.toLowerCase()}')),
                  Text(value(c, before: true), textAlign: TextAlign.right),
                  Text(value(c, before: false),
                      textAlign: TextAlign.right,
                      style: TextStyle(color: context.palette.playfulText)),
                ])
            ]);
      });
}
