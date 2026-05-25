import 'package:bikesetupapp/alert_dialogs/bike_alert_dialogs.dart';
import 'package:bikesetupapp/app_services/theme_data.dart';
import 'package:bikesetupapp/bike_enums/bike_type.dart';
import 'package:bikesetupapp/bike_enums/new_bike_mode.dart';
import 'package:bikesetupapp/database_service/database.dart';
import 'package:bikesetupapp/models/bike.dart';
import 'package:bikesetupapp/models/bike_setup.dart';
import 'package:bikesetupapp/widgets/new_bike_bottom_sheet.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class BikeList extends StatefulWidget {
  final User? user;
  final String bikeName;
  final void Function(String, String, BikeType, String, String) onBikeSelected;
  const BikeList({
    super.key,
    required this.user,
    required this.bikeName,
    required this.onBikeSelected,
  });

  @override
  State<BikeList> createState() => _BikeListState();
}

class _BikeListState extends State<BikeList> {
  late Stream _bikesStream;
  final Map<String, Stream> _setupStreams = {};
  String? _expandedBikeId;
  bool _didInitExpansion = false;

  @override
  void initState() {
    super.initState();
    if (widget.user != null) {
      _bikesStream = DatabaseService(widget.user!.uid).getBikes();
    }
  }

  Stream _setupStreamFor(String bikeId) {
    return _setupStreams.putIfAbsent(
        bikeId, () => DatabaseService(widget.user!.uid).getSetups(bikeId));
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    if (widget.user == null) {
      return Center(
        child: Text(
          'No User',
          style: AppTextStyles.inter(size: 12, color: p.inkMuted),
        ),
      );
    }
    return StreamBuilder(
      stream: _bikesStream,
      builder: (context, AsyncSnapshot snapshot) {
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
              style: AppTextStyles.inter(size: 12, color: p.red),
            ),
          );
        }
        if (snapshot.data == null || snapshot.data.docs.isEmpty) {
          return Center(
            child: Text(
              'No bikes',
              style: AppTextStyles.inter(size: 12, color: p.inkMuted),
            ),
          );
        }
        final docs = snapshot.data.docs;
        if (!_didInitExpansion) {
          _didInitExpansion = true;
          for (final d in docs) {
            final b = Bike.fromSnapshot(d);
            if (b.name == widget.bikeName) {
              _expandedBikeId = b.id;
              break;
            }
          }
        }
        return ListView.separated(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final bike = Bike.fromSnapshot(docs[index]);
            final active = bike.name == widget.bikeName;
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
    final defaultBikeId = await DatabaseService(widget.user!.uid).getDefaultBike();
    if (!mounted) return false;
    if (bike.id == defaultBikeId) {
      BikeAlerts.deleteError(context, 'Default Bike');
      return false;
    }
    if (!mounted) return false;
    final confirmed = await _confirmDestructive(
      context,
      title: 'Delete bike',
      message: 'Are you sure you want to delete "${bike.name}"? This cannot be undone.',
    );
    if (confirmed && mounted) {
      try {
        DatabaseService(widget.user!.uid).deleteBike(bike.id);
      } catch (_) {
        BikeAlerts.generalError(context, 'Error deleting bike');
      }
    }
    return confirmed;
  }
}

class _BikeCard extends StatelessWidget {
  final Bike bike;
  final User user;
  final bool active;
  final bool expanded;
  final Stream setupStream;
  final VoidCallback onToggleExpand;
  final void Function(String, String, BikeType, String, String) onSelectSetup;
  final Future<bool> Function() onConfirmDeleteBike;

