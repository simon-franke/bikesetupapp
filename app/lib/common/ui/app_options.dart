import 'app_haptics.dart';
import 'package:flutter/cupertino.dart';
import 'app_sheet.dart';
import 'package:bikesetupapp/common/theme/theme_data.dart';
import 'package:flutter/material.dart';

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
            : AppHaptics.wrap(() => _open(context)),
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
              AppSheetHeader(title: title),
              for (final (index, entry) in entries.indexed) ...[
                if (index > 0) const SizedBox(height: 8),
                AppSelectionSurface(
                  selected: entry.selected,
                  child: TextButton(
                    autofocus: entries.any((item) => item.selected)
                        ? entry.selected
                        : index == 0,
                    onPressed: () {
                      if (!entry.selected) AppHaptics.selection();
                      Navigator.pop(sheetContext, entry.value);
                    },
                    style: TextButton.styleFrom(
                      alignment: Alignment.centerLeft,
                      minimumSize:
                          Size(double.infinity, entry.icon == null ? 56 : 64),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 14),
                      foregroundColor: entry.destructive ? p.red : p.ink,
                      backgroundColor: entry.destructive
                          ? p.red.withValues(alpha: .10)
                          : Colors.transparent,
                      textStyle: AppTextStyles.label,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Semantics(
                      selected: entry.selected,
                      child: Row(children: [
                        if (entry.icon != null) ...[
                          Icon(entry.icon,
                              size: AppIconSizes.control,
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
                              size: AppIconSizes.control, color: p.accentText),
                        ],
                      ]),
                    ),
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

/// A quiet, flat selection highlight shared by option controls.
class AppSelectionSurface extends StatelessWidget {
  const AppSelectionSurface(
      {super.key, required this.selected, required this.child});

  final bool selected;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: selected ? p.surface2 : Colors.transparent,
      ),
      child: child,
    );
  }
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
              onTap: AppHaptics.wrap(onTap, selection: true),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                child: Row(children: [
                  if (isNew) ...[
                    const Icon(CupertinoIcons.plus, size: AppIconSizes.compact),
                    const SizedBox(width: 12)
                  ],
                  Expanded(child: Text(label, style: AppTextStyles.body)),
                  const SizedBox(width: 12),
                  Icon(CupertinoIcons.chevron_right,
                      size: AppIconSizes.compact,
                      color: context.palette.inkMuted),
                ]),
              )),
        ),
      );
}
