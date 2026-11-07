import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/physics.dart';
import 'package:flutter/semantics.dart';

import 'package:bikesetupapp/common/theme/theme_data.dart';
import 'package:bikesetupapp/features/setups/models/unit_system.dart';
import 'package:flutter/material.dart';
import 'package:bikesetupapp/common/ui/app_haptics.dart';

const double _tickWidth = 12;
const double _rulerHeight = 70;

class SettingValueEditor extends StatefulWidget {
  final double initialValue;
  final double min;
  final double max;
  final double step;
  final int decimals;
  final String unitLabel;
  final ValueChanged<double> onChanged;
  final VoidCallback? onValueTap;
  final String? valueLabel;
  final bool centerValueAccessory;
  final Widget? valueAccessory;

  const SettingValueEditor({
    super.key,
    required this.initialValue,
    required this.min,
    required this.max,
    required this.step,
    required this.decimals,
    required this.unitLabel,
    required this.onChanged,
    this.onValueTap,
    this.valueLabel,
    this.centerValueAccessory = false,
    this.valueAccessory,
  });

  @override
  State<SettingValueEditor> createState() => _SettingValueEditorState();
}

class _SettingValueEditorState extends State<SettingValueEditor> {
  late final ScrollController _controller;
  late double _effectiveMin;
  late double _effectiveMax;
  late double _step;
  late double _currentValue;
  double _tickSpacing = _tickWidth;
  final _touches = <int, Offset>{};
  bool _pinching = false;
  bool _aligningZoom = false;
  bool _alignmentScheduled = false;
  double _pinchSpan = 1;
  double _pinchSpacing = _tickWidth;
  double _zoomAnchor = 0;
  ScrollHoldController? _zoomHold;

  double get _touchSpan {
    final points = _touches.values.take(2).toList();
    return (points[0] - points[1]).distance;
  }

  void _touchDown(PointerDownEvent event) {
    _touches[event.pointer] = event.localPosition;
    if (_touches.length != 2) return;
    _pinchSpan = math.max(1, _touchSpan);
    _pinchSpacing = _tickSpacing;
    _zoomAnchor = _currentValue;
    _aligningZoom = true;
    _zoomHold = _controller.position.hold(() {});
    setState(() => _pinching = true);
  }

  void _touchMove(PointerMoveEvent event) {
    if (!_touches.containsKey(event.pointer)) return;
    _touches[event.pointer] = event.localPosition;
    if (!_pinching || _touches.length < 2) return;
    _setZoom(_pinchSpacing * _touchSpan / _pinchSpan);
  }

  void _touchEnd(PointerEvent event) {
    _touches.remove(event.pointer);
    if (!_pinching || _touches.length >= 2) return;
    setState(() => _pinching = false);
    _alignZoom();
  }

  void _setZoom(double spacing) {
    final next = spacing.clamp(3.0, 48.0);
    if (!_aligningZoom) {
      _zoomAnchor = _currentValue;
      _aligningZoom = true;
    }
    setState(() => _tickSpacing = next);
    _alignZoom();
  }

