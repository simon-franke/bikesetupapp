import 'package:flutter/material.dart';
import 'package:bikesetupapp/common/theme/theme_data.dart';

class ThemeSelector extends StatelessWidget {
  const ThemeSelector(
      {super.key, required this.selected, required this.onChanged});
  final ThemeMode selected;
  final ValueChanged<ThemeMode>? onChanged;
  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          for (final mode in [
            ThemeMode.system,
            ThemeMode.light,
            ThemeMode.dark
          ]) ...[
            if (mode != ThemeMode.system) const SizedBox(width: 12),
            Expanded(
                child: _ThemeOption(
                    mode: mode,
                    selected: selected == mode,
                    onTap: onChanged == null ? null : () => onChanged!(mode))),
          ],
        ]),
      ]);
}

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({required this.mode, required this.selected, this.onTap});
  final ThemeMode mode;
  final bool selected;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final label = switch (mode) {
      ThemeMode.system => 'System',
      ThemeMode.light => 'Light',
      ThemeMode.dark => 'Dark'
    };
    return Semantics(
        button: true,
        selected: selected,
        label: '$label theme',
        child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(children: [
                  ExcludeSemantics(
                      child: Container(
                          height: 90,
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: selected ? p.accentText : p.border,
                                  width: selected ? 2 : 1)),
                          child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: mode == ThemeMode.system
                                  ? const Row(children: [
                                      Expanded(
                                          child: _Preview(AppPalette.light)),
                                      Expanded(child: _Preview(AppPalette.dark))
                                    ])
                                  : _Preview(mode == ThemeMode.dark
                                      ? AppPalette.dark
                                      : AppPalette.light)))),
                  const SizedBox(height: 10),
                  Text(label,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight:
                              selected ? FontWeight.w600 : FontWeight.w400,
                          color: selected ? p.accentText : p.ink)),
                ]))));
  }
}

class _Preview extends StatelessWidget {
  const _Preview(this.palette);
  final AppPalette palette;
  @override
  Widget build(BuildContext context) => ColoredBox(
      color: palette.bg,
      child: Padding(
          padding: const EdgeInsets.all(8),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Align(
                alignment: Alignment.centerLeft,
                child:
                    Container(width: 22, height: 3, color: palette.inkMuted)),
            const SizedBox(height: 8),
            Expanded(
                child: DecoratedBox(
                    decoration: BoxDecoration(
                        color: palette.surface,
                        borderRadius: BorderRadius.circular(4)),
                    child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                  width: 18, height: 3, color: palette.ink),
                              const SizedBox(height: 6),
                              Container(height: 2, color: palette.border),
                            ])))),
            const SizedBox(height: 7),
            Container(
                height: 7,
                decoration: BoxDecoration(
                    color: palette.surface2,
                    borderRadius: BorderRadius.circular(4))),
          ])));
}
