import '../../app/routing/app_motion.dart';
import 'package:bikesetupapp/common/theme/theme_data.dart';
import 'package:flutter/material.dart';

/// Forms always use the phone bottom-sheet presentation.
Future<T?> showAppSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool fullHeight = false,
  bool dismissible = true,
}) async {
  ModalRoute<dynamic>? sheetRoute;
  final result = await showModalBottomSheet<T>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    isDismissible: dismissible,
    enableDrag: dismissible,
    sheetAnimationStyle: MediaQuery.disableAnimationsOf(context)
        ? AnimationStyle.noAnimation
        : const AnimationStyle(
            duration: AppMotion.forward, reverseDuration: AppMotion.reverse),
    useSafeArea: true,
    backgroundColor: context.palette.surface,
    clipBehavior: Clip.antiAlias,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
    builder: (context) {
      sheetRoute = ModalRoute.of(context);
      return fullHeight
          ? LayoutBuilder(
              builder: (context, constraints) => SizedBox(
                  height: constraints.maxHeight, child: builder(context)))
          : SingleChildScrollView(child: Builder(builder: builder));
    },
  );
  await sheetRoute?.completed;
  return result;
}

/// Finish dismissing a sheet before changing the screen underneath it.
Future<void> dismissAppSheet(BuildContext context) async {
  final route = ModalRoute.of(context);
  Navigator.of(context).pop();
  await route?.completed;
}

/// Drag affordance shared by app sheets.
class AppSheetHandle extends StatelessWidget {
  const AppSheetHandle({super.key});

  @override
  Widget build(BuildContext context) => Center(
        child: Container(
          width: 36,
          height: 4,
          decoration: BoxDecoration(
            color: context.palette.borderStrong,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      );
}

/// Shared title rhythm for task sheets. The caller owns the outer padding.
class AppSheetHeader extends StatelessWidget {
  const AppSheetHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.action,
    this.showHandle = true,
  });

  final String title;
  final String? subtitle;
  final Widget? leading, action;
  final bool showHandle;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showHandle) ...[
            const AppSheetHandle(),
            const SizedBox(height: 20),
          ],
          Row(children: [
            if (leading != null) leading!,
            Expanded(
                child: Semantics(
                    header: true,
                    child: Text(title,
                        style: AppTextStyles.heading
                            .copyWith(color: context.palette.ink)))),
            if (action != null) action!,
          ]),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(subtitle!,
                style: AppTextStyles.body
                    .copyWith(color: context.palette.inkMuted)),
          ],
          const SizedBox(height: 24),
        ],
      );
}

EdgeInsets appSheetPadding(BuildContext context) => EdgeInsets.fromLTRB(
    24,
    16,
    24,
    MediaQuery.viewInsetsOf(context).bottom +
        MediaQuery.paddingOf(context).bottom +
        24);
