import 'package:bikesetupapp/common/ui/bike_icon.dart';
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
import 'package:flutter/material.dart';

class BikeList extends StatefulWidget {
  final User? user;
  final String selectedBikeId;
  final String selectedSetupId;
  final void Function(String, String, String, String) onSetupDetails;
  final void Function(String, String, String, String) onBikeSelected;
  final bool compact;

  const BikeList({
    super.key,
    required this.user,
    this.compact = false,
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
  final Map<String, Stream<List<BikeSetup>>> _setupStreams = {};
  String? _expandedBikeId;
  bool _didInitExpansion = false;

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

  Stream<List<BikeSetup>> _setupStreamFor(String bikeId) {
    return _setupStreams.putIfAbsent(
        bikeId,
        () => AppDependencies.of(context)
            .forUser(widget.user!.uid)
            .setups
            .getSetups(bikeId));
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    if (widget.user == null) {
      return Center(
        heightFactor: widget.compact ? 1 : null,
        child: Text(
          'No User',
          style: AppTextStyles.inter(size: 12, color: p.inkMuted),
        ),
      );
    }
    return StreamBuilder(
      stream: _bikesStream,
      builder: (context, AsyncSnapshot<List<Bike>> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            heightFactor: widget.compact ? 1 : null,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(p.accent),
            ),
          );
        }
        if (snapshot.hasError) {
          return Center(
            heightFactor: widget.compact ? 1 : null,
            child: Text(
              'Error',
              style: AppTextStyles.inter(size: 12, color: p.red),
            ),
          );
        }
        if (snapshot.data == null || snapshot.data!.isEmpty) {
          return Center(
            heightFactor: widget.compact ? 1 : null,
            child: Text(
              'No bikes',
              style: AppTextStyles.inter(size: 12, color: p.inkMuted),
            ),
          );
        }
        final docs = [
          ...snapshot.data!.where((bike) => bike.id == widget.selectedBikeId),
          ...snapshot.data!.where((bike) => bike.id != widget.selectedBikeId),
        ];
        if (!_didInitExpansion) {
          _didInitExpansion = true;
          for (final d in docs) {
            final b = d;
            if (b.id == widget.selectedBikeId) {
              _expandedBikeId = b.id;
              break;
            }
          }
        }
        return ListView.separated(
          shrinkWrap: true,
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final bike = docs[index];
            final active = bike.id == widget.selectedBikeId;
            final expanded = _expandedBikeId == bike.id;
            return _BikeCard(
              bike: bike,
              user: widget.user!,
              active: active,
              expanded: expanded,
              setupStream: _setupStreamFor(bike.id),
              onToggleExpand: () => setState(
                () => _expandedBikeId = expanded ? null : bike.id,
              ),
              onSelectSetup: widget.onBikeSelected,
              selectedSetupId: active ? widget.selectedSetupId : null,
              onSetupDetails: widget.onSetupDetails,
              onConfirmDeleteBike: () => _confirmDeleteBike(bike, docs.length),
            );
          },
        );
      },
    );
  }

  Future<bool> _confirmDeleteBike(Bike bike, int total) async {
    if (total <= 1) {
      BikeAlerts.deleteError(context, 'Bike');
      return false;
    }
    final defaultBikeId = await AppDependencies.of(context)
        .forUser(widget.user!.uid)
        .bikes
        .getDefaultBike();
    if (!mounted) return false;
    if (bike.id == defaultBikeId) {
      BikeAlerts.deleteError(context, 'Default Bike');
      return false;
    }
    if (!mounted) return false;
    final confirmed = await _confirmDestructive(
      context,
      title: 'Delete bike',
      message:
          'Are you sure you want to delete "${bike.name}"? This cannot be undone.',
    );
    if (confirmed && mounted) {
      return presentCommand(
          context,
          () => AppDependencies.of(context)
              .forUser(widget.user!.uid)
              .bikes
              .deleteBike(bike.id));
    }
    return confirmed;
  }
}

class _BikeCard extends StatelessWidget {
  final Bike bike;
  final User user;
  final String? selectedSetupId;
  final void Function(String, String, String, String) onSetupDetails;
  final bool active;
  final bool expanded;
  final Stream<List<BikeSetup>> setupStream;
  final VoidCallback onToggleExpand;
  final void Function(String, String, String, String) onSelectSetup;
  final Future<bool> Function() onConfirmDeleteBike;

