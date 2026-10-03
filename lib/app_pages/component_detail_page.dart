import 'package:bikesetupapp/alert_dialogs/dialog_helpers.dart';
import 'package:bikesetupapp/app_services/theme_data.dart';
import 'package:bikesetupapp/database_service/service_database.dart';
import 'package:bikesetupapp/models/service_component.dart';
import 'package:bikesetupapp/models/service_entry.dart';
import 'package:bikesetupapp/widgets/log_service_sheet.dart';
import 'package:bikesetupapp/widgets/service_component_card.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class ComponentDetailPage extends StatefulWidget {
  final User user;
  final ServiceComponent component;
  final double currentMileageKm;
  final bool mileageAvailable;

  /// Strava gear ID linked to this bike, or null if Strava isn't connected /
  /// the bike isn't linked. Used to estimate historical mileage.
  final String? stravaGearId;

  const ComponentDetailPage({
    super.key,
    required this.user,
    required this.component,
    required this.currentMileageKm,
    this.mileageAvailable = true,
    this.stravaGearId,
  });

  @override
  State<ComponentDetailPage> createState() => _ComponentDetailPageState();
}

class _ComponentDetailPageState extends State<ComponentDetailPage> {
  late ServiceDatabaseService _db;
  late int _intervalKm;
  late Stream<List<ServiceEntry>> _entriesStream;
  static final NumberFormat _kmFormat = NumberFormat('#,###');

  @override
  void initState() {
    super.initState();
    _db = ServiceDatabaseService(widget.user.uid);
    _intervalKm = widget.component.serviceIntervalKm;
    _entriesStream = _db.getEntriesForComponent(widget.component.id);
  }

  ServiceComponent get _component =>
      _intervalKm == widget.component.serviceIntervalKm
          ? widget.component
          : ServiceComponent(
              id: widget.component.id,
              bikeId: widget.component.bikeId,
              type: widget.component.type,
              name: widget.component.name,
              serviceIntervalKm: _intervalKm,
              createdAt: widget.component.createdAt,
            );

