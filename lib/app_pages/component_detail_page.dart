import 'package:bikesetupapp/alert_dialogs/dialog_helpers.dart';
import 'package:bikesetupapp/app_services/theme_data.dart';
import 'package:bikesetupapp/database_service/strava_api_service.dart';
import 'package:bikesetupapp/database_service/strava_auth_service.dart';
import 'package:bikesetupapp/database_service/service_database.dart';
import 'package:bikesetupapp/models/service_component.dart';
import 'package:bikesetupapp/models/service_entry.dart';
import 'package:bikesetupapp/widgets/service_status.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

class ComponentDetailPage extends StatefulWidget {
  final User user;
  final ServiceComponent component;
  final double currentMileageKm;

  /// Strava gear ID linked to this bike, or null if Strava isn't connected /
  /// the bike isn't linked. Used to estimate historical mileage.
  final String? stravaGearId;

  const ComponentDetailPage({
    super.key,
    required this.user,
    required this.component,
    required this.currentMileageKm,
    this.stravaGearId,
  });

  @override
  State<ComponentDetailPage> createState() => _ComponentDetailPageState();
}

class _ComponentDetailPageState extends State<ComponentDetailPage> {
  late ServiceDatabaseService _db;
  late int _intervalKm;
  static final NumberFormat _kmFormat = NumberFormat('#,###');

  @override
  void initState() {
    super.initState();
    _db = ServiceDatabaseService(widget.user.uid);
    _intervalKm = widget.component.serviceIntervalKm;
  }

  ServiceComponent get _component => _intervalKm == widget.component.serviceIntervalKm
      ? widget.component
      : ServiceComponent(
          id: widget.component.id,
          bikeId: widget.component.bikeId,
          type: widget.component.type,
          name: widget.component.name,
          serviceIntervalKm: _intervalKm,
          createdAt: widget.component.createdAt,
        );