  void _alignZoom() {
    if (_alignmentScheduled) return;
    _alignmentScheduled = true;
    // Wait until the new scroll extent is laid out before repositioning it.
    // This is a coordinate change only: it must never publish a new value.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _alignmentScheduled = false;
      if (!mounted || !_controller.hasClients) return;
      _controller.jumpTo((_indexFor(_zoomAnchor) * _tickSpacing)
          .clamp(0.0, _controller.position.maxScrollExtent));
      if (!_pinching) {
        _zoomHold?.cancel();
        _zoomHold = null;
        setState(() => _aligningZoom = false);
      }
    });
  }

  int _indexFor(double value) => ((value - _effectiveMin) / _step).round();
  double _valueFor(int index) => _effectiveMin + index * _step;

  @override
  void initState() {
    super.initState();
    _step = widget.step > 0 ? widget.step : 1.0;
    _effectiveMin = math.min(widget.min, widget.initialValue);
    _effectiveMax = math.max(widget.max, widget.initialValue);
    _currentValue = widget.initialValue;
    _controller = ScrollController(
      initialScrollOffset: _indexFor(widget.initialValue) * _tickWidth,
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
    if (_aligningZoom) return;
    final tickCount = ((_effectiveMax - _effectiveMin) / _step).round();
    final maxOffset = tickCount * _tickSpacing;
    final clamped = _controller.offset.clamp(0.0, maxOffset);
    final index = (clamped / _tickSpacing).round();
    final newValue = _valueFor(index);
    if ((newValue - _currentValue).abs() >= _step / 2) {
      final wasAtBoundary = (_currentValue - _effectiveMin).abs() < _step / 2 ||
          (_currentValue - _effectiveMax).abs() < _step / 2;
      final isAtBoundary = (newValue - _effectiveMin).abs() < _step / 2 ||
          (newValue - _effectiveMax).abs() < _step / 2;
      if (isAtBoundary && !wasAtBoundary) {
        AppHaptics.action();
      } else {
        AppHaptics.selection();
      }
      setState(() => _currentValue = newValue);
      widget.onChanged(newValue);
    }
  }

  Widget _valueHeader({required List<Widget> children}) =>
      widget.centerValueAccessory
          ? Column(mainAxisSize: MainAxisSize.min, children: children)
          : Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: children);

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final tickCount = ((_effectiveMax - _effectiveMin) / _step).round() + 1;
    final contentWidth = (tickCount - 1) * _tickSpacing;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _valueHeader(
          children: [
            Semantics(
              button: widget.onValueTap != null,
              label: widget.onValueTap != null ? 'Enter value' : null,
              child: InkWell(
                onTap: AppHaptics.wrap(widget.onValueTap),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Flex(
                      direction: Axis.vertical,
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        if (widget.valueLabel != null)
                          Text(widget.valueLabel!,
                              style:
                                  AppTextStyles.heading.copyWith(color: p.ink))
                        else
                          _RollingValue(
                            value: _currentValue,
                            decimals: widget.decimals,
                          ),
                        if (widget.valueAccessory == null)
                          SizedBox(height: 4, width: 0),
                        if (widget.valueAccessory == null)
                          Text(
                            widget.unitLabel,
                            style: AppTextStyles.caption
                                .copyWith(color: p.inkMuted),
                          ),
                      ]),
                ),
              ),
            ),
            if (widget.valueAccessory != null) widget.valueAccessory!,
          ],
        ),
        const SizedBox(height: 2),
        Semantics(
          label: 'Adjustment ruler',
          hint: 'Drag to adjust. Pinch to change precision.',
          customSemanticsActions: {
            const CustomSemanticsAction(label: 'Zoom in'): () =>
                _setZoom(_tickSpacing * 2),
            const CustomSemanticsAction(label: 'Zoom out'): () =>
                _setZoom(_tickSpacing / 2),
          },
          child: Listener(
            key: const ValueKey('zoomable-ruler'),
            behavior: HitTestBehavior.opaque,
            onPointerDown: _touchDown,
            onPointerMove: _touchMove,
            onPointerUp: _touchEnd,
            onPointerCancel: _touchEnd,
            child: SizedBox(
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
                        physics: _pinching
                            ? const NeverScrollableScrollPhysics()
                            : _SnapScrollPhysics(
                                itemWidth: _tickSpacing,
                                momentum:
                                    !MediaQuery.disableAnimationsOf(context)),
                        child: Padding(
                          padding:
                              EdgeInsets.symmetric(horizontal: halfViewport),
                          child: SizedBox(
                            width: contentWidth,
                            height: _rulerHeight,
                          ),
                        ),
                      ),
                      Positioned.fill(
                        child: IgnorePointer(
                          child: AnimatedBuilder(
                            animation: _controller,
                            builder: (context, _) {
                              final offset = _aligningZoom
                                  ? _indexFor(_zoomAnchor) * _tickSpacing
                                  : _controller.hasClients
                                      ? _controller.offset
                                      : _controller.initialScrollOffset;
                              return Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Positioned.fill(
                                        child: CustomPaint(
                                      painter: _RulerPainter(
                                        tickCount: tickCount,
                                        minValue: _effectiveMin,
                                        step: _step,
                                        decimals: widget.decimals,
                                        tickWidth: _tickSpacing,
                                        offset: offset,
                                        tickColor: p.borderStrong,
                                        edgeColor: p.surface,
                                        labelColor: p.inkMuted,
                                      ),
                                    )),
                                    _FlexiblePointer(
                                        color: p.accent,
                                        scroll: _controller,
                                        tickWidth: _tickSpacing,
                                        enabled: !_aligningZoom),
                                  ]);
                            },
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
        Text('Pinch to zoom',
            style: AppTextStyles.caption.copyWith(color: p.inkDim)),
      ],
    );
  }
}

