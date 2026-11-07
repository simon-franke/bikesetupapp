import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/theme_data.dart';

/// The Clickwise adjuster, advancing one detent at a time. No progress is implied.
class AppLoadingIndicator extends StatefulWidget {
  const AppLoadingIndicator({super.key, this.size = 32});

  final double size;

  @override
  State<AppLoadingIndicator> createState() => _AppLoadingIndicatorState();
}

class _AppLoadingIndicatorState extends State<AppLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late final _rotation = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 5760));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context) ||
        !TickerMode.valuesOf(context).enabled) {
      _rotation.stop();
    } else if (!_rotation.isAnimating) {
      _rotation.repeat();
    }
  }

  @override
  void dispose() {
    _rotation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: RepaintBoundary(
          child: SizedBox.square(
            dimension: widget.size,
            child: CustomPaint(
              painter: _KnobPainter(
                  _rotation, context.palette.accent, context.palette.bg),
            ),
          ),
        ),
      );
}

/// Reusable page/section loading state. Keep existing content for small writes;
/// use the compact indicator in the initiating button instead.
class AppLoadingState extends StatelessWidget {
  const AppLoadingState({super.key, this.label = 'Loading…'});

  final String label;

  @override
  Widget build(BuildContext context) => Semantics(
        liveRegion: true,
        label: label,
        child: ExcludeSemantics(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const AppLoadingIndicator(size: 64),
            const SizedBox(height: 16),
            Text(label,
                style: AppTextStyles.body
                    .copyWith(color: context.palette.inkMuted)),
          ]),
        ),
      );
}

/// Compact, announced progress for buttons and inline operations.
class AppLoadingContent extends StatelessWidget {
  const AppLoadingContent({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Semantics(
        liveRegion: true,
        label: label,
        child: ExcludeSemantics(
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const SizedBox(
                width: 28,
                height: 20,
                child: OverflowBox(
                    maxHeight: 28, child: AppLoadingIndicator(size: 28))),
            const SizedBox(width: 10),
            Flexible(child: Text(label)),
          ]),
        ),
      );
}

class _KnobPainter extends CustomPainter {
  _KnobPainter(this.rotation, this.face, this.socket)
      : super(repaint: rotation);

  final Animation<double> rotation;
  final Color face, socket;

  @override
  void paint(Canvas canvas, Size size) {
    // 12 clicks per revolution: 160ms movement, then a 320ms dwell.
    final clicks = rotation.value * 12;
    final fraction = clicks - clicks.floor();
    final advance =
        Curves.easeOutCubic.transform((fraction * 3).clamp(0.0, 1.0));
    final angle = (clicks.floor() + advance) * math.pi / 6;
    final unit = size.shortestSide;
    final center = Offset(size.width / 2, size.height * .46);
    Offset point(double radius, double theta) =>
        center +
        Offset(math.cos(theta) * radius * unit,
            math.sin(theta) * radius * unit * .9);
    final outline = Path();

    for (var i = 0; i <= 180; i++) {
      final theta = i * math.pi * 2 / 180;
      final radius = .405 + .045 * math.cos(6 * (theta - angle + math.pi / 2));
      final p = point(radius, theta);
      if (i == 0) {
        outline.moveTo(p.dx, p.dy);
      } else {
        outline.lineTo(p.dx, p.dy);
      }
    }

    outline.close();
    // The face rotates; the extrusion and light stay in screen space.
    final depth = unit * .07;

    for (var y = depth; y >= 0; y -= math.max(1.0, unit / 64)) {
      canvas.drawPath(outline.shift(Offset(0, y)),
          Paint()..color = Color.lerp(face, Colors.black, .35)!);
    }

    canvas.drawPath(
        outline,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color.lerp(face, Colors.white, .18)!, face],
          ).createShader(Offset.zero & size));
    final hole = Path();

    for (var i = 0; i < 6; i++) {
      final p = point(.135, angle - math.pi / 2 + i * math.pi / 3);
      if (i == 0) {
        hole.moveTo(p.dx, p.dy);
      } else {
        hole.lineTo(p.dx, p.dy);
      }
    }

    hole.close();
    canvas.drawPath(hole, Paint()..color = socket);
    canvas.drawLine(
        point(.235, angle - math.pi / 2),
        point(.345, angle - math.pi / 2),
        Paint()
          ..color = Colors.white
          ..strokeWidth = unit * .055
          ..strokeCap = StrokeCap.round);
  }

  @override
  bool shouldRepaint(_KnobPainter oldDelegate) =>
      oldDelegate.rotation != rotation ||
      oldDelegate.face != face ||
      oldDelegate.socket != socket;
}
