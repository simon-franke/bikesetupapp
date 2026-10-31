import 'package:flutter/material.dart';

class AppRoutes {
  static Route<T> fadeSlide<T>(Widget page) => PageRouteBuilder<T>(
        transitionDuration: const Duration(milliseconds: 300),
        reverseTransitionDuration: const Duration(milliseconds: 260),
        pageBuilder: (_, __, ___) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          if (MediaQuery.disableAnimationsOf(context)) return child;
          final eased =
              animation.drive(CurveTween(curve: Curves.easeInOutCubic));
          return SlideTransition(
              position: eased
                  .drive(Tween(begin: const Offset(1, 0), end: Offset.zero)),
              child: child);
        },
      );
}