/// Only changing digits move. Stable slots and tabular glyphs keep the value
/// readable while the ruler is in motion; semantics expose one whole number.
class _RollingValue extends StatelessWidget {
  const _RollingValue({required this.value, required this.decimals});
  final double value;
  final int decimals;

  @override
  Widget build(BuildContext context) {
    final text = formatNumber(value, decimals);
    final reduced = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      label: text,
      child: ExcludeSemantics(
        child: LayoutBuilder(builder: (context, constraints) {
          final scaler = MediaQuery.textScalerOf(context);
          var style = AppTextStyles.pickerValue;
          for (final candidate in [
            AppTextStyles.pickerValue,
            AppTextStyles.value,
            AppTextStyles.heading
          ]) {
            style = candidate;
            final measure = TextPainter(
                text: TextSpan(text: text, style: style),
                textScaler: scaler,
                textDirection: TextDirection.ltr)
              ..layout();
            final fits = measure.width <= constraints.maxWidth;
            measure.dispose();
            if (fits) break;
          }
          style = style.copyWith(
              color: context.palette.ink,
              fontFeatures: const [FontFeature.tabularFigures()]);
          return Row(mainAxisSize: MainAxisSize.min, children: [
            for (var i = 0; i < text.length; i++)
              _RollingDigit(
                  key: ValueKey(text.length - i),
                  digit: text[i],
                  value: value,
                  style: style,
                  reduced: reduced),
          ]);
        }),
      ),
    );
  }
}

class _RollingDigit extends StatefulWidget {
  const _RollingDigit(
      {super.key,
      required this.digit,
      required this.value,
      required this.style,
      required this.reduced});
  final String digit;
  final double value;
  final TextStyle style;
  final bool reduced;
  @override
  State<_RollingDigit> createState() => _RollingDigitState();
}

class _RollingDigitState extends State<_RollingDigit> {
  double direction = 1;
  @override
  void didUpdateWidget(_RollingDigit oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      direction = widget.value > oldWidget.value ? 1 : -1;
    }
  }

  @override
  Widget build(BuildContext context) {
    final glyph = Text(widget.digit, style: widget.style);
    if (widget.reduced || widget.digit == '.' || widget.digit == '-') {
      return glyph;
    }
    return ClipRect(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 140),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          final incoming = child.key == ValueKey(widget.digit);
          return AnimatedBuilder(
              animation: animation,
              builder: (context, _) {
                final travel = 1 - animation.value;
                return ImageFiltered(
                  enabled: travel > 0.01,
                  imageFilter:
                      ui.ImageFilter.blur(sigmaX: 0, sigmaY: 0.8 * travel),
                  child: FractionalTranslation(
                      translation: Offset(0,
                          (incoming ? direction : -direction) * travel * 0.3),
                      child: Opacity(opacity: animation.value, child: child)),
                );
              });
        },
        child: Text(widget.digit,
            key: ValueKey(widget.digit), style: widget.style),
      ),
    );
  }
}

