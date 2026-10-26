import 'package:flutter/cupertino.dart';
import 'package:bikesetupapp/features/bikes/models/new_bike_mode.dart';
import 'package:bikesetupapp/features/bikes/ui/bike_info_bottom_sheet.dart';
import 'package:bikesetupapp/features/bikes/ui/bike_list.dart';
import 'package:bikesetupapp/features/bikes/ui/new_bike_bottom_sheet.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

typedef BikeSelectionCallback = void Function(String, String, String, String);

Future<void> showBikeChooserSheet({
  required BuildContext context,
  required User user,
  required String selectedBikeId,
  required String selectedSetupId,
  required BikeSelectionCallback onBikeSelected,
}) {
  Widget content(BuildContext chooserContext) => BikeChooserContent(
        bikeList: BikeList(
          user: user,
          selectedBikeId: selectedBikeId,
          selectedSetupId: selectedSetupId,
          onBikeSelected: (name, bikeID, setupName, setupID) {
            if (!chooserContext.mounted ||
                ModalRoute.of(chooserContext)?.isCurrent != true) {
              return;
            }
            Navigator.of(chooserContext).pop();
            onBikeSelected(name, bikeID, setupName, setupID);
          },
          onSetupDetails: (name, bikeID, setupName, setupID) {
            if (!chooserContext.mounted ||
                ModalRoute.of(chooserContext)?.isCurrent != true) {
              return;
            }
            Navigator.of(chooserContext).pop();
            showBikeInfoSheet(context, user, bikeID, setupID, setupName, name,
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
  return showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    builder: (sheetContext) => ConstrainedBox(
        constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(sheetContext).height * .8),
        child: content(sheetContext)),
  );
}

class BikeChooserContent extends StatelessWidget {
  final Widget bikeList;
  final VoidCallback onAddBike;

  const BikeChooserContent(
      {super.key, required this.bikeList, required this.onAddBike});

  @override
  Widget build(BuildContext context) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                  child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                          color: Theme.of(context).dividerColor,
                          borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 20),
              Text('Bike & setup',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              Flexible(fit: FlexFit.loose, child: bikeList),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                  onPressed: onAddBike,
                  icon: const Icon(CupertinoIcons.plus, size: 20),
                  label: const Text('Add bike')),
            ],
          ),
        ),
      );
}
