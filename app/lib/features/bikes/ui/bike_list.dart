import 'bike_setup_list.dart';
import 'package:bikesetupapp/common/ui/app_loading.dart';
import 'dart:async';
import 'package:bikesetupapp/common/ui/app_haptics.dart';
import 'package:bikesetupapp/common/ui/delete_confirmation_sheet.dart';
import 'package:flutter/cupertino.dart';
import 'package:bikesetupapp/common/ui/command_feedback.dart';
import 'package:bikesetupapp/app/app_dependencies.dart';
import 'package:bikesetupapp/common/ui/app_components.dart';
import 'package:bikesetupapp/features/bikes/ui/bike_alert_dialogs.dart';
import 'package:bikesetupapp/common/theme/theme_data.dart';
import 'package:bikesetupapp/features/bikes/models/bike.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class BikeList extends StatefulWidget {
  final FutureOr<void> Function()? onNoBikes;
  final VoidCallback? onDeletionStarted;
  final User? user;
  final bool bikesOnly;
  final String selectedBikeId;
  final String selectedSetupId;
  final void Function(String, String, String, String) onSetupDetails;
  final FutureOr<void> Function(String, String, String, String) onBikeSelected;

  const BikeList({
    super.key,
    required this.user,
    this.onNoBikes,
    this.onDeletionStarted,
    this.bikesOnly = false,
    required this.selectedBikeId,
    required this.selectedSetupId,
    required this.onSetupDetails,
    required this.onBikeSelected,
  });

  @override
  State<BikeList> createState() => _BikeListState();
}

class _BikeListState extends State<BikeList> {
  late Stream<List<Bike>> _bikesStream;

  @override
  void initState() {
    super.initState();
    if (widget.user != null) {
      _bikesStream = AppDependencies.of(context)
          .forUser(widget.user!.uid)
          .bikes
          .getBikes();
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    if (widget.user == null) {
      return Center(
        child: Text(
          'No User',
          style: AppTextStyles.caption.copyWith(color: p.inkMuted),
        ),
      );
    }

    return StreamBuilder(
      stream: _bikesStream,
      builder: (context, AsyncSnapshot<List<Bike>> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: AppLoadingState(label: 'Loading bikes…'));
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error',
              style: AppTextStyles.caption.copyWith(color: p.red),
            ),
          );
        }

        if (snapshot.data == null || snapshot.data!.isEmpty) {
          return Center(
            child: Text(
              'No bikes',
              style: AppTextStyles.caption.copyWith(color: p.inkMuted),
            ),
          );
        }

        final docs = [
          ...snapshot.data!.where((bike) => bike.id == widget.selectedBikeId),
          ...snapshot.data!.where((bike) => bike.id != widget.selectedBikeId),
        ];

        return ListView.separated(
          shrinkWrap: true,
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 24),
          itemBuilder: (context, index) {
            final bike = docs[index];
            final active = bike.id == widget.selectedBikeId;
            if (widget.bikesOnly) {
              return Material(
                color: active ? p.bg : Colors.transparent,
                borderRadius: BorderRadius.circular(24),
                clipBehavior: Clip.antiAlias,
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                  title: Text(bike.name,
                      style: AppTextStyles.label.copyWith(color: p.ink)),
                  selected: active,
                  trailing: active
                      ? Icon(CupertinoIcons.check_mark,
                          color: p.accentText, size: AppIconSizes.control)
                      : null,
                  onTap: () async {
                    AppHaptics.selection();
                    final controller = AppDependencies.of(context)
                        .forUser(widget.user!.uid)
                        .bikes;
                    String setupId = '', setupName = '';
                    final success = await presentCommand(context, () async {
                      final result = await controller.selectBike(bike.id);
                      if (result.isSuccess) {
                        final setup = result.requireValue();
                        setupId = setup.id;
                        setupName = setup.name;
                      }
                      return result;
                    });
                    if (!context.mounted || !success) return;

                    widget.onBikeSelected(
                        bike.name, bike.id, setupName, setupId);
                  },
                ),
              );
            }

            return _BikeCard(
              bike: bike,
              user: widget.user!,
              onSelectSetup: widget.onBikeSelected,
              selectedSetupId: active ? widget.selectedSetupId : null,
              onSetupDetails: widget.onSetupDetails,
              onConfirmDeleteBike: () => _confirmDeleteBike(bike),
            );
          },
        );
      },
    );
  }

  Future<bool> _confirmDeleteBike(Bike bike) async {
    final replaceSelection = bike.id == widget.selectedBikeId;
    final onBikeSelected = widget.onBikeSelected;
    final onNoBikes = widget.onNoBikes;
    final onDeletionStarted = widget.onDeletionStarted;
    final controller =
        AppDependencies.of(context).forUser(widget.user!.uid).bikes;

    return showDeleteConfirmationSheet(
      context,
      title: 'Delete ${bike.name}?',
      actionLabel: 'Delete',
      message: 'This permanently removes this bike and its saved data.',
      onConfirm: () {
        onDeletionStarted?.call();
        return controller.deleteBike(bike.id);
      },
      onConfirmed: (selection) async {
        if (replaceSelection) {
          if (selection != null) {
            await onBikeSelected(selection.bikeName, selection.bikeId,
                selection.setupName, selection.setupId);
          } else {
            await onNoBikes?.call();
          }
        }
      },
    );
  }
}

class _BikeCard extends StatelessWidget {
  final Bike bike;
  final User user;
  final String? selectedSetupId;
  final void Function(String, String, String, String) onSetupDetails;
  final void Function(String, String, String, String) onSelectSetup;
  final Future<bool> Function() onConfirmDeleteBike;

  const _BikeCard({
    required this.bike,
    required this.user,
    required this.selectedSetupId,
    required this.onSetupDetails,
    required this.onSelectSetup,
    required this.onConfirmDeleteBike,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Column(
      key: Key(bike.id),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(children: [
          Expanded(
              child: Semantics(
                  header: true,
                  child: Text(bike.name,
                      style: AppTextStyles.label.copyWith(color: p.ink)))),
          AppObjectMenu(
              tooltip: 'Bike options',
              title: bike.name,
              deleteLabel: 'Delete bike',
              onDelete: () {
                onConfirmDeleteBike();
              },
              onRename: () =>
                  BikeAlerts.renameBike(context, bike.id, bike.name)),
        ]),
        BikeSetupList(
            user: user,
            bike: bike,
            onSelectSetup: onSelectSetup,
            selectedSetupId: selectedSetupId,
            onSetupDetails: onSetupDetails),
      ],
    );
  }
}
