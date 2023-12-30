import 'package:flutter/material.dart';

class PulsatingCircle extends StatefulWidget {
  final double size;
  final Color color;

  const PulsatingCircle({
    Key? key,
    required this.size,
    required this.color,
  }) : super(key: key);

  @override
  State<PulsatingCircle> createState() => _PulsatingCircleState();
}

class _PulsatingCircleState extends State<PulsatingCircle>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: false);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return ScaleTransition(
          scale: Tween<double>(begin: 1.0, end: 1.3).animate(
            CurvedAnimation(
              parent: _animationController,
              curve: Curves.easeInOut,
            ),
          ),
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.color.withOpacity(0.3),
            ),
          ),
        );
      },
    );
  }
}
