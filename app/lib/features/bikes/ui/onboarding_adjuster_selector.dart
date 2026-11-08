import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:bikesetupapp/common/theme/theme_data.dart';
import 'package:bikesetupapp/common/ui/app_components.dart';
import 'adjuster_dial.dart';

class OnboardingAdjusterSelector extends StatelessWidget {
  const OnboardingAdjusterSelector(
      {super.key,
      required this.label,
      required this.selected,
      required this.onChanged});
  final String label;
  final Set<String> selected;
  final ValueChanged<Set<String>> onChanged;
  @override
  Widget build(BuildContext context) {
    final low = 'Low Speed $label', high = 'High Speed $label';
    final mode = selected.contains(label)
        ? 'Single'
        : selected.contains(low) || selected.contains(high)
            ? 'Low / high speed'
            : 'None';
    Widget choice(String value, String title, int count) => Semantics(
        selected: mode == value,
        child: AppSelectionSurface(
            selected: mode == value,
            child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                    animationDuration: MediaQuery.disableAnimationsOf(context)
                        ? Duration.zero
                        : const Duration(milliseconds: 220),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                    side: mode == value
                        ? BorderSide(color: context.palette.accentText)
                        : BorderSide.none,
                    backgroundColor:
                        mode == value ? Colors.transparent : context.palette.bg,
                    foregroundColor: mode == value
                        ? context.palette.accentText
                        : context.palette.ink,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14))),
                onPressed: () {
                  final next = {...selected};
                  next.removeAll([label, low, high]);
                  if (value == 'Single') next.add(label);
                  if (value == 'Low / high speed') {
                    next.addAll([low, high]);
                  }
                  onChanged(next);
                },
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  AdjusterDial(selected: mode == value, count: count),
                  const SizedBox(height: 6),
                  Text(title,
                      textAlign: TextAlign.center, style: AppTextStyles.label),
                  const SizedBox(height: 8),
                  Icon(
                      mode == value
                          ? CupertinoIcons.checkmark_circle_fill
                          : CupertinoIcons.circle,
                      size: AppIconSizes.compact,
                      color: mode == value
                          ? context.palette.accentText
                          : context.palette.inkDim),
                ]))));

    return Padding(
        padding: const EdgeInsets.only(bottom: 28),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(label,
              style: AppTextStyles.label.copyWith(color: context.palette.ink)),
          const SizedBox(height: 14),
          LayoutBuilder(builder: (context, constraints) {
            final choices = [
              choice('None', 'None', 0),
              choice('Single', 'One dial', 1),
              choice('Low / high speed', 'Low + high', 2)
            ];
            if (MediaQuery.textScalerOf(context).scale(13) > 20 ||
                constraints.maxWidth < 300) {
              return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final item in choices)
                      Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: item)
                  ]);
            }

            return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: choices[0]),
              const SizedBox(width: 8),
              Expanded(child: choices[1]),
              const SizedBox(width: 8),
              Expanded(child: choices[2]),
            ]);
          }),
        ]));
  }
}
