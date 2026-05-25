import 'package:bikesetupapp/app_services/theme_data.dart';
import 'package:bikesetupapp/bike_enums/category.dart';
import 'package:bikesetupapp/database_service/database.dart';
import 'package:bikesetupapp/widgets/field_meta.dart';
import 'package:bikesetupapp/widgets/progress_indicator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const double bubbleCardW = 70.0;
const double bubbleCardH = 44.0;
const double _dotRadius = 5.0;

class _LeaderLinePainter extends CustomPainter {
  final Offset dotCenter;
  final Offset cardCenter;
  final bool isSelected;
  final Color activeColor;
  final Color inactiveColor;

  const _LeaderLinePainter({
    required this.dotCenter,
    required this.cardCenter,
    required this.isSelected,
    required this.activeColor,
    required this.inactiveColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isSelected ? activeColor : inactiveColor
      ..strokeWidth = isSelected ? 1.5 : 1.0
      ..style = PaintingStyle.stroke;

    if (isSelected) {
      canvas.drawLine(dotCenter, cardCenter, paint);
      return;
    }
    const double dash = 3, gap = 2;
    final length = (cardCenter - dotCenter).distance;
    if (length == 0) return;
    final ux = (cardCenter.dx - dotCenter.dx) / length;
    final uy = (cardCenter.dy - dotCenter.dy) / length;
    double drawn = 0;
    while (drawn < length) {
      final segEnd = (drawn + dash).clamp(0.0, length);
      final start = Offset(dotCenter.dx + ux * drawn, dotCenter.dy + uy * drawn);
      final end = Offset(dotCenter.dx + ux * segEnd, dotCenter.dy + uy * segEnd);
      canvas.drawLine(start, end, paint);
      drawn += dash + gap;
    }
  }

  @override
  bool shouldRepaint(_LeaderLinePainter old) =>
      old.isSelected != isSelected ||
      old.dotCenter != dotCenter ||
      old.cardCenter != cardCenter ||
      old.activeColor != activeColor ||
      old.inactiveColor != inactiveColor;
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

  String _unitFor(String key) => kFieldMeta[key]?.unit ?? '';

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
    _tapScale = Tween<double>(begin: 1.0, end: 0.88).animate(
      CurvedAnimation(parent: _tapController, curve: Curves.easeInOut),
    );
    _selectScale = Tween<double>(begin: 1.0, end: 1.12).animate(
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
        return 'REAR TIRE';
      case Category.frontTire:
        return 'FRONT TIRE';
      case Category.shock:
        return 'SHOCK';
      case Category.fork:
        return 'FORK';
      case Category.generalSettings:
        return 'GEOMETRY';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.show) return const SizedBox.shrink();

    final p = context.palette;
    final bool isSelected = _isSelected;

    // Convert bottom-origin coordinates to top-origin for the painter.
    final Offset dotCenter = Offset(
      widget.anchorLeft + _dotRadius,
      widget.containerHeight - widget.anchorBottom - _dotRadius,
    );
    final Offset cardCenter = Offset(
      widget.bubbleLeft + bubbleCardW / 2,
      widget.containerHeight - widget.bubbleBottom - bubbleCardH / 2,
    );

    return Positioned.fill(
      child: Stack(
        children: [
          // Leader line spanning the full container
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _LeaderLinePainter(
                  dotCenter: dotCenter,
                  cardCenter: cardCenter,
                  isSelected: isSelected,
                  activeColor: p.accent,
                  inactiveColor: Colors.white.withValues(alpha: 0.35),
                ),
              ),
            ),
          ),

          // Anchor dot on the bike part
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
                  color: isSelected ? p.accent : AppColors.darkInk,
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.6),
                            spreadRadius: 3,
                          ),
                          BoxShadow(
                            color: p.accent.withValues(alpha: 0.65),
                            blurRadius: 14,
                          ),
                        ]
                      : [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.55),
                            spreadRadius: 3,
                          ),
                        ],
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
                    width: bubbleCardW,
                    height: bubbleCardH,
                    decoration: BoxDecoration(
                      color: isSelected ? p.accent : AppColors.darkCard,
                      borderRadius: BorderRadius.circular(9),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.55),
                                blurRadius: 18,
                                offset: const Offset(0, 6),
                              ),
                            ]
                          : [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.4),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                    ),
                    child: StreamBuilder(
                      stream: DatabaseService(widget.user.uid)
                          .getDocumentElement(widget.bikeName,
                              widget.category.category, widget.setup),
                      builder: (context, AsyncSnapshot snapshot) {
                        final String label = _categoryLabel(widget.category);
                        final Color chipInk = isSelected ? p.accentInk : AppColors.darkCardInk;

                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Center(
                            child: PulsatingCircle(
                              color: chipInk.withValues(alpha: 0.4),
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
                        if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
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
                                final priorityKeys = kDefaultFieldKeys[widget.category.category] ?? [];
                                for (final k in priorityKeys) {
                                  final v = data[k]?.toString() ?? '';
                                  if (v.isNotEmpty) { element = v; elementKey = k; break; }
                                }
                                if (element.isEmpty) {
                                  for (final entry in data.entries) {
                                    final s = entry.value?.toString() ?? '';
                                    if (s.isNotEmpty) { element = s; elementKey = entry.key; break; }
                                  }
                                }
                              }
                            }
                          } catch (_) {}
                          if (!isGeometry && element.isEmpty) hasError = true;
                        }

                        if (!isGeometry && !hasError && element != _latestValue) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted && _latestValue != element) {
                              setState(() => _latestValue = element);
                            }
                          });
                        }

                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                label,
                                style: TextStyle(
                                  color: chipInk.withValues(alpha: 0.65),
                                  fontSize: 7.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8,
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 2),
                              hasError
                                  ? Icon(Icons.error_outline, size: 14, color: chipInk.withValues(alpha: 0.55))
                                  : Row(
                                      crossAxisAlignment: CrossAxisAlignment.baseline,
                                      textBaseline: TextBaseline.alphabetic,
                                      children: [
                                        Flexible(
                                          child: Text(
                                            isGeometry ? '$specCount' : element,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: AppTextStyles.mono(
                                              size: 13,
                                              weight: FontWeight.w700,
                                              color: chipInk,
                                              height: 1,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 2),
                                        Flexible(
                                          child: Text(
                                            isGeometry
                                                ? (specCount == 1 ? 'spec' : 'specs')
                                                : _unitFor(elementKey),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: chipInk.withValues(alpha: 0.65),
                                              fontSize: 8.5,
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
