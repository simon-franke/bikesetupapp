import 'package:animations/animations.dart';
import 'package:flutter/material.dart';

class AppRoutes {
  static Route<T> fadeSlide<T>(Widget page) => PageRouteBuilder<T>(
        transitionDuration: const Duration(milliseconds: 250),
        reverseTransitionDuration: const Duration(milliseconds: 200),
        pageBuilder: (_, __, ___) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          if (MediaQuery.disableAnimationsOf(context)) return child;
          return SharedAxisTransition(
              animation: animation,
              secondaryAnimation: secondaryAnimation,
              transitionType: SharedAxisTransitionType.scaled,
              fillColor: Theme.of(context).scaffoldBackgroundColor,
              child: child);
        },
      );
}
