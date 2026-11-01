import 'package:flutter/material.dart';
import '../theme/theme_data.dart';
import 'app_components.dart';

/// A recoverable loading failure, with a little workshop humour.
class AppLoadError extends StatelessWidget {
  const AppLoadError({super.key, required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      liveRegion: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 12),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ExcludeSemantics(
              child: SizedBox(
                  width: 280,
                  height: 190,
                  child: CustomPaint(
                      painter: _MechanicalPainter(
                          frame: p.inkMuted,
                          backdrop: p.surface,
                          ground: p.borderStrong,
                          wheel: p.accentText)))),
          const SizedBox(height: 20),
          Text('A little roadside trouble.',
              textAlign: TextAlign.center,
              style: AppTextStyles.heading.copyWith(color: p.ink)),
          const SizedBox(height: 10),
          Text(message,
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(color: p.inkMuted)),
          const SizedBox(height: 24),
          AppActionButton(label: 'Try again', onPressed: onRetry),
        ]),
      ),
    );
  }
}

/// An upside-down bike resting on its saddle and bars, ready for a repair.
class _MechanicalPainter extends CustomPainter {
  const _MechanicalPainter(
      {required this.frame,
      required this.ground,
      required this.wheel,
      required this.backdrop});
  final Color frame, ground, wheel, backdrop;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 280, size.height / 190);
    final pen = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final fill = Paint()..color = backdrop;
    // Soft, asymmetric backdrop gives the drawing the scale of a scene.
    canvas.drawPath(
        Path()
          ..moveTo(24, 132)
          ..cubicTo(4, 96, 17, 34, 63, 26)
          ..cubicTo(109, 16, 134, 42, 165, 39)
          ..cubicTo(207, 36, 241, 83, 223, 119)
          ..cubicTo(204, 158, 62, 161, 24, 132)
          ..close(),
        fill);
    pen
      ..color = ground
      ..strokeWidth = 1.5;
    canvas.drawLine(const Offset(24, 151), const Offset(259, 151), pen);

    // Rear tire and fine spokes, above the inverted frame.
    pen
      ..color = ground
      ..strokeWidth = 6;
    canvas.drawCircle(const Offset(55, 64), 31, pen);
    pen
      ..color = frame
      ..strokeWidth = 1.4;
    canvas.drawCircle(const Offset(55, 64), 26, pen);
    for (final point in [
      const Offset(55, 39),
      const Offset(77, 51),
      const Offset(77, 77),
      const Offset(55, 89),
      const Offset(33, 77),
      const Offset(33, 51)
    ]) {
      canvas.drawLine(const Offset(55, 64), point, pen);
    }

    // Rounded frame tubes. The saddle and bar grips rest on the ground.
    pen
      ..color = frame
      ..strokeWidth = 4;
    canvas.drawPath(
        Path()
          ..moveTo(55, 64)
          ..lineTo(91, 121)
          ..lineTo(116, 69)
          ..close(),
        pen);
    canvas.drawPath(
        Path()
          ..moveTo(91, 121)
          ..lineTo(149, 115)
          ..lineTo(116, 69),
        pen);
    canvas.drawLine(const Offset(149, 115), const Offset(170, 65), pen);
    canvas.drawPath(
        Path()
          ..moveTo(170, 65)
          ..lineTo(175, 63),
        pen);
    canvas.drawLine(const Offset(91, 121), const Offset(94, 142), pen);
    fill.color = frame;
    canvas.drawPath(
        Path()
          ..moveTo(80, 145)
          ..quadraticBezierTo(92, 137, 105, 143)
          ..quadraticBezierTo(112, 148, 102, 150)
          ..lineTo(81, 150)
          ..quadraticBezierTo(76, 149, 80, 145)
          ..close(),
        fill);
    canvas.drawPath(
        Path()
          ..moveTo(149, 115)
          ..lineTo(156, 138)
          ..quadraticBezierTo(157, 144, 164, 144)
          ..lineTo(178, 144),
        pen);
    canvas.drawLine(
        const Offset(170, 145), const Offset(180, 145), pen..strokeWidth = 7);
    // A small crank, pedal and rear hub make this a bike rather than a symbol.
    pen
      ..color = ground
      ..strokeWidth = 3;
    canvas.drawCircle(const Offset(116, 69), 9, pen);
    pen
      ..color = frame
      ..strokeWidth = 2.5;
    canvas.drawCircle(const Offset(116, 69), 4, pen);
    canvas.drawPath(
        Path()
          ..moveTo(116, 69)
          ..lineTo(129, 57)
          ..lineTo(137, 57),
        pen);
    canvas.drawCircle(const Offset(55, 64), 3, pen);

    // Loose front wheel, propped beside the bike. Orange stays concentrated here.
    canvas.save();
    canvas.translate(223, 113);
    canvas.rotate(.18);
    pen
      ..color = wheel
      ..strokeWidth = 5;
    canvas.drawOval(const Rect.fromLTWH(-27, -35, 54, 70), pen);
    pen
      ..color = ground
      ..strokeWidth = 1.5;
    canvas.drawOval(const Rect.fromLTWH(-22, -30, 44, 60), pen);
    for (final point in [
      const Offset(0, -29),
      const Offset(19, -14),
      const Offset(19, 14),
      const Offset(0, 29),
      const Offset(-19, 14),
      const Offset(-19, -14)
    ]) {
      canvas.drawLine(Offset.zero, point, pen);
    }
    canvas.drawCircle(
        Offset.zero,
        4,
        pen
          ..color = wheel
          ..strokeWidth = 2.5);
    canvas.restore();

    // Two tools set on the ground, with enough space to read at phone size.
    canvas.save();
    canvas.translate(118, 169);
    canvas.rotate(-.13);
    pen
      ..color = frame
      ..strokeWidth = 2.5;
    canvas.drawPath(
        Path()
          ..moveTo(-15, -3)
          ..lineTo(5, -3)
          ..quadraticBezierTo(8, -10, 16, -7)
          ..lineTo(11, -2)
          ..lineTo(16, 3)
          ..quadraticBezierTo(8, 7, 5, 1)
          ..lineTo(-15, 1)
          ..quadraticBezierTo(-18, -1, -15, -3),
        pen);
    canvas.restore();
    pen
      ..color = ground
      ..strokeWidth = 3;
    canvas.drawPath(
        Path()
          ..moveTo(155, 170)
          ..lineTo(172, 170)
          ..quadraticBezierTo(176, 170, 176, 166)
          ..lineTo(176, 161),
        pen);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_MechanicalPainter oldDelegate) =>
      frame != oldDelegate.frame ||
      ground != oldDelegate.ground ||
      wheel != oldDelegate.wheel ||
      backdrop != oldDelegate.backdrop;
}
