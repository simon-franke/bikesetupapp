import 'package:bikesetupapp/common/ui/app_loading.dart';
import 'dart:async';
import 'package:bikesetupapp/common/ui/app_error_banner.dart';
import 'package:bikesetupapp/common/ui/delete_confirmation_sheet.dart';
import 'package:flutter/cupertino.dart';
import 'package:bikesetupapp/common/ui/command_feedback.dart';
import 'package:bikesetupapp/app/app_dependencies.dart';
import 'package:bikesetupapp/common/ui/app_components.dart';
import 'package:bikesetupapp/features/bikes/ui/bike_alert_dialogs.dart';
import 'package:bikesetupapp/common/theme/theme_data.dart';
import 'package:bikesetupapp/features/bikes/models/new_bike_mode.dart';
import 'package:bikesetupapp/features/bikes/models/bike.dart';
import 'package:bikesetupapp/features/setups/models/bike_setup.dart';
import 'package:bikesetupapp/features/bikes/ui/new_bike_bottom_sheet.dart';
import 'package:bikesetupapp/features/bikes/ui/setup_choice_tile.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BikeSetupList extends StatefulWidget {
  final User user;
  final String? selectedSetupId;
  final void Function(String, String, String, String) onSetupDetails;
  final Bike bike;

  final void Function(String, String, String, String) onSelectSetup;

  const BikeSetupList({
    super.key,
    required this.user,
    required this.selectedSetupId,
    required this.onSetupDetails,
    required this.bike,
    required this.onSelectSetup,
  });

  @override
  State<BikeSetupList> createState() => _BikeSetupListState();
}

class _BikeSetupListState extends State<BikeSetupList> {
  late Stream<List<BikeSetup>> _stream;

  User get user => widget.user;
  Bike get bike => widget.bike;
  String? get selectedSetupId => widget.selectedSetupId;
  void Function(String, String, String, String) get onSelectSetup =>
      widget.onSelectSetup;
  void Function(String, String, String, String) get onSetupDetails =>
      widget.onSetupDetails;

  @override
  void initState() {
    super.initState();
    _connect();
  }

  void _connect() {
    _stream =
        AppDependencies.of(context).forUser(user.uid).setups.getSetups(bike.id);
  }

  @override
  void didUpdateWidget(BikeSetupList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.bike.id != bike.id || oldWidget.user.uid != user.uid) {
      _connect();
    }
  }

  Future<bool> _confirmDeleteSetup(
      BuildContext context, String setupId, int total) async {
    if (total <= 1) {
      BikeAlerts.deleteError(context, 'Setup');
      return false;
    }

    final defaultSetupId = await AppDependencies.of(context)
        .forUser(user.uid)
        .setups
        .getDefaultSetup(bike.id);
    if (!context.mounted) return false;

    if (setupId == defaultSetupId) {
      BikeAlerts.deleteError(context, 'Default Setup');
      return false;
    }

    if (!context.mounted) return false;

    final confirmed = await showDeleteConfirmationSheet(
      context,
      title: 'Delete setup',
      message: 'Are you sure you want to delete this setup?',
    );
    if (confirmed && context.mounted) {
      return presentCommand(
          context,
          () => AppDependencies.of(context)
              .forUser(user.uid)
              .setups
              .deleteSetup(bike.id, setupId));
    }

    return confirmed;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: _stream,
      builder: (context, AsyncSnapshot<List<BikeSetup>> snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(12),
            child: Center(child: AppLoadingContent(label: 'Loading setups…')),
          );
        }

        if (snap.hasError) {
          return Padding(
            padding: const EdgeInsets.all(12),
            child: AppErrorBanner(
              message: 'Couldn’t load setups.',
              onRetry: () => setState(_connect),
            ),
          );
        }

        final docs = snap.data ?? <BikeSetup>[];

        return Padding(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final d in docs)
                _SetupRow(
                  setup: d,
                  user: user,
                  bike: bike,
                  onSelect: onSelectSetup,
                  isSelected: d.id == selectedSetupId,
                  onSetupDetails: onSetupDetails,
                  onConfirmDelete: () =>
                      _confirmDeleteSetup(context, d.id, docs.length),
                ),
              _NewSetupRow(
                onTap: () {
                  showNewBikeSheet(
                    context,
                    user,
                    NewBikeMode.newSetup,
                    uBikeID: bike.id,
                    uSetupID: selectedSetupId ?? docs.firstOrNull?.id ?? '',
                    bikeName: bike.name,
                    onBikeSelected: onSelectSetup,
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SetupRow extends StatelessWidget {
  final BikeSetup setup;
  final bool isSelected;
  final void Function(String, String, String, String) onSetupDetails;
  final User user;
  final Bike bike;

  final void Function(String, String, String, String) onSelect;
  final Future<bool> Function() onConfirmDelete;

  const _SetupRow({
    required this.setup,
    required this.isSelected,
    required this.onSetupDetails,
    required this.user,
    required this.bike,
    required this.onSelect,
    required this.onConfirmDelete,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Dismissible(
      key: Key('setup_${setup.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        color: p.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 18),
        child: Icon(CupertinoIcons.trash, color: AppColors.onColor(p.red)),
      ),
      confirmDismiss: (_) => onConfirmDelete(),
      child: SetupChoiceTile(
        name: setup.name,
        isSelected: isSelected,
        onSelect: () async {
          final db = AppDependencies.of(context).forUser(user.uid);
          final selected = await presentCommand(
              context, () => db.bikes.selectSetup(bike.id, setup.id));
          if (!context.mounted || !selected) return;
          onSelect(bike.name, bike.id, setup.name, setup.id);
        },
        onDetails: () =>
            onSetupDetails(bike.name, bike.id, setup.name, setup.id),
        onEdit: () => showNewBikeSheet(
          context,
          user,
          NewBikeMode.editSetup,
          uBikeID: bike.id,
          bikeName: bike.name,
          uSetupID: setup.id,
          setupName: setup.name,
          onBikeSelected: onSelect,
        ),
      ),
    );
  }
}

class _NewSetupRow extends StatelessWidget {
  final VoidCallback onTap;

  const _NewSetupRow({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AppAddButton(label: 'Add setup', onPressed: onTap);
  }
}
