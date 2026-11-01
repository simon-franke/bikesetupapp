import 'package:bikesetupapp/common/ui/app_haptics.dart';
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
import 'package:flutter/material.dart';

class BikeList extends StatefulWidget {
  final User? user;
  final bool bikesOnly;
  final String selectedBikeId;
  final String selectedSetupId;
  final void Function(String, String, String, String) onSetupDetails;
  final void Function(String, String, String, String) onBikeSelected;

  const BikeList({
    super.key,
    required this.user,
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
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(p.accent),
            ),
          );
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
          padding: const EdgeInsets.only(top: 16),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final bike = docs[index];
            final active = bike.id == widget.selectedBikeId;
            final expanded = _expandedBikeId == bike.id;
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
              expanded: expanded,
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
    final confirmed = await showDeleteConfirmationSheet(
      context,
      title: 'Delete ${bike.name}?',
      actionLabel: 'Delete',
      message: 'This permanently removes this bike and its saved data.',
    );
    if (confirmed && mounted) {
      final replaceSelection = bike.id == widget.selectedBikeId;
      final onBikeSelected = widget.onBikeSelected;
      final controller =
          AppDependencies.of(context).forUser(widget.user!.uid).bikes;
      return presentCommand(context, () async {
        final result = await controller.deleteBike(bike.id);
        if (result.isSuccess && replaceSelection) {
          final selection = result.requireValue();
          if (selection != null) {
            onBikeSelected(selection.bikeName, selection.bikeId,
                selection.setupName, selection.setupId);
          }
        }
        return result;
      });
    }
    return confirmed;
  }
}

class _BikeCard extends StatelessWidget {
  final Bike bike;
  final User user;
  final String? selectedSetupId;
  final void Function(String, String, String, String) onSetupDetails;
  final bool expanded;
  final VoidCallback onToggleExpand;
  final void Function(String, String, String, String) onSelectSetup;
  final Future<bool> Function() onConfirmDeleteBike;

  const _BikeCard({
    required this.bike,
    required this.user,
    required this.selectedSetupId,
    required this.onSetupDetails,
    required this.expanded,
    required this.onToggleExpand,
    required this.onSelectSetup,
    required this.onConfirmDeleteBike,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final details = Visibility(
        visible: expanded,
        maintainState: true,
        child: Column(children: [
          _SetupsList(
              user: user,
              bike: bike,
              onSelectSetup: onSelectSetup,
              selectedSetupId: selectedSetupId,
              onSetupDetails: onSetupDetails),
        ]));
    return Material(
      key: Key(bike.id),
      color: expanded ? p.bg : Colors.transparent,
      borderRadius: BorderRadius.circular(24),
      clipBehavior: Clip.antiAlias,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        InkWell(
          onTap: AppHaptics.wrap(onToggleExpand, selection: true),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
            child: Row(children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(bike.name,
                        style: AppTextStyles.label.copyWith(color: p.ink)),
                  ],
                ),
              ),
              if (expanded)
                AppObjectMenu(
                    tooltip: 'Bike options',
                    title: bike.name,
                    deleteLabel: 'Delete bike',
                    onDelete: () {
                      onConfirmDeleteBike();
                    },
                    onRename: () =>
                        BikeAlerts.renameBike(context, bike.id, bike.name)),
              Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: AnimatedRotation(
                      turns: expanded ? .25 : 0,
                      duration: MediaQuery.disableAnimationsOf(context)
                          ? Duration.zero
                          : const Duration(milliseconds: 240),
                      curve: Curves.easeInOutCubic,
                      child: Icon(CupertinoIcons.chevron_right,
                          size: AppIconSizes.compact, color: p.inkMuted))),
            ]),
          ),
        ),
        if (MediaQuery.disableAnimationsOf(context))
          details
        else
          AnimatedSize(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeInOutCubic,
            alignment: Alignment.topCenter,
            child: details,
          ),
      ]),
    );
  }
}

class _SetupsList extends StatefulWidget {
  final User user;
  final String? selectedSetupId;
  final void Function(String, String, String, String) onSetupDetails;
  final Bike bike;

  final void Function(String, String, String, String) onSelectSetup;

  const _SetupsList({
    required this.user,
    required this.selectedSetupId,
    required this.onSetupDetails,
    required this.bike,
    required this.onSelectSetup,
  });

  @override
  State<_SetupsList> createState() => _SetupsListState();
}

class _SetupsListState extends State<_SetupsList> {
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
  void didUpdateWidget(_SetupsList oldWidget) {
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
            child: Center(
                child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2))),
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
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
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