  Future<void> _editInterval() async {
    final controller = TextEditingController(
      text: _intervalKm.toString(),
    );
    final saved = await showDialog<int>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => WorkshopDialog(
        title: 'Edit service interval',
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'How many kilometers between services for '
              '${widget.component.type.label.toLowerCase()}?',
            ),
            const SizedBox(height: 12),
            DialogTextField(
              controller: controller,
              hint: 'Service interval (km)',
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          DialogSecondaryButton(
            label: 'Cancel',
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          DialogPrimaryButton(
            label: 'Save',
            onPressed: () {
              final parsed = int.tryParse(controller.text.trim());
              if (parsed == null || parsed <= 0) return;
              Navigator.of(ctx).pop(parsed);
            },
          ),
        ],
      ),
    );
    if (saved != null && saved != _intervalKm) {
      await _db.updateComponent(
        widget.component.id,
        serviceIntervalKm: saved,
      );
      if (mounted) {
        setState(() => _intervalKm = saved);
        HapticFeedback.lightImpact();
      }
    }
  }

  Future<void> _confirmDeleteComponent() async {
    final p = context.palette;
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => WorkshopDialog(
        title: 'Delete component?',
        content: Text(
          'This permanently removes ${widget.component.type.label} and all its '
          'service history. This cannot be undone.',
        ),
        actions: [
          DialogSecondaryButton(
            label: 'Cancel',
            onPressed: () => Navigator.of(ctx).pop(false),
          ),
          DialogPrimaryButton(
            label: 'Delete',
            color: p.red,
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _db.deleteComponent(widget.component.id);
      HapticFeedback.mediumImpact();
      if (mounted) Navigator.of(context).pop();
    }
  }

  Future<void> _confirmDeleteEntry(ServiceEntry entry) async {
    final p = context.palette;
    final mileageText = entry.mileageAtServiceKm != null
        ? '${_kmFormat.format(entry.mileageAtServiceKm!.round())} km'
        : 'this';
    final dateText = DateFormat('MMM d, yyyy').format(entry.date);
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => WorkshopDialog(
        title: 'Delete entry?',
        content: Text(
          'This permanently removes the $mileageText service from $dateText.',
        ),
        actions: [
          DialogSecondaryButton(
            label: 'Cancel',
            onPressed: () => Navigator.of(ctx).pop(false),
          ),
          DialogPrimaryButton(
            label: 'Delete',
            color: p.red,
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _db.deleteServiceEntry(widget.component.id, entry.id);
      HapticFeedback.mediumImpact();
    }
  }

  Future<void> _showEntryContextMenu(
    Offset globalPosition,
    ServiceEntry entry,
  ) async {
    final p = context.palette;
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final result = await showMenu<String>(
      context: context,
      color: p.surface,
      position: RelativeRect.fromLTRB(
        globalPosition.dx,
        globalPosition.dy,
        overlay.size.width - globalPosition.dx,
        overlay.size.height - globalPosition.dy,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: p.border),
      ),
      items: [
        PopupMenuItem<String>(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_outline_rounded, size: 16, color: p.red),
              const SizedBox(width: 10),
              Text(
                'Delete entry',
                style: AppTextStyles.inter(
                  size: 13,
                  weight: FontWeight.w600,
                  color: p.ink,
                ),
              ),
            ],
          ),
        ),
      ],
    );
    if (result == 'delete') {
      await _confirmDeleteEntry(entry);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Scaffold(
      appBar: AppBar(
        scrolledUnderElevation: 0,
        title: Text(
          widget.component.type.label,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        actions: [
          PopupMenuButton<String>(
            color: p.surface,
            tooltip: 'Component options',
            icon: Icon(Icons.more_vert_rounded, color: p.ink),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: p.border),
            ),
            onSelected: (value) {
              if (value == 'edit_interval') {
                _editInterval();
              } else if (value == 'delete') {
                _confirmDeleteComponent();
              }
            },
            itemBuilder: (ctx) => [
              PopupMenuItem<String>(
                value: 'edit_interval',
                child: Row(
                  children: [
                    Icon(Icons.tune_rounded, size: 16, color: p.ink),
                    const SizedBox(width: 10),
                    Text(
                      'Edit interval',
                      style: AppTextStyles.inter(
                        size: 13,
                        weight: FontWeight.w600,
                        color: p.ink,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline_rounded, size: 16, color: p.red),
                    const SizedBox(width: 10),
                    Text(
                      'Delete component',
                      style: AppTextStyles.inter(
                        size: 13,
                        weight: FontWeight.w600,
                        color: p.red,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: StreamBuilder<List<ServiceEntry>>(
        stream: _entriesStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Text('Could not load service history.'),
                TextButton(
                  onPressed: () => setState(() {
                    _entriesStream =
                        _db.getEntriesForComponent(widget.component.id);
                  }),
                  child: const Text('Try again'),
                ),
              ]),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator.adaptive());
          }
          final entries = snapshot.data ?? const <ServiceEntry>[];
          final latest = entries.isEmpty ? null : entries.first;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: ServiceComponentCard(
                  component: _component,
                  currentMileageKm: widget.currentMileageKm,
                  latestEntry: latest,
                  mileageAvailable: widget.mileageAvailable,
                ),
              ),
              _HistoryHeader(count: entries.length),
              Expanded(
                child: entries.isEmpty
                    ? const _EmptyHistory()
                    : _HistoryList(
                        entries: entries,
                        onDelete: _confirmDeleteEntry,
                        onContextMenu: _showEntryContextMenu,
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showLogServiceSheet(
          context: context,
          userID: widget.user.uid,
          component: widget.component,
          currentMileageKm: widget.currentMileageKm,
          stravaGearId: widget.mileageAvailable ? widget.stravaGearId : null,
        ),
        icon: const Icon(Icons.check),
        label: const Text('Log service'),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// History
// ──────────────────────────────────────────────────────────────────────────────

class _HistoryHeader extends StatelessWidget {
  final int count;
  const _HistoryHeader({required this.count});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
      child: Row(
        children: [
          Text(
            'Service history',
            style: AppTextStyles.inter(
              size: 14,
              weight: FontWeight.w600,
              color: p.ink,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$count',
            style: AppTextStyles.inter(
              size: 10,
              weight: FontWeight.w700,
              color: p.inkDim,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: Container(height: 1, color: p.border)),
        ],
      ),
    );
  }
}

class _HistoryList extends StatelessWidget {
  final List<ServiceEntry> entries;
  final Future<void> Function(ServiceEntry) onDelete;
  final Future<void> Function(Offset, ServiceEntry) onContextMenu;

  const _HistoryList({
    required this.entries,
    required this.onDelete,
    required this.onContextMenu,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 96),
      itemCount: entries.length,
      separatorBuilder: (_, __) => Divider(
        height: 1,
        thickness: 1,
        color: p.border,
        indent: 18,
        endIndent: 18,
      ),
      itemBuilder: (context, index) {
        final entry = entries[index];
        final prior = index + 1 < entries.length ? entries[index + 1] : null;
        return Dismissible(
          key: Key(entry.id),
          direction: DismissDirection.endToStart,
          confirmDismiss: (_) async {
            await onDelete(entry);
            return false;
          },
          background: Container(
            color: p.red,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 22),
            child: Icon(Icons.delete_outline_rounded,
                color: AppColors.onColor(p.red), size: 20),
          ),
          child: _HistoryRow(
            entry: entry,
            prior: prior,
            ordinal: entries.length - index,
            onContextMenu: onContextMenu,
          ),
        );
      },
    );
  }
}

class _HistoryRow extends StatelessWidget {
  final ServiceEntry entry;
  final ServiceEntry? prior;
  final int ordinal;
  final Future<void> Function(Offset, ServiceEntry) onContextMenu;

  const _HistoryRow({
    required this.entry,
    required this.prior,
    required this.ordinal,
    required this.onContextMenu,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final formatter = NumberFormat('#,###');
    final mileageText = entry.mileageAtServiceKm != null
        ? '${formatter.format(entry.mileageAtServiceKm!.round())} km'
        : '— km';

    String? deltaText;
    if (entry.mileageAtServiceKm != null && prior?.mileageAtServiceKm != null) {
      final delta =
          (entry.mileageAtServiceKm! - prior!.mileageAtServiceKm!).round();
      if (delta > 0) {
        deltaText = '+${formatter.format(delta)} km since prior';
      }
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onLongPressStart: (details) =>
          onContextMenu(details.globalPosition, entry),
      onSecondaryTapDown: (details) =>
          onContextMenu(details.globalPosition, entry),
      child: Container(
        color: p.bg,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 28,
              child: Text(
                '#$ordinal',
                style: AppTextStyles.mono(
                  size: 10,
                  weight: FontWeight.w600,
                  color: p.inkDim,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mileageText,
                    style: AppTextStyles.mono(
                      size: 14,
                      weight: FontWeight.w700,
                      color: p.ink,
                    ),
                  ),
                  if (deltaText != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        deltaText,
                        style: AppTextStyles.mono(
                          size: 10,
                          weight: FontWeight.w500,
                          color: p.inkDim,
                        ),
                      ),
                    ),
                  if (entry.note != null && entry.note!.trim().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        entry.note!,
                        style: AppTextStyles.inter(
                          size: 11.5,
                          color: p.inkMuted,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(
              DateFormat('MMM d, yyyy').format(entry.date),
              style: AppTextStyles.inter(
                size: 11,
                weight: FontWeight.w600,
                color: p.inkMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: p.surface,
              border: Border.all(color: p.border),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.history_rounded, size: 24, color: p.inkDim),
          ),
          const SizedBox(height: 14),
          Text(
            'No service logged yet',
            style: AppTextStyles.inter(
              size: 13,
              weight: FontWeight.w700,
              color: p.ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Use Log service to record the first service',
            style: AppTextStyles.inter(size: 11.5, color: p.inkDim),
          ),
        ],
      ),
    );
  }
}
