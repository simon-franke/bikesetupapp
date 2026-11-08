import 'app_haptics.dart';
import 'app_loading.dart';
import 'package:flutter/cupertino.dart';
import 'package:bikesetupapp/common/theme/theme_data.dart';
import 'package:flutter/material.dart';

/// App-specific compositions of Material controls. Visual defaults live in
/// AppTheme so focus, disabled states, sizing and semantics stay consistent.
class AppActionButton extends StatelessWidget {
  final String label;
  final bool isLoading;
  final String loadingLabel;
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
    this.isLoading = false,
    this.loadingLabel = 'Saving…',
    this.icon,
    this.outlined = false,
    this.destructive = false,
    this.color,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    final action = isLoading ? null : onPressed;
    final child = isLoading
        ? AppLoadingContent(label: loadingLabel)
        : Text(label, style: textStyle);
    if (outlined) {
      return icon == null || isLoading
          ? OutlinedButton(
              onPressed: AppHaptics.wrap(action),
              style: isLoading
                  ? OutlinedButton.styleFrom(
                      disabledForegroundColor: context.palette.ink)
                  : null,
              child: child)
          : OutlinedButton.icon(
              onPressed: AppHaptics.wrap(action),
              icon: Icon(icon),
              label: child);
    }

    final content = icon == null || isLoading
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
        onPressed: AppHaptics.wrap(action),
        style: TextButton.styleFrom(
          foregroundColor: context.palette.red,
          disabledForegroundColor: isLoading ? context.palette.ink : null,
          backgroundColor: context.palette.red.withValues(alpha: .10),
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: content,
      );
    }

    return AppTactileButton(
        onPressed: onPressed,
        color: color,
        isLoading: isLoading,
        loadingLabel: loadingLabel,
        child: content);
  }
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

/// A button face that depresses onto a solid base while retaining native
/// keyboard, focus, cancellation, and disabled-button behavior.
class AppTactileButton extends StatefulWidget {
  const AppTactileButton(
      {super.key,
      required this.onPressed,
      required this.child,
      this.tooltip,
      this.color,
      this.isLoading = false,
      this.loadingLabel = 'Saving…',
      this.compact = false});

  final VoidCallback? onPressed;
  final Widget child;
  final String? tooltip;
  final Color? color;
  final bool compact;
  final bool isLoading;
  final String loadingLabel;

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
    if (_activating || widget.isLoading || widget.onPressed == null) return;
    final action = widget.onPressed!;
    setState(() => _activating = true);
    AppHaptics.action();
    // Keep a quick tap visibly depressed before navigation or a save replaces it.
    await Future<void>.delayed(const Duration(milliseconds: 100));
    if (!mounted) return;
    setState(() => _activating = false);
    if (widget.onPressed != null && !widget.isLoading) action();
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
    final enabled = widget.onPressed != null && !widget.isLoading;
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
              disabledForegroundColor: widget.isLoading ? p.ink : p.inkDim,
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
            child: widget.isLoading
                ? AppLoadingContent(label: widget.loadingLabel)
                : widget.child,
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
