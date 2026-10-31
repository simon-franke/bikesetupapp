import 'package:bikesetupapp/common/theme/theme_data.dart';
import 'package:flutter/material.dart';

/// Forms always use the phone bottom-sheet presentation.
Future<T?> showAppSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool fullHeight = false,
}) {
  return showModalBottomSheet<T>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    sheetAnimationStyle: MediaQuery.disableAnimationsOf(context)
        ? AnimationStyle.noAnimation
        : const AnimationStyle(
            duration: Duration(milliseconds: 280),
            reverseDuration: Duration(milliseconds: 220)),
    useSafeArea: true,
    backgroundColor: context.palette.surface,
    clipBehavior: Clip.antiAlias,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
    builder: (context) => fullHeight
        ? LayoutBuilder(
            builder: (context, constraints) => SizedBox(
                height: constraints.maxHeight, child: builder(context)))
        : SingleChildScrollView(child: Builder(builder: builder)),
  );
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