  const _BikeCard({
    required this.bike,
    required this.user,
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
    final bikeType = BikeType.fromString(bike.bikeType);
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Dismissible(
      key: Key(bike.id),
      direction: DismissDirection.endToStart,
      background: Container(
        decoration: BoxDecoration(
          color: p.red,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 18),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
      ),
      confirmDismiss: (_) => onConfirmDeleteBike(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: active ? p.surface2 : Colors.transparent,
          border: Border.all(color: active ? p.borderStrong : p.border),
          borderRadius: BorderRadius.circular(12),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onToggleExpand,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 11, 8, 11),
                  child: Row(
                    children: [
                      Container(
                        width: 32, height: 32,
                        decoration: BoxDecoration(
                          color: p.bg,
                          border: Border.all(color: p.border),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Center(
                          child: SizedBox(
                            width: 26, height: 18,
                            child: ColorFiltered(
                              colorFilter: isLight
                                  ? const ColorFilter.matrix(<double>[
                                      0.18, 0, 0, 0, 0,
                                      0, 0.18, 0, 0, 0,
                                      0, 0, 0.18, 0, 0,
                                      0, 0, 0, 0.9, 0,
                                    ])
                                  : const ColorFilter.matrix(<double>[
                                      -1, 0, 0, 0, 255,
                                      0, -1, 0, 0, 255,
                                      0, 0, -1, 0, 255,
                                      0, 0, 0, 1, 0,
                                    ]),
                              child: Image.asset(bikeType.path, fit: BoxFit.contain),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeOut,
                              style: AppTextStyles.inter(
                                size: 13, weight: FontWeight.w700,
                                color: active ? p.accent : p.ink,
                              ),
                              child: Text(
                                bike.name,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              bikeType == BikeType.error ? '—' : bikeType.bikeType,
                              style: AppTextStyles.inter(
                                size: 10, weight: FontWeight.w600,
                                color: p.inkDim, letterSpacing: 0.6,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => BikeAlerts.renameBike(context, bike.id, bike.name),
                        constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                        padding: EdgeInsets.zero,
                        icon: Icon(Icons.edit_outlined, size: 16, color: p.inkMuted),
                      ),
                      AnimatedRotation(
                        turns: expanded ? 0 : -0.25,
                        duration: const Duration(milliseconds: 150),
                        child: Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: p.inkMuted),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 220),
              sizeCurve: Curves.easeOutCubic,
              firstCurve: Curves.easeOut,
              secondCurve: Curves.easeIn,
              alignment: Alignment.topCenter,
              firstChild: Column(
                children: [
                  Divider(height: 1, color: p.border),
                  _SetupsList(
                    user: user,
                    bike: bike,
                    bikeType: bikeType,
                    setupStream: setupStream,
                    onSelectSetup: onSelectSetup,
                  ),
                ],
              ),
              secondChild: const SizedBox(width: double.infinity, height: 0),
              crossFadeState: expanded
                  ? CrossFadeState.showFirst
                  : CrossFadeState.showSecond,
            ),
          ],
        ),
      ),
    );
  }
}

class _SetupsList extends StatelessWidget {
  final User user;
  final Bike bike;
  final BikeType bikeType;
  final Stream setupStream;
  final void Function(String, String, BikeType, String, String) onSelectSetup;

  const _SetupsList({
    required this.user,
    required this.bike,
    required this.bikeType,
    required this.setupStream,
    required this.onSelectSetup,
  });

  Future<bool> _confirmDeleteSetup(BuildContext context, String setupId, int total) async {
    if (total <= 1) {
      BikeAlerts.deleteError(context, 'Setup');
      return false;
    }
    final defaultSetupId = await DatabaseService(user.uid).getDefaultSetup(bike.id);
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
      try {
        DatabaseService(user.uid).deleteSetup(bike.id, setupId);
      } catch (_) {
        BikeAlerts.generalError(context, 'Error deleting setup');
      }
    }
    return confirmed;
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    if (bikeType == BikeType.error) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          'Something went wrong',
          style: AppTextStyles.inter(size: 11, color: p.red),
        ),
      );
    }
    return StreamBuilder(
      stream: setupStream,
      builder: (context, AsyncSnapshot snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(12),
            child: Center(child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))),
          );
        }
        if (snap.hasError || snap.data == null) {
          return Padding(
            padding: const EdgeInsets.all(12),
            child: Text('No setups', style: AppTextStyles.inter(size: 11, color: p.inkDim)),
          );
        }
        final docs = snap.data.docs;
        return Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 8, 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final d in docs)
                _SetupRow(
                  setup: BikeSetup.fromSnapshot(d),
                  user: user,
                  bike: bike,
                  bikeType: bikeType,
                  onSelect: onSelectSetup,
                  onConfirmDelete: () => _confirmDeleteSetup(context, BikeSetup.fromSnapshot(d).id, docs.length),
                ),
              _NewSetupRow(
                onTap: () {
                  showNewBikeSheet(
                    context, user, NewBikeMode.newSetup,
                    bikeType: bikeType,
                    uBikeID: bike.id,
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
  final User user;
  final Bike bike;
  final BikeType bikeType;
  final void Function(String, String, BikeType, String, String) onSelect;
  final Future<bool> Function() onConfirmDelete;

  const _SetupRow({
    required this.setup,
    required this.user,
    required this.bike,
    required this.bikeType,
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
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
      ),
      confirmDismiss: (_) => onConfirmDelete(),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            DatabaseService(user.uid).setDefaultBike(bike.id);
            DatabaseService(user.uid).setDefaultSetup(bike.id, setup.id);
            final scaffold = Scaffold.maybeOf(context);
            if (scaffold?.isDrawerOpen == true) scaffold!.closeDrawer();
            onSelect(bike.name, bike.id, bikeType, setup.name, setup.id);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            child: Row(
              children: [
                Container(
                  width: 4, height: 4,
                  decoration: BoxDecoration(
                    color: p.inkDim,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    setup.name,
                    style: AppTextStyles.inter(
                      size: 12, weight: FontWeight.w500, color: p.ink,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  onPressed: () {
                    showNewBikeSheet(
                      context, user, NewBikeMode.editSetup,
                      bikeType: bikeType,
                      uBikeID: bike.id,
                      bikeName: bike.name,
                      uSetupID: setup.id,
                      setupName: setup.name,
                      onBikeSelected: onSelect,
                    );
                  },
                  constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
                  padding: EdgeInsets.zero,
                  icon: Icon(Icons.edit_outlined, size: 13, color: p.inkDim),
                ),
              ],
            ),
          ),
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
    final p = context.palette;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              Icon(Icons.add_rounded, size: 12, color: p.accent),
              const SizedBox(width: 6),
              Text(
                'NEW SETUP',
                style: AppTextStyles.inter(
                  size: 11, weight: FontWeight.w700,
                  color: p.accent, letterSpacing: 0.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
          style: AppTextStyles.inter(size: 16, weight: FontWeight.w700, color: p.ink),
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
                size: 12, weight: FontWeight.w700, color: p.inkMuted, letterSpacing: 0.5,
              ),
            ),
          ),
          Material(
            color: p.red,
            borderRadius: BorderRadius.circular(9),
            child: InkWell(
              onTap: () => Navigator.of(ctx).pop(true),
              borderRadius: BorderRadius.circular(9),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                child: Text(
                  'DELETE',
                  style: AppTextStyles.inter(
                    size: 11, weight: FontWeight.w800,
                    color: Colors.white, letterSpacing: 0.6,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    },
  );
  return result ?? false;
}
