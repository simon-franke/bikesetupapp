import 'package:bikesetupapp/common/theme/theme_data.dart';
import 'package:flutter/material.dart';

/// App-specific compositions of Material controls. Visual defaults live in
/// AppTheme so focus, disabled states, sizing and semantics stay consistent.
class AppActionButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool outlined;
  final Color? color;

  const AppActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.outlined = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final child = Text(label);
    if (outlined) {
      return icon == null
          ? OutlinedButton(onPressed: onPressed, child: child)
          : OutlinedButton.icon(
              onPressed: onPressed, icon: Icon(icon), label: child);
    }
    final style = color == null
        ? null
        : FilledButton.styleFrom(
            backgroundColor: color,
            foregroundColor: AppColors.onColor(color!),
          );
    return icon == null
        ? FilledButton(onPressed: onPressed, style: style, child: child)
        : FilledButton.icon(
            onPressed: onPressed, style: style, icon: Icon(icon), label: child);
  }
}

class AppTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final String? errorText;
  final String? suffix;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool autofocus;
  final int? maxLines;

  const AppTextField({
    super.key,
    required this.controller,
    required this.hint,
    this.errorText,
    this.suffix,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
    this.autofocus = false,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) => TextField(
        controller: controller,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        autofocus: autofocus,
        maxLines: maxLines,
        style: Theme.of(context).textTheme.bodyLarge,
        cursorColor: context.palette.accentText,
        decoration: InputDecoration(
            hintText: hint, errorText: errorText, suffixText: suffix),
      );
}

class AppFieldLabel extends StatelessWidget {
  final String label;
  const AppFieldLabel(this.label, {super.key});

  @override
  Widget build(BuildContext context) => Text(
        label,
        style: Theme.of(context).textTheme.titleSmall,
      );
}

class AppSectionLabel extends StatelessWidget {
  final String label;
  const AppSectionLabel(this.label, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Text(label, style: Theme.of(context).textTheme.titleMedium),
      );
}

/// Titles and actions share a baseline and wrap together in narrow panes.
class AppSectionToolbar extends StatelessWidget {
  final Widget title;
  final Widget? action;
  const AppSectionToolbar({super.key, required this.title, this.action});

  @override
  Widget build(BuildContext context) =>
      LayoutBuilder(builder: (context, constraints) {
        if (action == null) return title;
        if (constraints.maxWidth < 420 ||
            MediaQuery.textScalerOf(context).scale(14) > 22) {
          return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [title, const SizedBox(height: 8), action!]);
        }
        return Row(children: [
          Expanded(child: title),
          const SizedBox(width: 16),
          action!
        ]);
      });
}
