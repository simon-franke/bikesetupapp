import 'package:flutter/material.dart';

const double kWideBreakpoint = 768.0;

class ResponsiveLayout {
  static bool isWide(BuildContext context) =>
      MediaQuery.of(context).size.width >= kWideBreakpoint;

  static const double sidebarWidth = 300.0;

  static double contentWidth(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return isWide(context) ? w - sidebarWidth : w;
  }
}
