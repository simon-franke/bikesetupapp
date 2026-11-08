import 'package:bikesetupapp/features/setups/ui/setup_card.dart';
import 'package:bikesetupapp/features/setups/ui/field_meta.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:bikesetupapp/common/theme/theme_data.dart';
import 'package:bikesetupapp/common/ui/app_components.dart';
import '../models/setup_test.dart';

String experimentDraftName(SetupTest test, String setupName) {
  if (test.name.isNotEmpty &&
      test.name != '$setupName test' &&
      test.name != '$setupName experiment') {
    return test.name;
  }

  final changes = test.changes;
  if (changes.isEmpty) return '$setupName experiment';

  if (changes
      .every((c) => c.category.endsWith('Tire') && c.field == 'Pressure')) {
    return 'Tire pressure experiment';
  }

  final categories = changes.map((c) => categoryLabel(c.category)).toSet();

  return categories.length == 1
      ? '${categories.single} experiment'
      : 'Setup experiment';
}

class ExperimentDraftCard extends StatelessWidget {
  const ExperimentDraftCard(
      {super.key,
      this.test,
      required this.setupName,
      required this.busy,
      required this.onContinue,
      this.onRename,
      this.onDiscard,
      this.showOptions = true});

  final SetupTest? test;
  final String setupName;
  final bool busy, showOptions;
  final VoidCallback? onContinue, onRename, onDiscard;

  @override
  Widget build(BuildContext context) {
    final test = this.test;
    final changes = test?.changes ?? <TestChange>[];

    return SetupCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
              child: Text(
                  test == null
                      ? 'Try a new setup'
                      : experimentDraftName(test, setupName),
                  style: AppTextStyles.label
                      .copyWith(color: context.palette.ink))),
          if (test != null && showOptions)
            AppObjectMenu(
                tooltip: 'Experiment options',
                title: experimentDraftName(test, setupName),
                onRename: busy ? null : onRename,
                onDiscard: busy ? null : onDiscard),
        ]),
        const SizedBox(height: 16),
        Text(
            test == null
                ? 'Tune your settings. See how it rides.'
                : '${changes.length} ${changes.length == 1 ? 'change' : 'changes'} in your draft',
            style:
                AppTextStyles.body.copyWith(color: context.palette.inkMuted)),
        if (test != null) ...[
          const SizedBox(height: 16),
          for (final change in changes.take(2))
            Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          '${categoryLabel(change.category)} ${change.field.toLowerCase()}',
                          style: AppTextStyles.body
                              .copyWith(color: context.palette.inkMuted)),
                      const SizedBox(height: 4),
                      Text('${change.before} → ${change.after}',
                          style: AppTextStyles.body
                              .copyWith(color: context.palette.playfulText)),
                    ])),
        ],
        const SizedBox(height: 24),
        SizedBox(
            width: double.infinity,
            child: AppActionButton(
                label:
                    test == null ? 'Create experiment' : 'Continue experiment',
                onPressed: busy ? null : onContinue)),
      ]),
    );
  }
}
