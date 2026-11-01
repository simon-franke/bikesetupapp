import 'app_haptics.dart';
import 'package:flutter/cupertino.dart';
import 'app_sheet.dart';
import 'package:flutter/services.dart';
import 'package:bikesetupapp/common/theme/theme_data.dart';
import 'package:flutter/material.dart';

/// A compact detail header with room for long titles and larger system text.
AppBar buildDetailAppBar(
  BuildContext context, {
  required String title,
  List<Widget> actions = const [],
}) {
  final style = AppTextStyles.heading.copyWith(
    color: context.palette.ink,
    fontFamily: Theme.of(context).textTheme.titleLarge?.fontFamily,
  );
  // Match the toolbar's leading space, title gaps, and 48px action targets.
  final titleWidth =
      (MediaQuery.sizeOf(context).width - 68 - 16 - 20 - actions.length * 48)
          .clamp(1.0, double.infinity);
  final painter = TextPainter(
    text: TextSpan(text: title, style: style),
    textDirection: Directionality.of(context),
    textScaler: MediaQuery.textScalerOf(context),
  )..layout(maxWidth: titleWidth);
  final height = (painter.height + 24).clamp(64.0, double.infinity);
  painter.dispose();
  return AppBar(
    automaticallyImplyLeading: false,
    centerTitle: false,
    toolbarHeight: height,
    leadingWidth: 68,
    leading: Padding(
      padding: const EdgeInsets.only(left: 20),
      child: Builder(
          builder: (routeContext) => IconButton(
                tooltip:
                    MaterialLocalizations.of(routeContext).backButtonTooltip,
                icon: const Icon(CupertinoIcons.chevron_left,
                    size: AppIconSizes.compact),
                onPressed: AppHaptics.wrap(
                    () => Navigator.of(routeContext).maybePop()),
              )),
    ),
    titleSpacing: 8,
    title: Text(title,
        style: style,
        textScaler: MediaQuery.textScalerOf(context),
        softWrap: true,
        overflow: TextOverflow.visible),
    actionsPadding: const EdgeInsets.only(right: 20),
    actions:
        actions.map((action) => SizedBox(width: 48, child: action)).toList(),
  );
}

/// App-specific compositions of Material controls. Visual defaults live in
/// AppTheme so focus, disabled states, sizing and semantics stay consistent.
class AppActionButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool outlined;
  final bool destructive;
  final Color? color;
  final TextStyle? textStyle;

  const AppActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.outlined = false,
    this.destructive = false,
    this.color,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    final child = Text(label, style: textStyle);
    if (outlined) {
      return icon == null
          ? OutlinedButton(onPressed: AppHaptics.wrap(onPressed), child: child)
          : OutlinedButton.icon(
              onPressed: AppHaptics.wrap(onPressed),
              icon: Icon(icon),
              label: child);
    }
    final content = icon == null
        ? child
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: AppIconSizes.control),
              const SizedBox(width: 8),
              Flexible(child: child)
            ],
          );
    if (destructive || color == context.palette.red) {
      return TextButton(
        onPressed: AppHaptics.wrap(onPressed),
        style: TextButton.styleFrom(
          foregroundColor: context.palette.red,
          backgroundColor: context.palette.red.withValues(alpha: .10),
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: content,
      );
    }
    return AppTactileButton(onPressed: onPressed, color: color, child: content);
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
              const AppSheetHandle(),
              const SizedBox(height: 24),
              Text(title,
                  textAlign: TextAlign.center,
                  style: Theme.of(sheetContext).textTheme.titleLarge),
              const SizedBox(height: 24),
              for (final (index, entry) in entries.indexed) ...[
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
      onPressed: AppHaptics.wrap(onPressed),
      style: TextButton.styleFrom(
        foregroundColor: context.palette.inkMuted,
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        textStyle: AppTextStyles.label,
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

/// A button face that depresses onto a solid base while retaining native
/// keyboard, focus, cancellation, and disabled-button behavior.
class AppTactileButton extends StatefulWidget {
  const AppTactileButton(
      {super.key,
      required this.onPressed,
      required this.child,
      this.tooltip,
      this.color,
      this.compact = false});
  final VoidCallback? onPressed;
  final Widget child;
  final String? tooltip;
  final Color? color;
  final bool compact;

  @override
  State<AppTactileButton> createState() => _AppTactileButtonState();
}

class _AppTactileButtonState extends State<AppTactileButton> {
  final _states = WidgetStatesController();
  bool _activating = false;

  @override
  void initState() {
    super.initState();
    _states.addListener(_update);
  }

  void _update() {
    // ButtonStyleButton can update disabled/focus states during its own build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  Future<void> _activate() async {
    if (_activating || widget.onPressed == null) return;
    final action = widget.onPressed!;
    setState(() => _activating = true);
    AppHaptics.action();
    // Keep a quick tap visibly depressed before navigation or a save replaces it.
    await Future<void>.delayed(const Duration(milliseconds: 100));
    if (!mounted) return;
    setState(() => _activating = false);
    if (widget.onPressed != null) action();
  }

  @override
  void dispose() {
    _states.removeListener(_update);
    _states.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final face = widget.color ?? p.accent;
    final ink = widget.color == null ? p.accentInk : AppColors.onColor(face);
    final enabled = widget.onPressed != null;
    final pressed =
        _activating || (enabled && _states.value.contains(WidgetState.pressed));
    final radius = BorderRadius.circular(10);
    final button = Stack(fit: StackFit.passthrough, children: [
      Positioned.fill(
        top: 6,
        child: DecoratedBox(
            decoration: BoxDecoration(
          color: enabled ? Color.lerp(face, Colors.black, .4) : p.surface2,
          borderRadius: radius,
        )),
      ),
      Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: AnimatedContainer(
          duration: pressed || MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 120),
          transform: Matrix4.translationValues(0, pressed ? 6 : 0, 0),
          child: ElevatedButton(
            statesController: _states,
            onPressed: enabled ? _activate : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: face,
              foregroundColor: ink,
              disabledBackgroundColor: p.surface2,
              disabledForegroundColor: p.inkDim,
              minimumSize: const Size(48, 48),
              padding: widget.compact
                  ? EdgeInsets.zero
                  : const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: radius),
            ).copyWith(
              elevation: const WidgetStatePropertyAll(0),
              overlayColor: WidgetStateProperty.resolveWith((states) =>
                  states.contains(WidgetState.pressed)
                      ? Colors.transparent
                      : null),
              splashFactory: NoSplash.splashFactory,
            ),
            child: widget.child,
          ),
        ),
      ),
    ]);
    return widget.tooltip == null
        ? button
        : Tooltip(
            message: widget.tooltip!,
            child: Semantics(label: widget.tooltip, child: button),
          );
  }
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

/// A consistent, quiet entry point below a list; confirmation stays in the form.
class AppAddButton extends StatelessWidget {
  const AppAddButton(
      {super.key, required this.label, required this.onPressed, this.tooltip});
  final String label;
  final VoidCallback? onPressed;
  final String? tooltip;
  @override
  Widget build(BuildContext context) {
    final button = Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: AppHaptics.wrap(onPressed),
        style: TextButton.styleFrom(
          foregroundColor: context.palette.accentText,
          textStyle: AppTextStyles.label,
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 12),
        ),
        icon: const Icon(CupertinoIcons.plus, size: AppIconSizes.compact),
        label: Text(label),
      ),
    );
    return tooltip == null ? button : Tooltip(message: tooltip!, child: button);
  }
}
