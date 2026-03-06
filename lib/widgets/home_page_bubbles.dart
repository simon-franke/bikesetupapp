import 'package:bikesetupapp/widgets/progress_indicator.dart';
import 'package:bikesetupapp/bike_enums/category.dart';
import 'package:bikesetupapp/database_service/database.dart';
import 'package:bikesetupapp/widgets/field_meta.dart';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';

const double bubbleCardW = 76.0;
const double bubbleCardH = 50.0;
const double _dotRadius = 5.0;
const Color _activeColor = Color(0xFFFF6B00);

class _LeaderLinePainter extends CustomPainter {
  final Offset dotCenter;
  final Offset cardCenter;
  final bool isSelected;

  const _LeaderLinePainter({
    required this.dotCenter,
    required this.cardCenter,
    required this.isSelected,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isSelected
          ? _activeColor.withValues(alpha: 0.75)
          : Colors.white.withValues(alpha: 0.45)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawLine(dotCenter, cardCenter, paint);
  }

  @override
  bool shouldRepaint(_LeaderLinePainter old) =>
      old.isSelected != isSelected ||
      old.dotCenter != dotCenter ||
      old.cardCenter != cardCenter;
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
        return 'SETTINGS';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.show) return const SizedBox.shrink();

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
                  color: isSelected
                      ? _activeColor
                      : Colors.white.withValues(alpha: 0.7),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: _activeColor.withValues(alpha: 0.55),
                            blurRadius: 8,
                            spreadRadius: 2,
                          )
                        ]
                      : [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 3,
                          )
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
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    width: bubbleCardW,
                    height: bubbleCardH,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected ? _activeColor : Colors.transparent,
                        width: 2.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black
                              .withValues(alpha: isSelected ? 0.38 : 0.22),
                          blurRadius: isSelected ? 14 : 7,
                          spreadRadius: isSelected ? 1 : 0,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: StreamBuilder(
                      stream: DatabaseService(widget.user.uid)
                          .getDocumentElement(widget.bikeName,
                              widget.category.category, widget.setup),
                      builder: (context, AsyncSnapshot snapshot) {
                        final String label = _categoryLabel(widget.category);

                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Center(
                            child: PulsatingCircle(
                              color: Colors.grey.shade300,
                              size: 20,
                            ),
                          );
                        }

                        Widget valueWidget;

                        if (widget.category == Category.generalSettings) {
                          valueWidget = Icon(
                            Icons.settings,
                            color: isSelected ? _activeColor : Colors.black54,
                            size: 16,
                          );
                        } else if (snapshot.hasError ||
                            !snapshot.hasData ||
                            snapshot.data == null) {
                          valueWidget = const Icon(
                            Icons.error_outline,
                            color: Colors.redAccent,
                            size: 16,
                          );
                        } else {
                          String element = '';
                          try {
                            final rawMap = snapshot.data.data();
                            if (rawMap is Map) {
                              final data = rawMap.cast<String, dynamic>();
                              final priorityKeys = kDefaultFieldKeys[widget.category.category] ?? [];
                              for (final k in priorityKeys) {
                                final v = data[k]?.toString() ?? '';
                                if (v.isNotEmpty) { element = v; break; }
                              }
                              if (element.isEmpty) {
                                for (final v in data.values) {
                                  final s = v?.toString() ?? '';
                                  if (s.isNotEmpty) { element = s; break; }
                                }
                              }
                            }
                          } catch (_) {}

                          if (element.isEmpty) {
                            valueWidget = const Icon(
                              Icons.error_outline,
                              color: Colors.redAccent,
                              size: 16,
                            );
                          } else {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (mounted && _latestValue != element) {
                                setState(() => _latestValue = element);
                              }
                            });
                            valueWidget = Text(
                              element,
                              style: const TextStyle(
                                color: Colors.black87,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            );
                          }
                        }

                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 5),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                label,
                                style: TextStyle(
                                  color: isSelected
                                      ? _activeColor
                                      : Colors.black38,
                                  fontSize: 8,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.6,
                                ),
                              ),
                              const SizedBox(height: 3),
                              valueWidget,
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
