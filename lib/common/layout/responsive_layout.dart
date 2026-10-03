import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:bikesetupapp/common/theme/theme_data.dart';

const double kWideBreakpoint = 768.0;
const double kWorkspaceDiagramMinWidth = 440.0;
const double kWorkspaceSettingsMinWidth = 384.0;
const double kContentMaxWidth = 1440.0;

class ResponsiveLayout {
  static bool isWide(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= kWideBreakpoint;
}

/// Limit reading and interaction distances without scaling up phone controls.
class AppContentFrame extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry padding;
  const AppContentFrame(
      {super.key,
      required this.child,
      this.maxWidth = kContentMaxWidth,
      this.padding = EdgeInsets.zero});

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.topCenter,
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: SizedBox(
              width: double.infinity,
              child: Padding(padding: padding, child: child)),
        ),
      );
}

/// Use independent diagram and settings panes when both have useful room.
class SetupWorkspace extends StatelessWidget {
  final Widget Function(double width, double height) diagramBuilder;
  final Widget settings;
  const SetupWorkspace(
      {super.key, required this.diagramBuilder, required this.settings});

  @override
  Widget build(BuildContext context) =>
      LayoutBuilder(builder: (context, constraints) {
        final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
        if (constraints.maxWidth / 2 >=
                math.max(kWorkspaceDiagramMinWidth,
                    kWorkspaceSettingsMinWidth * scale) &&
            constraints.maxHeight >= 360 &&
            scale < 1.6) {
          final diagramWidth = constraints.maxWidth / 2;
          final diagramHeight = constraints.maxHeight;
          return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SizedBox(
                width: diagramWidth,
                child: diagramBuilder(diagramWidth, diagramHeight)),
            Expanded(
                child: ConstrainedBox(
                    constraints:
                        BoxConstraints(maxHeight: constraints.maxHeight),
                    child: Container(
                      decoration: BoxDecoration(
                          border: Border(
                              left: BorderSide(color: context.palette.border))),
                      padding: const EdgeInsets.only(left: 24),
                      child: settings,
                    ))),
          ]);
        }
        final diagramWidth = constraints.maxWidth.clamp(0.0, 700.0);
        final baseHeight = constraints.maxWidth >= kWideBreakpoint
            ? (diagramWidth * .68).clamp(360.0, 460.0)
            : (MediaQuery.sizeOf(context).height / 3.2).clamp(220.0, 320.0);
        final diagramHeight = math.max(baseHeight,
            (ResponsiveLayout.isWide(context) ? 64 : 44) * scale * 3 + 48);
        return SingleChildScrollView(
            child: Column(children: [
          AppContentFrame(
              maxWidth: 700,
              child: diagramBuilder(diagramWidth, diagramHeight)),
          const SizedBox(height: 20),
          settings,
        ]));
      });
}

/// Natural-height cards avoid clipping service content when text is enlarged.
class ResponsiveCardGrid extends StatelessWidget {
  final List<Widget> children;
  const ResponsiveCardGrid({super.key, required this.children});

  @override
  Widget build(BuildContext context) =>
      LayoutBuilder(builder: (context, constraints) {
        final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
        final columns = constraints.maxWidth >= kWideBreakpoint &&
                constraints.maxWidth / 2 >= 360 * scale
            ? 2
            : 1;
        if (columns == 1 || children.length == 1) {
          return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < children.length; i++) ...[
                  if (i > 0 && ResponsiveLayout.isWide(context))
                    const SizedBox(height: 16),
                  children[i],
                ],
              ]);
        }
        return Wrap(spacing: 16, runSpacing: 16, children: [
          for (var i = 0; i < children.length; i++)
            SizedBox(
                width: children.length.isOdd && i == children.length - 1
                    ? constraints.maxWidth
                    : (constraints.maxWidth - 16) / 2,
                child: children[i]),
        ]);
      });
}
