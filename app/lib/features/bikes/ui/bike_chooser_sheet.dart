import 'package:bikesetupapp/app/routing/app_motion.dart';
import 'package:bikesetupapp/common/ui/app_sheet.dart';
import 'package:bikesetupapp/common/theme/theme_data.dart';
import 'package:bikesetupapp/common/ui/app_components.dart';
import 'package:bikesetupapp/common/ui/app_scroll_edge.dart';
import 'package:bikesetupapp/features/bikes/models/new_bike_mode.dart';
import 'package:bikesetupapp/features/bikes/ui/bike_info_bottom_sheet.dart';
import 'package:bikesetupapp/features/bikes/ui/bike_list.dart';
import 'package:bikesetupapp/features/bikes/ui/new_bike_bottom_sheet.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

typedef BikeSelectionCallback = void Function(String, String, String, String);

Future<void> showBikeChooserSheet({
  required BuildContext context,
  bool bikesOnly = false,
  required User user,
  required String selectedBikeId,
  required String selectedSetupId,
  required BikeSelectionCallback onBikeSelected,
  VoidCallback? onNoBikes,
}) {
  ModalRoute<dynamic>? chooserRoute;
  Future<void> closeChooser(BuildContext chooserContext) async {
    if (chooserContext.mounted && chooserRoute?.isCurrent == true) {
      await dismissAppSheet(chooserContext);
    } else if (chooserRoute?.isActive == false) {
      await chooserRoute?.completed;
    }
  }

  Widget content(BuildContext chooserContext) => BikeChooserContent(
        title: bikesOnly ? 'Choose a bike' : 'Bikes & setups',
        bikeList: BikeList(
          user: user,
          onDeletionStarted: () {
            final route = chooserRoute;
            // Confirmation owns the operation now. Remove the covered chooser
            // without animating an empty list back into view.
            if (route != null && route.isActive && !route.isCurrent) {
              route.navigator?.removeRoute(route);
            }
          },
          onNoBikes: () async {
            if (!context.mounted) return;
            ScaffoldMessenger.maybeOf(context)?.clearSnackBars();
            await closeChooser(chooserContext);
            if (context.mounted) onNoBikes?.call();
          },
          bikesOnly: bikesOnly,
          selectedBikeId: selectedBikeId,
          selectedSetupId: selectedSetupId,
          onBikeSelected: (name, bikeID, setupName, setupID) async {
            if (!context.mounted) return;
            // A confirmed deletion can finish after the chooser is dismissed.
            // Its replacement selection still belongs to the workspace.
            await closeChooser(chooserContext);
            if (context.mounted) {
              onBikeSelected(name, bikeID, setupName, setupID);
            }
          },
          onSetupDetails: (name, bikeID, setupName, setupID) async {
            if (!chooserContext.mounted ||
                ModalRoute.of(chooserContext)?.isCurrent != true) {
              return;
            }
            await closeChooser(chooserContext);
            if (!context.mounted) return;
            showBikeInfoSheet(context, user, bikeID, setupID, setupName, name,
                onBikeSelected: onBikeSelected);
          },
        ),
        onAddBike: () async {
          if (!chooserContext.mounted ||
              ModalRoute.of(chooserContext)?.isCurrent != true) {
            return;
          }
          await closeChooser(chooserContext);
          if (!context.mounted) return;
          showNewBikeSheet(context, user, NewBikeMode.newBike,
              onBikeSelected: onBikeSelected);
        },
      );

  return showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    sheetAnimationStyle: MediaQuery.disableAnimationsOf(context)
        ? AnimationStyle.noAnimation
        : const AnimationStyle(
            duration: AppMotion.forward, reverseDuration: AppMotion.reverse),
    builder: (sheetContext) {
      chooserRoute = ModalRoute.of(sheetContext);
      return ConstrainedBox(
          constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(sheetContext).height * .8),
          child: content(sheetContext));
    },
  );
}

class BikeChooserContent extends StatelessWidget {
  final String title;
  final Widget bikeList;
  final VoidCallback onAddBike;

  const BikeChooserContent(
      {super.key,
      this.title = 'Bikes & setups',
      required this.bikeList,
      required this.onAddBike});

  @override
  Widget build(BuildContext context) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppSheetHeader(title: title),
              Flexible(
                  fit: FlexFit.loose, child: AppScrollEdge(child: bikeList)),
              const SizedBox(height: 16),
              Divider(height: 1, color: context.palette.border),
              const SizedBox(height: 12),
              AppActionButton(
                  label: 'Add bike',
                  icon: Icons.add,
                  outlined: true,
                  onPressed: onAddBike),
            ],
          ),
        ),
      );
}