class _FlexiblePointer extends StatefulWidget {
  const _FlexiblePointer(
      {required this.color,
      required this.scroll,
      required this.tickWidth,
      required this.enabled});
  final Color color;
  final ScrollController scroll;
  final double tickWidth;
  final bool enabled;

  @override
  State<_FlexiblePointer> createState() => _FlexiblePointerState();
}

class _FlexiblePointerState extends State<_FlexiblePointer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bend =
      AnimationController.unbounded(vsync: this);
  late double _lastOffset = widget.scroll.hasClients
      ? widget.scroll.offset
      : widget.scroll.initialScrollOffset;
  final _clock = Stopwatch()..start();
  Duration? _lastFrame;

  @override
  void initState() {
    super.initState();
    widget.scroll.addListener(_onScroll);
  }

  void _onScroll() {
    final now = _clock.elapsed;
    final delta = widget.scroll.offset - _lastOffset;
    final elapsed = _lastFrame == null
        ? 1 / 60
        : ((now - _lastFrame!).inMicroseconds / 1000000).clamp(1 / 240, 0.1);
    _lastFrame = now;
    _lastOffset = widget.scroll.offset;
    if (!widget.enabled || MediaQuery.disableAnimationsOf(context)) {
      _bend.stop();
      _bend.value = 0;
      return;
    }
    final speed = (delta.abs() / elapsed / 800).clamp(0.0, 1.0);
    final phase = (widget.scroll.offset / widget.tickWidth) % 1;
    // A slower turn barely flexes the pointer. Release quickly removes the
    // load, including when the user pauses midway between two ticks.
    _bend.value = -delta.sign * math.sin(math.pi * phase) * 4 * speed;
    _bend.animateTo(0,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOutCubic);
  }

  @override
  void dispose() {
    widget.scroll.removeListener(_onScroll);
    _clock.stop();
    _bend.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 24,
        height: _rulerHeight,
        child: AnimatedBuilder(
            animation: _bend,
            builder: (context, _) => CustomPaint(
                painter:
                    _PointerPainter(color: widget.color, bend: _bend.value))),
      );
}

class _PointerPainter extends CustomPainter {
  final Color color;
  final double bend;
  const _PointerPainter({required this.color, required this.bend});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;

    // The anchor stays fixed while the flexible tip is pushed by each tick.
    final pointer = Path()
      ..moveTo(cx, 8)
      ..cubicTo(cx, 16, cx + bend * 0.25, 24, cx + bend, 34);
    canvas.drawPath(
        pointer,
        Paint()
          ..color = color
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke);
  }

  @override
  bool shouldRepaint(_PointerPainter old) =>
      old.color != color || old.bend != bend;
}

/// Projects the ticks onto a cylindrical drum. Spacing and height compress at
/// its edges; only the visible arc is painted, even for very large ranges.
class _RulerPainter extends CustomPainter {
  final int tickCount;
  final double minValue, step, tickWidth, offset;
  final int decimals;
  final Color tickColor, edgeColor, labelColor;

