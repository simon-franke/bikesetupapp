import 'package:bikesetupapp/app_services/theme_data.dart';
import 'package:bikesetupapp/app_services/responsive_layout.dart';
import 'package:bikesetupapp/bike_enums/category.dart';
import 'package:bikesetupapp/database_service/database.dart';
import 'package:bikesetupapp/widgets/field_meta.dart';
import 'package:bikesetupapp/widgets/progress_indicator.dart';
import 'package:bikesetupapp/widgets/unit_system.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const double bubbleCardW = 70.0;
const double bubbleCardH = 44.0;
Size schematicCardSize(BuildContext context) {
  final wide = ResponsiveLayout.isWide(context);
  final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
  return Size(
      (wide ? 112 : bubbleCardW) * scale, (wide ? 64 : bubbleCardH) * scale);
}

const double _dotRadius = 5.0;

class _LeaderLinePainter extends CustomPainter {
  final Offset dotCenter;
  final Offset cardCenter;
  final Color activeColor;
  final Color inactiveColor;
  final Color background;
  final bool selected;

  const _LeaderLinePainter({
    required this.dotCenter,
    required this.cardCenter,
    required this.activeColor,
    required this.inactiveColor,
    required this.background,
    required this.selected,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final width = selected ? 1.8 : 1.2;
    final paint = Paint()
      ..color = selected ? activeColor : inactiveColor
      ..strokeWidth = width
      ..style = PaintingStyle.stroke;
    final halo = Paint()
      ..color = background
      ..strokeWidth = width + 2
      ..style = PaintingStyle.stroke;
    void line(Offset start, Offset end) {
      canvas.drawLine(start, end, halo);
      canvas.drawLine(start, end, paint);
    }

    if (selected) {
      line(dotCenter, cardCenter);
      return;
    }
    final vector = cardCenter - dotCenter;
    final length = vector.distance;
    if (length == 0) return;
    final direction = vector / length;
    for (double offset = 0; offset < length; offset += 8) {
      line(dotCenter + direction * offset,
          dotCenter + direction * (offset + 5).clamp(0, length));
    }
  }

  @override
  bool shouldRepaint(_LeaderLinePainter old) =>
      old.dotCenter != dotCenter ||
      old.cardCenter != cardCenter ||
      old.activeColor != activeColor ||
      old.inactiveColor != inactiveColor ||
      old.background != background ||
      old.selected != selected;
}

class SchematicBubble extends StatefulWidget {
  final User user;
  // Anchor dot — sits on the bike part
  final double anchorLeft;
  final double anchorBottom;
  // Floating card — in clear space nearby
  final double bubbleLeft;
  final double bubbleBottom;
  final double containerHeight;
  final String bikeName;
  final Category category;
  final Category chosenCategory;
  final String setup;
  final VoidCallback? onPressed;
  final Function(String) onValueChange;
  final bool show;

  const SchematicBubble({
    super.key,
    required this.user,
    required this.anchorLeft,
    required this.anchorBottom,
    required this.bubbleLeft,
    required this.bubbleBottom,
    required this.containerHeight,
    required this.bikeName,
    required this.category,
    required this.chosenCategory,
    required this.setup,
    required this.onPressed,
    required this.onValueChange,
    required this.show,
  });

