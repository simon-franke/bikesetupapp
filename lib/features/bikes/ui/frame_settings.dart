import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:bikesetupapp/common/theme/theme_data.dart';
import 'package:bikesetupapp/common/ui/app_components.dart';

class FrameSettings extends StatelessWidget {
  const FrameSettings({super.key, required this.values, required this.onChanged});
  final Map<String, String> values;
  final void Function(String, String) onChanged;
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    _Positions(key: const ValueKey('flip-chip'), label: 'Flip chip', value: values['Flip chip']!,
      choices: const ['Low', 'Standard', 'High'],
      onChanged: (value) => onChanged('Flip chip', value)),
    const SizedBox(height: 24),
    _Positions(key: const ValueKey('headset-cups'), label: 'Headset cups', value: values['Headset cups']!,
      choices: const ['Slacker', 'Neutral', 'Steeper'], headset: true,
      onChanged: (value) => onChanged('Headset cups', value)),
  ]);
}

class _Positions extends StatefulWidget {
  const _Positions({super.key, required this.label, required this.value, required this.choices,
    required this.onChanged, this.headset = false});
  final String label, value;
  final List<String> choices;
  final ValueChanged<String> onChanged;
  final bool headset;
  @override
  State<_Positions> createState() => _PositionsState();
}
class _PositionsState extends State<_Positions> {
  late bool custom = !widget.choices.contains(widget.value);
  late final input = TextEditingController(text: widget.value);
  @override
  void dispose() { input.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    Row(children: [Expanded(child: AppFieldLabel(widget.label)),
      TextButton(onPressed: () => setState(() { custom = !custom; input.text = widget.value; }),
        child: Text(custom ? 'Presets' : 'Custom', style: const TextStyle(fontSize: 12))),
    ]),
    const SizedBox(height: 6),
    if (custom) AppTextField(controller: input, hint: 'Enter position', onChanged: widget.onChanged)
    else LayoutBuilder(builder: (context, constraints) {
      final stacked = constraints.maxWidth < 300 || MediaQuery.textScalerOf(context).scale(13) > 20;
      final cards = [for (final value in widget.choices) _choice(context, value)];
      return stacked ? Column(crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [for (final card in cards) Padding(padding: const EdgeInsets.only(bottom: 8), child: card)])
        : Row(children: [Expanded(child: cards[0]), const SizedBox(width: 8), Expanded(child: cards[1]), const SizedBox(width: 8), Expanded(child: cards[2])]);
    }),
  ]);
  Widget _choice(BuildContext context, String value) {
    final selected = widget.value == value;
    final color = selected ? context.palette.accentInk : context.palette.ink;
    return Semantics(selected: selected, child: FilledButton(
      style: FilledButton.styleFrom(backgroundColor: selected ? context.palette.accent : context.palette.bg,
        foregroundColor: color, padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
      onPressed: () => widget.onChanged(value),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        SizedBox(height: 28, child: widget.headset
          ? Center(child: Transform.rotate(angle: value == 'Slacker' ? -.5 : value == 'Steeper' ? -.1 : -.3,
              child: Container(width: 10, height: 24, decoration: BoxDecoration(border: Border.all(color: color, width: 1.5), borderRadius: BorderRadius.circular(3)))))
          : Icon(value == 'Low' ? CupertinoIcons.arrow_down : value == 'High' ? CupertinoIcons.arrow_up : CupertinoIcons.equal, size: 22, color: color)),
        const SizedBox(height: 10), Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      ])));
  }
}
