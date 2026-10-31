import 'package:flutter/material.dart';
import 'package:bikesetupapp/common/theme/theme_data.dart';
import 'app_components.dart';

class AppUnitOption {
  const AppUnitOption(this.id, this.symbol, this.label);
  final String id;
  final String symbol;
  final String label;
}

/// A value's unit, with the same selection sheet wherever units are editable.
class AppUnitSelector extends StatelessWidget {
  const AppUnitSelector(
      {super.key,
      required this.value,
      required this.options,
      required this.onChanged});
  final String value;
  final List<AppUnitOption> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final selected = options.firstWhere((option) => option.id == value);
    final label = Text(selected.symbol,
        style: TextStyle(fontSize: 16, color: context.palette.inkMuted));
    if (options.length < 2) return label;
    return Semantics(
      label: 'Unit: ${selected.label}',
      button: true,
      excludeSemantics: true,
      child: TextButton(
        style: TextButton.styleFrom(
          foregroundColor: context.palette.inkMuted,
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 12),
        ),
        onPressed: () async {
          final result = await showAppOptionsSheet(
              context: context,
              title: 'Unit',
              entries: [
                for (final option in options)
                  AppSheetOption(
                      value: option.id,
                      label: option.label,
                      selected: option.id == value)
              ]);
          if (context.mounted && result != null && result != value) {
            onChanged(result);
          }
        },
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          label,
          const SizedBox(width: 4),
          const Icon(Icons.keyboard_arrow_down_rounded, size: 18)
        ]),
      ),
    );
  }
}
