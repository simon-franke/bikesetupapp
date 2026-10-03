import 'package:bikesetupapp/common/layout/responsive_layout.dart';
import 'package:bikesetupapp/common/theme/theme_data.dart';
import 'package:flutter/material.dart';

/// Forms use a centered, keyboard-aware dialog on wide windows.
Future<T?> showAdaptiveModal<T>({
  required BuildContext context,
  required WidgetBuilder builder,
}) {
  if (!ResponsiveLayout.isWide(context)) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: context.palette.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: builder,
    );
  }
  return showDialog<T>(
    context: context,
    builder: (dialogContext) => Dialog(
      backgroundColor: dialogContext.palette.surface,
      insetPadding: const EdgeInsets.all(24),
      constraints: const BoxConstraints(maxWidth: 560),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: 560,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 8, right: 8),
                child: IconButton(
                  tooltip: 'Close dialog',
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  icon: const Icon(Icons.close),
                ),
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                child: MediaQuery.removeViewInsets(
                  context: dialogContext,
                  removeBottom: true,
                  child: Builder(builder: builder),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// A drag affordance belongs only to the phone sheet presentation.
class AppSheetHandle extends StatelessWidget {
  const AppSheetHandle({super.key});

  @override
  Widget build(BuildContext context) => ResponsiveLayout.isWide(context)
      ? const SizedBox.shrink()
      : Center(
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
