import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AppRoutes {
  static Route<T> fadeSlide<T>(Widget page) => _AppPageRoute<T>(page);
}

class _AppPageRoute<T> extends MaterialPageRoute<T> {
  _AppPageRoute(Widget page) : super(builder: (_) => page);

  @override
  Duration get transitionDuration => const Duration(milliseconds: 300);

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 260);

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation, Widget child) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    if (Theme.of(context).platform == TargetPlatform.iOS) {
      // Keep Flutter's edge gesture, including cancellation and pop guards.
      // With reduced motion, only an active drag moves the page.
      return CupertinoRouteTransitionMixin.buildPageTransitions<T>(
        this,
        context,
        reduced && !popGestureInProgress
            ? const AlwaysStoppedAnimation<double>(1)
            : animation,
        reduced && !popGestureInProgress
            ? const AlwaysStoppedAnimation<double>(0)
            : secondaryAnimation,
        child,
      );
    }
    if (reduced) return child;
    final eased = animation.drive(CurveTween(curve: Curves.easeInOutCubic));
    return SlideTransition(
        position:
            eased.drive(Tween(begin: const Offset(1, 0), end: Offset.zero)),
        child: child);
  }
}
