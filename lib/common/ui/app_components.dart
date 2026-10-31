import 'package:flutter/cupertino.dart';
import 'app_sheet.dart';
import 'package:flutter/services.dart';
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
  final TextStyle? textStyle;

  const AppActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.outlined = false,
    this.color,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    final child = Text(label, style: textStyle);
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

/// Keeps secondary object actions out of the content hierarchy.
class AppObjectMenu extends StatelessWidget {
  const AppObjectMenu({
    super.key,
    required this.tooltip,
    this.title,
    required this.onRename,
    this.onDiscard,
    this.onDelete,
    this.deleteLabel = 'Delete',
  });

  final String tooltip;
  final String? title;
  final VoidCallback? onRename;
  final VoidCallback? onDiscard;
  final VoidCallback? onDelete;
  final String deleteLabel;

  Future<void> _open(BuildContext context) async {
    final selected = await showAppOptionsSheet(
        context: context,
        title: title ?? tooltip,
        entries: [
          if (onRename != null)
            const AppSheetOption(
                value: 'rename', label: 'Rename', icon: CupertinoIcons.pencil),
          if (onDiscard != null)
            const AppSheetOption(
                value: 'discard',
                label: 'Discard draft',
                icon: CupertinoIcons.trash,
                destructive: true),
          if (onDelete != null)
            AppSheetOption(
                value: 'delete',
                label: deleteLabel,
                icon: CupertinoIcons.trash,
                destructive: true),
        ]);
    if (!context.mounted) return;
    if (selected == 'rename') onRename?.call();
    if (selected == 'discard') onDiscard?.call();
    if (selected == 'delete') onDelete?.call();
  }

  @override
  Widget build(BuildContext context) => IconButton(
        tooltip: tooltip,
        onPressed: onRename == null && onDiscard == null && onDelete == null
            ? null
            : () => _open(context),
        style: IconButton.styleFrom(
          minimumSize: const Size(48, 48),
          foregroundColor: context.palette.inkMuted,
        ).copyWith(splashFactory: NoSplash.splashFactory),
        icon: const Icon(Icons.more_horiz),
      );
}

class AppSheetOption {
  const AppSheetOption(
      {required this.value,
      required this.label,
      this.icon,
      this.destructive = false,
      this.selected = false,
      this.count = 0});
  final String value, label;
  final IconData? icon;
  final bool destructive, selected;
  final int count;
}

/// Compact choices shared by object actions and unit selection.
/// Wait for dismissal before opening an editor or confirmation.
Future<String?> showAppOptionsSheet({
  required BuildContext context,
  required List<AppSheetOption> entries,
  required String title,
}) async {
  ModalRoute<dynamic>? sheetRoute;
  final selected = await showAppSheet<String>(
    context: context,
    builder: (sheetContext) {
      sheetRoute = ModalRoute.of(sheetContext);
      final p = sheetContext.palette;
      return SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const AppSheetHandle(),
              const SizedBox(height: 24),
              Text(title,
                  textAlign: TextAlign.center,
                  style: Theme.of(sheetContext).textTheme.titleLarge),
              const SizedBox(height: 24),
              for (final (index, entry) in entries.indexed) ...[
                TextButton(
                  autofocus: entries.any((item) => item.selected)
                      ? entry.selected
                      : index == 0,
                  onPressed: () => Navigator.pop(sheetContext, entry.value),
                  style: TextButton.styleFrom(
                    alignment: Alignment.centerLeft,
                    minimumSize:
                        Size(double.infinity, entry.icon == null ? 56 : 64),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 14),
                    foregroundColor: p.ink,
                    backgroundColor:
                        entry.selected ? p.surface2 : Colors.transparent,
                    textStyle: AppTextStyles.inter(
                        size: entry.icon == null ? 16 : 17,
                        weight: entry.icon == null
                            ? FontWeight.w500
                            : FontWeight.w600),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Semantics(
                    selected: entry.selected,
                    child: Row(children: [
                      if (entry.icon != null) ...[
                        Icon(entry.icon,
                            size: 25,
                            color: entry.destructive ? p.red : p.accentText),
                        const SizedBox(width: 20),
                      ],
                      Expanded(child: Text(entry.label)),
                      if (entry.count > 0) ...[
                        const SizedBox(width: 12),
                        Text('${entry.count}'),
                      ],
                      if (entry.selected) ...[
                        const SizedBox(width: 12),
                        Icon(Icons.check_rounded,
                            size: 20, color: p.accentText),
                      ],
                    ]),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    },
  );
  await sheetRoute?.completed;
  return selected;
}

/// A quiet, labeled action for editing the adjacent content.
class AppEditButton extends StatelessWidget {
  const AppEditButton({
    super.key,
    this.label = 'Edit',
    required this.onPressed,
    this.tooltip,
  });

  final String label;
  final String? tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final button = TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: context.palette.inkMuted,
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        textStyle: AppTextStyles.inter(
          size: 13,
          weight: FontWeight.w500,
        ),
      ),
      child: Text(label),
    );
    return tooltip == null ? button : Tooltip(message: tooltip!, child: button);
  }
}

class AppTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
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
    required this.hint,
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

/// Shared suggestion row for adding settings and categories.
class AppSuggestionTile extends StatelessWidget {
  const AppSuggestionTile(
      {super.key,
      required this.label,
      required this.onTap,
      this.isNew = false});
  final String label;
  final VoidCallback? onTap;
  final bool isNew;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Material(
          color: context.palette.surface2,
          borderRadius: BorderRadius.circular(14),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
              onTap: onTap,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                child: Row(children: [
                  if (isNew) ...[
                    const Icon(CupertinoIcons.plus, size: 18),
                    const SizedBox(width: 12)
                  ],
                  Expanded(
                      child: Text(label, style: const TextStyle(fontSize: 16))),
                  const SizedBox(width: 12),
                  Icon(CupertinoIcons.chevron_right,
                      size: 16, color: context.palette.inkMuted),
                ]),
              )),
        ),
      );
}