  void _showLogServiceSheet() {
    final noteController = TextEditingController();
    DateTime selectedDate = DateTime.now();

    double? fetchedMileage =
        widget.stravaGearId != null ? widget.currentMileageKm : null;
    bool fetchingMileage = false;
    String? mileageError; // 'scope' | 'error' | null
    int fetchGeneration = 0;

    Future<void> fetchMileage(DateTime date, StateSetter setSheetState) async {
      if (widget.stravaGearId == null) return;

      final gen = ++fetchGeneration;
      setSheetState(() {
        fetchingMileage = true;
        fetchedMileage = null;
        mileageError = null;
      });

      final now = DateTime.now();
      final isToday = date.year == now.year &&
          date.month == now.month &&
          date.day == now.day;

      if (isToday) {
        if (gen == fetchGeneration) {
          setSheetState(() {
            fetchingMileage = false;
            fetchedMileage = widget.currentMileageKm;
          });
        }
        return;
      }

      try {
        final token = await StravaAuthService().getValidToken();
        if (gen != fetchGeneration) return;
        if (token == null) {
          setSheetState(() {
            fetchingMileage = false;
            mileageError = 'error';
          });
          return;
        }

        final km = await StravaApiService().fetchMileageAtDate(
          accessToken: token,
          gearId: widget.stravaGearId!,
          date: date,
          currentTotalKm: widget.currentMileageKm,
        );
        if (gen != fetchGeneration) return;

        if (km == null) {
          setSheetState(() {
            fetchingMileage = false;
            mileageError = 'error';
          });
          return;
        }

        setSheetState(() {
          fetchingMileage = false;
          fetchedMileage = km;
        });
      } on StravaInsufficientScopeException {
        if (gen != fetchGeneration) return;
        setSheetState(() {
          fetchingMileage = false;
          mileageError = 'scope';
        });
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.palette.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
        final p = ctx.palette;
        return StatefulBuilder(
          builder: (ctx, setSheetState) => Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 16,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: p.borderStrong,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'LOG SERVICE',
                  style: AppTextStyles.eyebrow(color: p.inkDim),
                ),
                const SizedBox(height: 14),
                _SheetFieldLabel(label: 'Date'),
                const SizedBox(height: 6),
                _SheetDateField(
                  date: selectedDate,
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: selectedDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setSheetState(() => selectedDate = picked);
                      fetchMileage(picked, setSheetState);
                    }
                  },
                ),
                if (widget.stravaGearId != null) ...[
                  const SizedBox(height: 10),
                  _buildMileageStatus(
                      ctx, fetchingMileage, fetchedMileage, mileageError),
                ],
                const SizedBox(height: 14),
                _SheetFieldLabel(label: 'Note'),
                const SizedBox(height: 6),
                TextField(
                  controller: noteController,
                  cursorColor: p.accent,
                  style: AppTextStyles.inter(size: 13, color: p.ink),
                  decoration: InputDecoration(
                    hintText: 'Optional — e.g. new chain, cleaned only',
                    hintStyle:
                        AppTextStyles.inter(size: 13, color: p.inkDim),
                    filled: true,
                    fillColor: p.surface2,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: p.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: p.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: p.accent),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: _SheetPrimaryButton(
                        label: 'Log service',
                        enabled: !fetchingMileage,
                        onPressed: () {
                          final note = noteController.text.trim();
                          final entry = ServiceEntry(
                            id: const Uuid().v4(),
                            componentId: widget.component.id,
                            mileageAtServiceKm: fetchedMileage,
                            date: selectedDate.toUtc(),
                            note: note.isNotEmpty ? note : null,
                          );
                          _db.addServiceEntry(widget.component.id, entry);
                          HapticFeedback.lightImpact();
                          Navigator.of(ctx).pop();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMileageStatus(
    BuildContext ctx,
    bool fetchingMileage,
    double? fetchedMileage,
    String? mileageError,
  ) {
    final p = ctx.palette;
    if (fetchingMileage) {
      return Row(
        children: [
          const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator.adaptive(strokeWidth: 2),
          ),
          const SizedBox(width: 8),
          Text(
            'Fetching from Strava…',
            style: AppTextStyles.inter(size: 11, color: p.inkMuted),
          ),
        ],
      );
    }

    if (mileageError == 'scope') {
      return Row(
        children: [
          Icon(Icons.warning_amber_rounded, size: 14, color: p.red),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'Re-connect Strava in settings to fetch mileage',
              style: AppTextStyles.inter(
                size: 11,
                weight: FontWeight.w600,
                color: p.red,
              ),
            ),
          ),
        ],
      );
    }

    if (mileageError == 'error') {
      return Row(
        children: [
          Icon(Icons.close_rounded, size: 14, color: p.red),
          const SizedBox(width: 6),
          Text(
            'Could not fetch mileage from Strava',
            style: AppTextStyles.inter(
              size: 11,
              weight: FontWeight.w600,
              color: p.red,
            ),
          ),
        ],
      );
    }

    if (fetchedMileage != null) {
      return Row(
        children: [
          Icon(Icons.route_rounded, size: 14, color: p.amber),
          const SizedBox(width: 6),
          Text(
            '${_kmFormat.format(fetchedMileage.round())} km at service',
            style: AppTextStyles.mono(
              size: 11,
              weight: FontWeight.w700,
              color: p.amber,
            ),
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }

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
    final overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
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
        stream: _db.getEntriesForComponent(widget.component.id),
        builder: (context, snapshot) {
          final loading = snapshot.connectionState == ConnectionState.waiting;
          final entries = snapshot.data ?? const <ServiceEntry>[];
          final latest = entries.isEmpty ? null : entries.first;
          final annotated = annotateService(
            component: _component,
            currentMileageKm: widget.currentMileageKm,
            latestEntry: latest,
          );

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 6, 14, 6),
                child: _StatusHero(
                  component: _component,
                  service: annotated,
                  hasEntries: entries.isNotEmpty,
                ),
              ),
              _HistoryHeader(count: entries.length),
              Expanded(
                child: loading
                    ? const Center(child: CircularProgressIndicator.adaptive())
                    : entries.isEmpty
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
      floatingActionButton: FloatingActionButton(
        onPressed: _showLogServiceSheet,
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Status hero
// ──────────────────────────────────────────────────────────────────────────────

class _StatusHero extends StatelessWidget {
  final ServiceComponent component;
  final AnnotatedService service;
  final bool hasEntries;

  const _StatusHero({
    required this.component,
    required this.service,
    required this.hasEntries,
  });

  String get _badgeLabel {
    switch (service.status) {
      case ServiceStatus.red:
        return 'DUE NOW';
      case ServiceStatus.amber:
        return 'SOON';
      case ServiceStatus.green:
        return 'HEALTHY';
      case ServiceStatus.unknown:
        return 'NO DATA';
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final color = service.status.color(p);
    final formatter = NumberFormat('#,###');
    final kmSince = formatter.format(service.kmSinceService.round());
    final interval = formatter.format(component.serviceIntervalKm);
    final remaining = service.remainingKm.round();
    final overdueBy = (service.kmSinceService - component.serviceIntervalKm)
        .clamp(0.0, double.infinity)
        .round();

    final isRed = service.status == ServiceStatus.red;
    final hasModel = component.name.trim().isNotEmpty &&
        component.name.trim() != component.type.label;

    return Container(
      decoration: BoxDecoration(
        color: p.surface,
        border: Border.all(color: isRed ? color : p.border),
        borderRadius: BorderRadius.circular(14),
        boxShadow: isRed
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.18),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: isRed ? 1.0 : 0.18),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(8),
                ),
              ),
              child: Text(
                _badgeLabel,
                style: AppTextStyles.inter(
                  size: 9,
                  weight: FontWeight.w800,
                  color: isRed ? Colors.white : color,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        iconForComponent(component.type.icon),
                        size: 20,
                        color: color,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            component.type.label,
                            style: AppTextStyles.inter(
                              size: 15,
                              weight: FontWeight.w700,
                              color: p.ink,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (hasModel)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                component.name,
                                style: AppTextStyles.inter(
                                  size: 11.5,
                                  color: p.inkMuted,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          const SizedBox(height: 4),
                          Text(
                            'Service every $interval km',
                            style: AppTextStyles.inter(
                              size: 10.5,
                              weight: FontWeight.w600,
                              color: p.inkDim,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 60),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      kmSince,
                      style: AppTextStyles.mono(
                        size: 30,
                        weight: FontWeight.w700,
                        color: color,
                        letterSpacing: -1,
                        height: 1,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '/ $interval km',
                      style: AppTextStyles.mono(
                        size: 13,
                        weight: FontWeight.w600,
                        color: p.inkDim,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  _statusSubline(
                    status: service.status,
                    remaining: remaining,
                    overdueBy: overdueBy,
                    lastServicedAt: service.lastServicedAt,
                    hasEntries: hasEntries,
                  ),
                  style: AppTextStyles.inter(
                    size: 11.5,
                    weight: FontWeight.w600,
                    color: service.status == ServiceStatus.red
                        ? color
                        : p.inkMuted,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: service.progress.clamp(0.0, 1.0),
                    minHeight: 5,
                    backgroundColor: p.surface2,
                    valueColor: AlwaysStoppedAnimation(color),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _statusSubline({
    required ServiceStatus status,
    required int remaining,
    required int overdueBy,
    required DateTime? lastServicedAt,
    required bool hasEntries,
  }) {
    if (status == ServiceStatus.unknown) {
      if (!hasEntries) return 'No service logged yet';
      return 'Last entry had no mileage';
    }
    final base = remaining > 0
        ? '${NumberFormat('#,###').format(remaining)} km remaining'
        : overdueBy > 0
            ? 'Overdue by ${NumberFormat('#,###').format(overdueBy)} km'
            : 'Due now';
    if (lastServicedAt == null) {
      return '$base · Never serviced';
    }
    final days = DateTime.now().difference(lastServicedAt).inDays;
    final agoText = days <= 0
        ? 'today'
        : days == 1
            ? 'yesterday'
            : '$days days ago';
    return '$base · Last serviced $agoText';
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
            'SERVICE HISTORY',
            style: AppTextStyles.inter(
              size: 10,
              weight: FontWeight.w700,
              color: p.ink,
              letterSpacing: 1.6,
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
            child: const Icon(Icons.delete_outline_rounded,
                color: Colors.white, size: 20),
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
    if (entry.mileageAtServiceKm != null &&
        prior?.mileageAtServiceKm != null) {
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
        padding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
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
            'Tap + to record the first service',
            style: AppTextStyles.inter(size: 11.5, color: p.inkDim),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Bottom sheet helpers
// ──────────────────────────────────────────────────────────────────────────────

class _SheetFieldLabel extends StatelessWidget {
  final String label;
  const _SheetFieldLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Text(
      label.toUpperCase(),
      style: AppTextStyles.inter(
        size: 9.5,
        weight: FontWeight.w700,
        color: p.inkDim,
        letterSpacing: 1.4,
      ),
    );
  }
}

class _SheetDateField extends StatelessWidget {
  final DateTime date;
  final VoidCallback onTap;
  const _SheetDateField({required this.date, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Material(
      color: p.surface2,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: p.border),
          ),
          child: Row(
            children: [
              Icon(Icons.calendar_today_rounded, size: 14, color: p.inkMuted),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  DateFormat('MMM d, yyyy').format(date),
                  style: AppTextStyles.inter(
                    size: 13,
                    weight: FontWeight.w600,
                    color: p.ink,
                  ),
                ),
              ),
              Icon(Icons.expand_more_rounded, size: 16, color: p.inkDim),
            ],
          ),
        ),
      ),
    );
  }
}

class _SheetPrimaryButton extends StatelessWidget {
  final String label;
  final bool enabled;
  final VoidCallback onPressed;
  const _SheetPrimaryButton({
    required this.label,
    required this.enabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final bg = enabled ? p.accent : p.surface2;
    final fg = enabled ? p.accentInk : p.inkDim;
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(11),
      child: InkWell(
        onTap: enabled ? onPressed : null,
        borderRadius: BorderRadius.circular(11),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Center(
            child: Text(
              label.toUpperCase(),
              style: AppTextStyles.inter(
                size: 12,
                weight: FontWeight.w800,
                color: fg,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
