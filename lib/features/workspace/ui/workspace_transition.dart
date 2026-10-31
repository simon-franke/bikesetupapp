import 'package:flutter/material.dart';

/// Retains visited tabs so switching back preserves data and scroll position.
class WorkspaceTransition extends StatelessWidget {
  const WorkspaceTransition({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => _RetainedPages(child: child);
}

class _RetainedPages extends StatefulWidget {
  const _RetainedPages({required this.child});
  final Widget child;
  @override
  State<_RetainedPages> createState() => _WorkspaceTransitionState();
}

class _WorkspaceTransitionState extends State<_RetainedPages> {
  final _pages = <Key, Widget>{};
  Key get _active => widget.child.key ?? ValueKey(widget.child.runtimeType);
  late Key? _visible = _active;

  @override
  void didUpdateWidget(_RetainedPages oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldKey = oldWidget.child.key ?? ValueKey(oldWidget.child.runtimeType);
    if (oldKey != _active) {
      _visible = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _visible = _active);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final active = _active;
    _pages[active] = widget.child;
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 220);
    return Stack(fit: StackFit.expand, children: [
      for (final entry in _pages.entries)
        Positioned.fill(
          key: ValueKey(('retained-page', entry.key)),
          child: IgnorePointer(
            ignoring: entry.key != active,
            child: ExcludeSemantics(
              excluding: entry.key != active,
              child: AnimatedOpacity(
                opacity: entry.key == _visible ? 1 : 0,
                duration: duration,
                curve: Curves.easeInOut,
                child: TickerMode(
                    enabled: entry.key == active, child: entry.value),
              ),
            ),
          ),
        ),
    ]);
  }
}