  @override
  State<SchematicBubble> createState() => _SchematicBubbleState();
}

class _SchematicBubbleState extends State<SchematicBubble>
    with TickerProviderStateMixin {
  late AnimationController _tapController;
  late AnimationController _selectController;
  late Animation<double> _tapScale;
  late Animation<double> _selectScale;
  String _latestValue = '';

  bool get _isSelected => widget.chosenCategory == widget.category;

  ({String value, String unit}) _displayFor(String key, String rawValue) {
    final meta = kFieldMeta[key];
    final parsed = SettingValue.parse(
      rawValue,
      fallbackFamily: meta?.family,
      fallbackUnit: meta?.defaultUnit,
    );
    if (parsed.isText) return (value: parsed.text ?? '', unit: '');
    if (parsed.number == null) return (value: rawValue, unit: '');
    return (value: parsed.displayNumber(), unit: parsed.displayUnit());
  }

  @override
  void initState() {
    super.initState();
    _tapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _selectController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _tapScale = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _tapController, curve: Curves.easeInOut),
    );
    _selectScale = Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(parent: _selectController, curve: Curves.easeOut),
    );
  }

  @override
  void didUpdateWidget(SchematicBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.chosenCategory != oldWidget.chosenCategory && _isSelected) {
      _selectController.forward(from: 0).then((_) {
        if (mounted) _selectController.reverse();
      });
    }
  }

  @override
  void dispose() {
    _tapController.dispose();
    _selectController.dispose();
    super.dispose();
  }

  String _categoryLabel(Category cat) {
    switch (cat) {
      case Category.rearTire:
        return 'Rear tire';
      case Category.frontTire:
        return 'Front tire';
      case Category.shock:
        return 'Shock';
      case Category.fork:
        return 'Fork';
      case Category.generalSettings:
        return 'Geometry';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.show) return const SizedBox.shrink();

    final p = context.palette;
    final bool isSelected = _isSelected;
    final cardSize = schematicCardSize(context);
    final wide = ResponsiveLayout.isWide(context);

    // Convert bottom-origin coordinates to top-origin for the painter.
    final Offset dotCenter = Offset(
      widget.anchorLeft + _dotRadius,
      widget.containerHeight - widget.anchorBottom - _dotRadius,
    );
    final Offset cardCenter = Offset(
      widget.bubbleLeft + cardSize.width / 2,
      widget.containerHeight - widget.bubbleBottom - cardSize.height / 2,
    );

    return Positioned.fill(
      child: Stack(
        children: [
          // Leader line spanning the full container
          if (wide || isSelected)
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _LeaderLinePainter(
                    dotCenter: dotCenter,
                    cardCenter: cardCenter,
                    activeColor: p.accentText,
                    inactiveColor: p.inkMuted,
                    background: p.bg,
                    selected: isSelected,
                  ),
                ),
              ),
            ),

          // Anchor dot on the bike part
          if (wide || isSelected)
            Positioned(
              left: widget.anchorLeft,
              bottom: widget.anchorBottom,
              child: IgnorePointer(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: _dotRadius * 2,
                  height: _dotRadius * 2,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? p.accentText : p.inkMuted,
                    border: Border.all(color: p.bg, width: 1.5),
                  ),
                ),
              ),
            ),

          // Floating schematic card
          Positioned(
            left: widget.bubbleLeft,
            bottom: widget.bubbleBottom,
            child: ScaleTransition(
              scale: _selectScale,
              child: ScaleTransition(
                scale: _tapScale,
                child: GestureDetector(
                  onTap: () {
                    _tapController.forward(from: 0).then((_) {
                      if (mounted) _tapController.reverse();
                    });
                    HapticFeedback.lightImpact();
                    widget.onPressed?.call();
                  },
                  onLongPress: () {
                    HapticFeedback.mediumImpact();
                    widget.onValueChange(_latestValue);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOut,
                    width: cardSize.width,
                    height: cardSize.height,
                    decoration: BoxDecoration(
                      color: isSelected ? p.accent : p.surface,
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(
                          color: isSelected ? p.accentText : p.borderStrong),
                    ),
                    child: StreamBuilder(
                      stream: DatabaseService(widget.user.uid)
                          .getDocumentElement(widget.bikeName,
                              widget.category.category, widget.setup),
                      builder: (context, AsyncSnapshot snapshot) {
                        final String label = _categoryLabel(widget.category);
                        final Color chipInk = isSelected ? p.accentInk : p.ink;

                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Center(
                            child: PulsatingCircle(
                              color: chipInk,
                              size: 14,
                            ),
                          );
                        }

                        final bool isGeometry =
                            widget.category == Category.generalSettings;
                        String element = '';
                        String elementKey = '';
                        int specCount = 0;
                        bool hasError = false;
                        if (snapshot.hasError ||
                            !snapshot.hasData ||
                            snapshot.data == null) {
                          hasError = true;
                        } else {
                          try {
                            final rawMap = snapshot.data.data();
                            if (rawMap is Map) {
                              final data = rawMap.cast<String, dynamic>();
                              if (isGeometry) {
                                for (final entry in data.entries) {
                                  final s = entry.value?.toString() ?? '';
                                  if (s.isNotEmpty) specCount++;
                                }
                              } else {
                                final priorityKeys = kDefaultFieldKeys[
                                        widget.category.category] ??
                                    [];
                                for (final k in priorityKeys) {
                                  final v = data[k]?.toString() ?? '';
                                  if (v.isNotEmpty) {
                                    element = v;
                                    elementKey = k;
                                    break;
                                  }
                                }
                                if (element.isEmpty) {
                                  for (final entry in data.entries) {
                                    final s = entry.value?.toString() ?? '';
                                    if (s.isNotEmpty) {
                                      element = s;
                                      elementKey = entry.key;
                                      break;
                                    }
                                  }
                                }
                              }
                            }
                          } catch (_) {}
                          if (!isGeometry && element.isEmpty) hasError = true;
                        }

                        if (!isGeometry &&
                            !hasError &&
                            element != _latestValue) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted && _latestValue != element) {
                              setState(() => _latestValue = element);
                            }
                          });
                        }

                        final display = isGeometry
                            ? (
                                value: '$specCount',
                                unit: (specCount == 1 ? 'spec' : 'specs'),
                              )
                            : _displayFor(elementKey, element);

                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 5),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                label,
                                style: TextStyle(
                                  color: chipInk,
                                  fontSize: wide ? 14 : 10,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0,
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 1),
                              hasError
                                  ? Icon(Icons.error_outline,
                                      size: 14, color: chipInk)
                                  : Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.baseline,
                                      textBaseline: TextBaseline.alphabetic,
                                      children: [
                                        Flexible(
                                          child: Text(
                                            display.value,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: AppTextStyles.mono(
                                              size: wide ? 20 : 13,
                                              weight: FontWeight.w700,
                                              color: chipInk,
                                              height: 1,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 2),
                                        Flexible(
                                          child: Text(
                                            display.unit,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: chipInk,
                                              fontSize: wide ? 12 : 8.5,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
