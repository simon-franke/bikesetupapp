import 'app_error_banner.dart';
import 'package:flutter/services.dart';
import 'package:bikesetupapp/common/theme/theme_data.dart';
import 'package:flutter/material.dart';

import 'app_buttons.dart';

class AppTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool enabled;
  final bool obscureText;
  final bool autocorrect;
  final Iterable<String>? autofillHints;
  final String? errorText;
  final String? suffix;
  final Widget? suffixWidget;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool autofocus;
  final int? maxLines;

  const AppTextField({
    super.key,
    required this.controller,
    this.hint = '',
    this.enabled = true,
    this.obscureText = false,
    this.autocorrect = true,
    this.autofillHints,
    this.errorText,
    this.suffix,
    this.suffixWidget,
    this.keyboardType,
    this.inputFormatters,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
    this.autofocus = false,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final invalid = errorText != null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: controller,
          enabled: enabled,
          obscureText: obscureText,
          autocorrect: autocorrect,
          autofillHints: autofillHints,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          textInputAction: textInputAction,
          onChanged: onChanged,
          onSubmitted: onSubmitted,
          autofocus: autofocus,
          maxLines: maxLines,
          style: theme.textTheme.bodyLarge,
          cursorColor: context.palette.accentText,
          decoration: InputDecoration(
              hintText: hint,
              enabledBorder:
                  invalid ? theme.inputDecorationTheme.errorBorder : null,
              focusedBorder: invalid
                  ? theme.inputDecorationTheme.focusedErrorBorder
                  : null,
              suffixText: suffix,
              suffixIcon: suffixWidget),
        ),
        if (invalid) ...[
          const SizedBox(height: 8),
          Semantics(
              liveRegion: true,
              child: Text(errorText!,
                  style: theme.inputDecorationTheme.errorStyle)),
        ],
      ],
    );
  }
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

/// A visible field label and its control, with consistent spacing and semantics.
class AppFormField extends StatelessWidget {
  const AppFormField({super.key, required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          ExcludeSemantics(child: AppFieldLabel(label)),
          const SizedBox(height: 8),
          Semantics(label: label, child: child),
        ],
      );
}

/// Shared submission feedback; the caller owns saving, retries, and dismissal.
class AppFormFooter extends StatelessWidget {
  const AppFormFooter({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.loadingLabel = 'Saving…',
    this.error,
    this.destructive = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final String loadingLabel;
  final String? error;
  final bool destructive;

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (error != null) ...[
            AppErrorBanner(message: error!),
            const SizedBox(height: 16),
          ],
          AppActionButton(
            label: label,
            onPressed: onPressed,
            isLoading: isLoading,
            loadingLabel: loadingLabel,
            destructive: destructive,
          ),
        ],
      );
}
