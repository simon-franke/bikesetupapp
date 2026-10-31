import 'package:flutter/material.dart';
import '../../../common/theme/theme_data.dart';

/// Keeps bike identity stable while the selected tab changes its main value.
class WorkspaceTitle extends StatelessWidget {
  const WorkspaceTitle(
      {super.key,
      required this.bikeName,
      required this.setupName,
      required this.bikeOnly,
      this.activitySummary,
      this.mileageKm,
      this.hours});

  final String bikeName;
  final String setupName;
  final bool bikeOnly;
  final String? activitySummary;
  final double? mileageKm, hours;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final value = bikeOnly ? activitySummary ?? 'No rides yet' : setupName;
    final titleStyle =
        AppTextStyles.inter(size: 24, weight: FontWeight.w600, color: p.ink)
            .copyWith(
                height: 1.4,
                fontFeatures: const [FontFeature.tabularFigures()]);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(bikeName,
            style: AppTextStyles.inter(size: 12, color: p.inkMuted)
                .copyWith(height: 1.4),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
        const SizedBox(height: 2),
        AnimatedSwitcher(
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 180),
          layoutBuilder: (current, previous) => Stack(
            alignment: Alignment.centerLeft,
            children: [...previous, if (current != null) current],
          ),
          child:
              bikeOnly && (mileageKm != null || (hours != null && hours! > 0))
                  ? _ActivityOdometerTitle(
                      key: const ValueKey('activity-odometer'),
                      mileageKm: mileageKm,
                      hours: hours,
                      style: titleStyle)
                  : Text(value,
                      key: ValueKey(value),
                      style: titleStyle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}

class _ActivityOdometerTitle extends StatelessWidget {
  const _ActivityOdometerTitle(
      {super.key,
      required this.mileageKm,
      required this.hours,
      required this.style});
  final double? mileageKm, hours;
  final TextStyle style;

  String label(double? distance) => [
        if (distance != null) '${distance.round()} km',
        if (hours != null && hours! > 0) '${hours!.toStringAsFixed(1)} h',
      ].join('   ');

  @override
  Widget build(BuildContext context) {
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    final finalLabel = label(mileageKm);
    Widget text(String value) =>
        Text(value, style: style, maxLines: 1, overflow: TextOverflow.ellipsis);
    return Semantics(
      label: finalLabel,
      excludeSemantics: true,
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          // Reserve the final width so the header doesn't resize while counting.
          Opacity(opacity: 0, child: text(finalLabel)),
          Positioned.fill(
            child: TweenAnimationBuilder<double>(
              key: ValueKey(finalLabel),
              tween: Tween(begin: 0, end: 1),
              duration: reducedMotion
                  ? Duration.zero
                  : const Duration(milliseconds: 550),
              curve: Curves.easeOutCubic,
              builder: (context, progress, child) => CustomPaint(
                painter: _OdometerPainter(
                  label: finalLabel,
                  progress: reducedMotion ? 1 : progress,
                  style: style,
                  textScaler: MediaQuery.textScalerOf(context),
                  textDirection: Directionality.of(context),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Each fixed-width wheel makes one turn and eases onto its final digit.
class _OdometerPainter extends CustomPainter {
  _OdometerPainter(
      {required this.label,
      required this.progress,
      required this.style,
      required this.textScaler,
      required this.textDirection});
  final String label;
  final double progress;
  final TextStyle style;
  final TextScaler textScaler;
  final TextDirection textDirection;

  TextPainter text(String value, {double maxWidth = double.infinity}) =>
      TextPainter(
          text: TextSpan(text: value, style: style),
          textDirection: textDirection,
          textScaler: textScaler,
          maxLines: 1,
          ellipsis: '…')
        ..layout(maxWidth: maxWidth);

  @override
  void paint(Canvas canvas, Size size) {
    final digitSize = text('0').size;
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    var x = 0.0;
    for (final character in RegExp(r'[0-9]|[^0-9]+')
        .allMatches(label)
        .map((match) => match.group(0)!)) {
      final target = int.tryParse(character);
      if (target == null) {
        final glyph = text(character);
        glyph.paint(canvas, Offset(x, 0));
        x += glyph.width;
        continue;
      }
      final position = (10 + target) * progress;
      final current = position.floor();
      final fraction = position - current;
      canvas.save();
      canvas.clipRect(Rect.fromLTWH(x, 0, digitSize.width, size.height));
      text('${current % 10}')
          .paint(canvas, Offset(x, -fraction * digitSize.height));
      if (fraction > 0) {
        text('${(current + 1) % 10}')
            .paint(canvas, Offset(x, (1 - fraction) * digitSize.height));
      }
      canvas.restore();
      x += digitSize.width;
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_OdometerPainter oldDelegate) =>
      label != oldDelegate.label ||
      progress != oldDelegate.progress ||
      style != oldDelegate.style ||
      textScaler != oldDelegate.textScaler ||
      textDirection != oldDelegate.textDirection;
}
