import 'package:flutter/material.dart';

/// Softens content passing beneath a fixed header without taking space.
class AppScrollEdge extends StatefulWidget {
  const AppScrollEdge({super.key, required this.child});
  final Widget child;

  @override
  State<AppScrollEdge> createState() => _AppScrollEdgeState();
}

class _AppScrollEdgeState extends State<AppScrollEdge> {
  final amount = ValueNotifier<double>(0);

  void update(ScrollMetrics metrics, int depth) {
    if (depth == 0 && metrics.axis == Axis.vertical) {
      amount.value = (metrics.extentBefore / 24).clamp(0, 1);
    }
  }

  @override
  void dispose() {
    amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      NotificationListener<ScrollMetricsNotification>(
        onNotification: (notification) {
          update(notification.metrics, notification.depth);
          return false;
        },
        child: NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            update(notification.metrics, notification.depth);
            return false;
          },
          child: ValueListenableBuilder<double>(
            valueListenable: amount,
            child: widget.child,
            builder: (context, value, child) => ShaderMask(
              blendMode: BlendMode.dstIn,
              shaderCallback: (bounds) => LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withValues(alpha: 1 - value),
                  Colors.white.withValues(alpha: 1 - value),
                  Colors.white,
                ],
                stops: const [0, 0.12, 1],
              ).createShader(Rect.fromLTWH(0, 0, bounds.width, 32)),
              child: child,
            ),
          ),
        ),
      );
}
