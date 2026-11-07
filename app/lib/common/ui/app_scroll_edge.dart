import 'package:flutter/material.dart';

/// Clips scrolling content beneath a fixed header without decoration.
class AppScrollEdge extends StatelessWidget {
  const AppScrollEdge({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => ClipRect(child: child);
}