  const _RulerPainter({
    required this.tickCount,
    required this.minValue,
    required this.step,
    required this.decimals,
    required this.tickWidth,
    required this.offset,
    required this.tickColor,
    required this.edgeColor,
    required this.labelColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Moving closer enlarges the drum: the visible arc becomes flatter while
    // the spacing between its markings grows. Pulling back reveals its curve.
    final zoom = tickWidth / _tickWidth;
    final radius =
        math.max(1.0, size.width / 2 - 4) * math.sqrt(zoom).clamp(0.8, 2.0);
    final center = size.width / 2;
    const arcLimit = 1.35;
    int niceInterval(double target) {
      for (final interval in [1, 2, 5, 10, 20, 50, 100]) {
        if (interval >= target) return interval;
      }
      return 100;
    }

    final minorInterval = niceInterval(8 / tickWidth);
    final labelSpacing = (90 / math.sqrt(zoom)).clamp(44.0, 90.0);
    final majorInterval = niceInterval(labelSpacing / tickWidth);
    final midInterval = math.max(minorInterval, majorInterval ~/ 2);
    final first = math.max(
        0,
        ((offset - radius * arcLimit) / tickWidth / minorInterval).floor() *
            minorInterval);
    final last = math.min(
        tickCount - 1, ((offset + radius * arcLimit) / tickWidth).ceil());
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    var lastLabelRight = -double.infinity;
    for (var i = first; i <= last; i += minorInterval) {
      // Keep every selectable step near the pointer; remove minor marks at
      // the sides where perspective would crowd them together.
      final angle = (i * tickWidth - offset) / radius;
      final visibility = i % midInterval == 0
          ? 1.0
          : ((0.75 - angle.abs()) / 0.3).clamp(0.0, 1.0);
      if (visibility == 0) continue;
      if (angle.abs() > arcLimit) continue;
      final depth = math.cos(angle);
      final x = center + radius * math.sin(angle);
      final edgeFade = (math.min(x, size.width - x) / 24).clamp(0.0, 1.0);
      if (edgeFade == 0) continue;
      final top = 13 + 8 * (1 - depth);
      final major = i % majorInterval == 0;
      final mid = i % midInterval == 0;
      final height = (major ? 21.0 : (mid ? 15.0 : 7.0)) * depth;
      final tick = Paint()
        ..color = Color.lerp(
            edgeColor, tickColor, depth * depth * visibility * edgeFade)!
        ..strokeWidth = major ? 3 : (mid ? 2 : 1.5)
        ..strokeCap = StrokeCap.round;
      if (depth < 0.65) {
        tick.maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.6);
      }
      canvas.drawLine(Offset(x, top), Offset(x, top + height), tick);
      // Keep only the front-facing labels; edge labels would be compressed
      // beyond readability. The selected value above remains fully accessible.
      if (major && depth > 0.65) {
        final tp = TextPainter(
          text: TextSpan(
            text: formatNumber(minValue + i * step, decimals),
            style: AppTextStyles.caption.copyWith(
                color: labelColor,
                fontFeatures: const [FontFeature.tabularFigures()]),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        final left = x - tp.width / 2;
        final right = x + tp.width / 2;
        if (left >= 8 &&
            right <= size.width - 8 &&
            left >= lastLabelRight + 12) {
          tp.paint(canvas, Offset(left, 45));
          lastLabelRight = right;
        }
        tp.dispose();
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_RulerPainter old) =>
      old.tickCount != tickCount ||
      old.minValue != minValue ||
      old.step != step ||
      old.decimals != decimals ||
      old.tickWidth != tickWidth ||
      old.offset != offset ||
      old.tickColor != tickColor ||
      old.edgeColor != edgeColor ||
      old.labelColor != labelColor;
}

class _SnapScrollPhysics extends ScrollPhysics {
  final double itemWidth;
  final bool momentum;
  const _SnapScrollPhysics(
      {required this.itemWidth, this.momentum = true, super.parent});

  @override
  _SnapScrollPhysics applyTo(ScrollPhysics? ancestor) => _SnapScrollPhysics(
      itemWidth: itemWidth, momentum: momentum, parent: buildParent(ancestor));

  double _targetPixels(ScrollMetrics position, double velocity) {
    final coast = momentum
        ? FrictionSimulation(0.08, position.pixels, velocity).finalX -
            position.pixels
        : 0.0;
    // A quick flick should cover nearby adjustments, not race across the
    // entire measurement range. Direct entry handles large changes.
    final estimated =
        position.pixels + coast.clamp(-20 * itemWidth, 20 * itemWidth);
    final snapped = (estimated / itemWidth).round() * itemWidth;
    return snapped.clamp(position.minScrollExtent, position.maxScrollExtent);
  }

  @override
  Simulation? createBallisticSimulation(
      ScrollMetrics position, double velocity) {
    velocity = velocity.clamp(-1200.0, 1200.0);
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
      momentum ? velocity : 0,
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
