import 'package:flutter/material.dart';

/// Shared timing for navigation, sheets and replacement screens.
abstract final class AppMotion {
  static const forward = Duration(milliseconds: 280);
  static const reverse = Duration(milliseconds: 220);
  static const replacement = Duration(milliseconds: 220);
  static const curve = Curves.easeInOutCubic;
}

/// Use for mutually exclusive screen states, not navigation history.
/// Give each state a stable key. Outgoing content cannot receive input or focus.
class AppScreenTransition extends StatelessWidget {
  const AppScreenTransition({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    return ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: AnimatedSwitcher(
        duration: AppMotion.replacement,
        // Clear the old content before revealing the new layout, so unrelated
        // forms and cards do not overlap midway through the transition.
        switchInCurve: const Interval(.35, 1, curve: Curves.easeOutCubic),
        switchOutCurve: const Interval(.65, 1, curve: Curves.easeInCubic),
        layoutBuilder: (current, previous) => Stack(
          fit: StackFit.expand,
          children: [
            for (final page in [...previous, if (current != null) current])
              ExcludeFocus(
                  key: page.key,
                  excluding: page != current,
                  child: ExcludeSemantics(
                      excluding: page != current,
                      child: IgnorePointer(
                          ignoring: page != current, child: page))),
          ],
        ),
        child: child,
      ),
    );
  }
}