  const _BikeCard({
    required this.bike,
    required this.user,
    required this.selectedSetupId,
    required this.onSetupDetails,
    required this.active,
    required this.expanded,
    required this.setupStream,
    required this.onToggleExpand,
    required this.onSelectSetup,
    required this.onConfirmDeleteBike,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Dismissible(
        key: Key(bike.id),
        direction: DismissDirection.endToStart,
        confirmDismiss: (_) => onConfirmDeleteBike(),
        background: Container(
            color: p.red,
            alignment: Alignment.centerRight,
            child: Icon(CupertinoIcons.trash, color: AppColors.onColor(p.red))),
        child: Container(
          decoration: BoxDecoration(
              color: expanded ? p.bg : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: p.border)),
          clipBehavior: Clip.antiAlias,
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
            InkWell(
              onTap: onToggleExpand,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
                child: Row(children: [
                  BikeIcon(size: 24, color: p.inkMuted),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(bike.name,
                            style: AppTextStyles.inter(
                                size: 15, weight: FontWeight.w600, color: p.ink)),
                      ],
                    ),
                  ),
                  if (expanded)
                    IconButton(
                        tooltip: 'Rename bike',
                        icon: const Icon(CupertinoIcons.pencil, size: 17),
                        onPressed: () => BikeAlerts.renameBike(context, bike.id, bike.name)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: AnimatedRotation(
                        turns: expanded ? .25 : 0,
                        duration: MediaQuery.disableAnimationsOf(context)
                            ? Duration.zero : const Duration(milliseconds: 240),
                        curve: Curves.easeInOutCubic,
                        child: Icon(CupertinoIcons.chevron_right,
                            size: 15, color: p.inkMuted))),
                ]),
              ),
            ),
            AnimatedSize(
              duration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero : const Duration(milliseconds: 240),
              curve: Curves.easeInOutCubic,
              alignment: Alignment.topCenter,
              child: Visibility(
                visible: expanded,
                maintainState: true,
                child: Column(children: [
              Divider(height: 1, indent: 14, endIndent: 14, color: p.border),
              _SetupsList(
                  user: user,
                  bike: bike,

                  setupStream: setupStream,
                  onSelectSetup: onSelectSetup,
                  selectedSetupId: selectedSetupId,
                  onSetupDetails: onSetupDetails),
              ])),
            ),
          ]),
        ));
  }
}

class _SetupsList extends StatelessWidget {
  final User user;
  final String? selectedSetupId;
  final void Function(String, String, String, String) onSetupDetails;
  final Bike bike;

  final Stream<List<BikeSetup>> setupStream;
  final void Function(String, String, String, String) onSelectSetup;

  const _SetupsList({
    required this.user,
    required this.selectedSetupId,
    required this.onSetupDetails,
    required this.bike,

    required this.setupStream,
    required this.onSelectSetup,
  });

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
    final confirmed = await _confirmDestructive(
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
    final p = context.palette;
    return StreamBuilder(
      stream: setupStream,
      builder: (context, AsyncSnapshot<List<BikeSetup>> snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(12),
            child: Center(
                child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2))),
          );
        }
        if (snap.hasError || snap.data == null) {
          return Padding(
            padding: const EdgeInsets.all(12),
            child: Text('No setups',
                style: AppTextStyles.inter(size: 11, color: p.inkDim)),
          );
        }
        final docs = snap.data!;
        return Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 8, 6),
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
        child:
            Icon(CupertinoIcons.trash, color: AppColors.onColor(p.red)),
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
    return Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
            onPressed: onTap,
            style: TextButton.styleFrom(
                foregroundColor: context.palette.inkMuted,
                textStyle: AppTextStyles.inter(size: 12, weight: FontWeight.w500)),
            icon: const Icon(CupertinoIcons.plus, size: 15),
            label: const Text('Add setup')));
  }
}

Future<bool> _confirmDestructive(
  BuildContext context, {
  required String title,
  required String message,
}) async {
  final p = context.palette;
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      return AlertDialog(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: p.border),
        ),
        title: Text(
          title,
          style: AppTextStyles.inter(
              size: 16, weight: FontWeight.w700, color: p.ink),
        ),
        content: Text(
          message,
          style: AppTextStyles.inter(size: 13, color: p.inkMuted),
        ),
        actionsAlignment: MainAxisAlignment.spaceBetween,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Cancel',
              style: AppTextStyles.inter(
                size: 12,
                weight: FontWeight.w700,
                color: p.inkMuted,
                letterSpacing: 0.5,
              ),
            ),
          ),
          AppActionButton(
              label: 'Delete',
              color: p.red,
              onPressed: () => Navigator.of(ctx).pop(true)),
        ],
      );
    },
  );
  return result ?? false;
}
