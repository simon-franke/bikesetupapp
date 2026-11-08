import 'app_haptics.dart';
import 'package:flutter/cupertino.dart';
import 'package:bikesetupapp/common/theme/theme_data.dart';
import 'package:flutter/material.dart';

/// A compact detail header with room for long titles and larger system text.
AppBar buildDetailAppBar(
  BuildContext context, {
  required String title,
  List<Widget> actions = const [],
  VoidCallback? onBack,
  bool backEnabled = true,
}) {
  final style = AppTextStyles.heading.copyWith(
    color: context.palette.ink,
    fontFamily: Theme.of(context).textTheme.titleLarge?.fontFamily,
  );
  // Match the toolbar's leading space, title gaps, and 48px action targets.
  final titleWidth =
      (MediaQuery.sizeOf(context).width - 68 - 16 - 20 - actions.length * 48)
          .clamp(1.0, double.infinity);
  final painter = TextPainter(
    text: TextSpan(text: title, style: style),
    textDirection: Directionality.of(context),
    textScaler: MediaQuery.textScalerOf(context),
  )..layout(maxWidth: titleWidth);
  final height = (painter.height + 24).clamp(64.0, double.infinity);
  painter.dispose();

  return AppBar(
    automaticallyImplyLeading: false,
    centerTitle: false,
    toolbarHeight: height,
    leadingWidth: 68,
    leading: Padding(
      padding: const EdgeInsets.only(left: 20),
      child: Builder(
          builder: (routeContext) => IconButton(
                tooltip:
                    MaterialLocalizations.of(routeContext).backButtonTooltip,
                icon: const Icon(CupertinoIcons.chevron_left,
                    size: AppIconSizes.compact),
                onPressed: AppHaptics.wrap(backEnabled
                    ? onBack ?? () => Navigator.of(routeContext).maybePop()
                    : null),
              )),
    ),
    titleSpacing: 8,
    title: Text(title,
        style: style,
        textScaler: MediaQuery.textScalerOf(context),
        softWrap: true,
        overflow: TextOverflow.visible),
    actionsPadding: const EdgeInsets.only(right: 20),
    actions:
        actions.map((action) => SizedBox(width: 48, child: action)).toList(),
  );
}

class AppSectionLabel extends StatelessWidget {
  final String label;

  const AppSectionLabel(this.label, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Semantics(
            header: true,
            child: Text(label, style: Theme.of(context).textTheme.titleMedium)),
      );
}

/// Titles and actions share a baseline and wrap together in narrow panes.
class AppSectionToolbar extends StatelessWidget {
  final Widget title;
  final Widget? action;

  const AppSectionToolbar({super.key, required this.title, this.action});

  @override
  Widget build(BuildContext context) =>
      LayoutBuilder(builder: (context, constraints) {
        if (action == null) return title;

        if (constraints.maxWidth < 420 ||
            MediaQuery.textScalerOf(context).scale(14) > 22) {
          return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [title, const SizedBox(height: 8), action!]);
        }

        return Row(children: [
          Expanded(child: title),
          const SizedBox(width: 16),
          action!
        ]);
      });
}
