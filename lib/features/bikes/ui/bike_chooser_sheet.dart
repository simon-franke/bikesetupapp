import 'package:bikesetupapp/common/layout/responsive_layout.dart';
import 'package:bikesetupapp/features/bikes/models/bike_type.dart';
import 'package:bikesetupapp/features/bikes/models/new_bike_mode.dart';
import 'package:bikesetupapp/features/bikes/ui/bike_info_bottom_sheet.dart';
import 'package:bikesetupapp/features/bikes/ui/bike_list.dart';
import 'package:bikesetupapp/features/bikes/ui/new_bike_bottom_sheet.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

typedef BikeSelectionCallback = void Function(
    String, String, BikeType, String, String);

Future<void> showBikeChooserSheet({
  required BuildContext context,
  required User user,
  required String selectedBikeId,
  required String selectedSetupId,
  required BikeSelectionCallback onBikeSelected,
}) {
  final compact = ResponsiveLayout.isWide(context);
  Widget content(BuildContext chooserContext) => BikeChooserContent(
        compact: compact,
        bikeList: BikeList(
          compact: compact,
          user: user,
          selectedBikeId: selectedBikeId,
          selectedSetupId: selectedSetupId,
          onBikeSelected: (name, bikeID, type, setupName, setupID) {
            if (!chooserContext.mounted ||
                ModalRoute.of(chooserContext)?.isCurrent != true) {
              return;
            }
            Navigator.of(chooserContext).pop();
            onBikeSelected(name, bikeID, type, setupName, setupID);
          },
          onSetupDetails: (name, bikeID, type, setupName, setupID) {
            if (!chooserContext.mounted ||
                ModalRoute.of(chooserContext)?.isCurrent != true) {
              return;
            }
            Navigator.of(chooserContext).pop();
            showBikeInfoSheet(
                context, user, bikeID, setupID, setupName, name, type,
                onBikeSelected: onBikeSelected);
          },
        ),
        onAddBike: () {
          if (!chooserContext.mounted ||
              ModalRoute.of(chooserContext)?.isCurrent != true) {
            return;
          }
          Navigator.of(chooserContext).pop();
          showNewBikeSheet(context, user, NewBikeMode.newBike,
              onBikeSelected: onBikeSelected);
        },
      );
  if (compact) {
    return showDialog<void>(
        context: context,
        builder: (dialogContext) => Dialog(
              insetPadding: const EdgeInsets.all(24),
              constraints: BoxConstraints(
                  maxWidth: 560,
                  maxHeight: MediaQuery.sizeOf(dialogContext).height * .8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              clipBehavior: Clip.antiAlias,
              child: SizedBox(width: 560, child: content(dialogContext)),
            ));
  }
  return showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    constraints: const BoxConstraints(maxWidth: 560),
    builder: (sheetContext) =>
        FractionallySizedBox(heightFactor: .8, child: content(sheetContext)),
  );
}

class BikeChooserContent extends StatelessWidget {
  final Widget bikeList;
  final VoidCallback onAddBike;
  final bool compact;

  const BikeChooserContent(
      {super.key,
      required this.bikeList,
      required this.onAddBike,
      this.compact = false});

  @override
  Widget build(BuildContext context) => SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.all(compact ? 24 : 16),
          child: Column(
            mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!compact) ...[
                Center(
                    child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                            color: Theme.of(context).dividerColor,
                            borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 20),
              ],
              Row(children: [
                Expanded(
                    child: Text('Bikes & setups',
                        style: Theme.of(context).textTheme.titleLarge)),
                if (compact)
                  IconButton(
                      tooltip: 'Close bike chooser',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close)),
              ]),
              const SizedBox(height: 16),
              if (compact)
                Flexible(fit: FlexFit.loose, child: bikeList)
              else
                Expanded(child: bikeList),
              const SizedBox(height: 20),
              Align(
                  alignment: compact ? Alignment.centerRight : Alignment.center,
                  child: SizedBox(
                      width: compact ? null : double.infinity,
                      child: FilledButton.icon(
                          onPressed: onAddBike,
                          icon: const Icon(Icons.add, size: 20),
                          label: const Text('Add bike')))),
            ],
          ),
        ),
      );
}
