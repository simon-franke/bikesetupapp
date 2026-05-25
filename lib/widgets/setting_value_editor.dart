import 'dart:math' as math;

import 'package:bikesetupapp/app_services/theme_data.dart';
import 'package:bikesetupapp/widgets/field_meta.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const double _tickWidth = 12;
const double _rulerHeight = 70;

class SettingValueEditor extends StatefulWidget {
  final int initialValue;
  final FieldMeta meta;
  final ValueChanged<int> onChanged;

  const SettingValueEditor({
    super.key,
    required this.initialValue,
    required this.meta,
    required this.onChanged,
  });

  @override
  State<SettingValueEditor> createState() => _SettingValueEditorState();
}

class _SettingValueEditorState extends State<SettingValueEditor> {
  late final ScrollController _controller;
  late int _effectiveMin;
  late int _effectiveMax;
  late int _currentValue;

  @override
  void initState() {
    super.initState();
    _effectiveMin = math.min(widget.meta.min, widget.initialValue);
    _effectiveMax = math.max(widget.meta.max, widget.initialValue);
    _currentValue = widget.initialValue;
    _controller = ScrollController(
      initialScrollOffset: (widget.initialValue - _effectiveMin) * _tickWidth,
    );
    _controller.addListener(_onScroll);
  }

  @override
  void dispose() {
    _controller.removeListener(_onScroll);
    _controller.dispose();
    super.dispose();
  }

  void _onScroll() {
    final maxOffset = (_effectiveMax - _effectiveMin) * _tickWidth;
    final clamped = _controller.offset.clamp(0.0, maxOffset);
    final index = (clamped / _tickWidth).round();
    final newValue = _effectiveMin + index;
    if (newValue != _currentValue) {
      final wasAtBoundary =
          _currentValue == _effectiveMin || _currentValue == _effectiveMax;
      final isAtBoundary =
          newValue == _effectiveMin || newValue == _effectiveMax;
      if (isAtBoundary && !wasAtBoundary) {
        HapticFeedback.mediumImpact();
      } else {
        HapticFeedback.selectionClick();
      }
      setState(() => _currentValue = newValue);
      widget.onChanged(newValue);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final tickCount = _effectiveMax - _effectiveMin + 1;
    final contentWidth = (tickCount - 1) * _tickWidth;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$_currentValue',
          style: AppTextStyles.mono(
            size: 64,
            weight: FontWeight.w700,
            color: p.ink,
            letterSpacing: -3,
            height: 1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          widget.meta.unit,
          style: AppTextStyles.inter(
            size: 12,
            weight: FontWeight.w600,
            color: p.inkMuted,
          ),
        ),
        const SizedBox(height: 18),
        SizedBox(
          height: _rulerHeight,
          child: LayoutBuilder(
            builder: (ctx, constraints) {
              final halfViewport = constraints.maxWidth / 2;
              return Stack(
                alignment: Alignment.center,
                children: [
                  SingleChildScrollView(
                    controller: _controller,
                    scrollDirection: Axis.horizontal,
                    physics: const _SnapScrollPhysics(itemWidth: _tickWidth),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: halfViewport),
                      child: SizedBox(
                        width: contentWidth,
                        height: _rulerHeight,
                        child: CustomPaint(
                          painter: _RulerPainter(
                            tickCount: tickCount,
                            minValue: _effectiveMin,
                            tickWidth: _tickWidth,
                            tickColor: p.borderStrong,
                            labelColor: p.inkMuted,
                          ),
                        ),
                      ),
                    ),
                  ),
                  IgnorePointer(
                    child: _CenterPointer(color: p.accent),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _CenterPointer extends StatelessWidget {
  final Color color;
  const _CenterPointer({required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 14,
      height: _rulerHeight,
      child: CustomPaint(painter: _PointerPainter(color: color)),
    );
  }
}

class _PointerPainter extends CustomPainter {
  final Color color;
  const _PointerPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final cx = size.width / 2;
    final tri = Path()
      ..moveTo(cx - 5, 0)
      ..lineTo(cx + 5, 0)
      ..lineTo(cx, 7)
      ..close();
    canvas.drawPath(tri, paint);
    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 2;
    canvas.drawLine(Offset(cx, 6), Offset(cx, size.height - 18), linePaint);
  }

  @override
  bool shouldRepaint(_PointerPainter old) => old.color != color;
}

class _RulerPainter extends CustomPainter {
  final int tickCount;
  final int minValue;
  final double tickWidth;
  final Color tickColor;
  final Color labelColor;

  const _RulerPainter({
    required this.tickCount,
    required this.minValue,
    required this.tickWidth,
    required this.tickColor,
    required this.labelColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = tickColor
      ..strokeWidth = 1;
    final topY = 8.0;
    for (int i = 0; i < tickCount; i++) {
      final x = i * tickWidth;
      final value = minValue + i;
      final isMajor = value % 10 == 0;
      final isMid = value % 5 == 0;
      final tickHeight = isMajor ? 20.0 : (isMid ? 14.0 : 9.0);
      canvas.drawLine(
        Offset(x, topY),
        Offset(x, topY + tickHeight),
        paint,
      );
      if (isMajor) {
        final tp = TextPainter(
          text: TextSpan(
            text: '$value',
            style: TextStyle(
              color: labelColor,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(x - tp.width / 2, topY + tickHeight + 4));
      }
    }
  }

  @override
  bool shouldRepaint(_RulerPainter old) =>
      old.tickCount != tickCount ||
      old.minValue != minValue ||
      old.tickWidth != tickWidth ||
      old.tickColor != tickColor ||
      old.labelColor != labelColor;
}

class _SnapScrollPhysics extends ScrollPhysics {
  final double itemWidth;
  const _SnapScrollPhysics({required this.itemWidth, super.parent});

  @override
  _SnapScrollPhysics applyTo(ScrollPhysics? ancestor) =>
      _SnapScrollPhysics(itemWidth: itemWidth, parent: buildParent(ancestor));

  double _targetPixels(ScrollMetrics position, double velocity) {
    final estimated = position.pixels + 0.25 * velocity;
    final snapped = (estimated / itemWidth).round() * itemWidth;
    return snapped.clamp(position.minScrollExtent, position.maxScrollExtent);
  }

  @override
  Simulation? createBallisticSimulation(
      ScrollMetrics position, double velocity) {
    final tolerance = toleranceFor(position);
    final target = _targetPixels(position, velocity);
    if ((target - position.pixels).abs() < tolerance.distance &&
        velocity.abs() < tolerance.velocity) {
      return null;
    }
    return ScrollSpringSimulation(
      spring,
      position.pixels,
      target,
      velocity,
      tolerance: tolerance,
    );
  }

  @override
  SpringDescription get spring => SpringDescription.withDampingRatio(
        mass: 0.5,
        stiffness: 100,
        ratio: 1.0,
      );
}
