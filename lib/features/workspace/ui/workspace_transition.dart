import 'package:animations/animations.dart';
import 'package:flutter/material.dart';

/// Tab pages occupy the same viewport even while a short page loads its data.
class WorkspaceTransition extends StatelessWidget {
  const WorkspaceTransition({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => PageTransitionSwitcher(
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 180),
        layoutBuilder: (children) => Stack(
            fit: StackFit.expand,
            alignment: Alignment.topLeft,
            children: children),
        transitionBuilder: (child, animation, secondaryAnimation) {
          if (MediaQuery.disableAnimationsOf(context)) return child;
          // Crossfade without scaling a full screen around its centre.
          return FadeTransition(
              opacity: animation.drive(CurveTween(curve: Curves.easeOut)),
              child: FadeTransition(
                  opacity:
                      secondaryAnimation.drive(Tween<double>(begin: 1, end: 0)),
                  child: child));
        },
        child: child,
      );
}
