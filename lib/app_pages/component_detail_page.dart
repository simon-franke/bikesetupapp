import 'package:bikesetupapp/database_service/strava_api_service.dart';
import 'package:bikesetupapp/database_service/strava_auth_service.dart';
import 'package:bikesetupapp/database_service/service_database.dart';
import 'package:bikesetupapp/models/service_component.dart';
import 'package:bikesetupapp/models/service_entry.dart';
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

  @override
  void initState() {
    super.initState();
    _db = ServiceDatabaseService(widget.user.uid);
  }

  void _showLogServiceSheet() {
    final noteController = TextEditingController();
    DateTime selectedDate = DateTime.now();

    // Mileage is fetched automatically from Strava — never typed by the user.
    // null = no Strava link or fetch failed; fetching = in progress.
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

      // For today just use the already-synced total — no extra API call.
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
      backgroundColor: Theme.of(context).cardTheme.color,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 32,
            right: 32,
            top: 28,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 28,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(ctx)
                        .textTheme
                        .labelSmall
                        ?.color
                        ?.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'LOG SERVICE',
                style: Theme.of(ctx).textTheme.labelSmall?.copyWith(
                      letterSpacing: 1.5,
                      fontSize: 11,
                    ),
              ),
              const SizedBox(height: 16),
              // ── Date picker ───────────────────────────────────────────────
              GestureDetector(
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
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      width: 2,
                      color: Theme.of(ctx).textTheme.labelMedium?.color ??
                          Theme.of(ctx).colorScheme.onSurface,
                    ),
                  ),
                  child: Text(
                    DateFormat('MMM d, yyyy').format(selectedDate),
                    style: Theme.of(ctx).textTheme.labelLarge,
                  ),
                ),
              ),
              // ── Strava mileage status (auto, read-only) ───────────────────
              if (widget.stravaGearId != null) ...[
                const SizedBox(height: 10),
                _buildMileageStatus(
                    ctx, fetchingMileage, fetchedMileage, mileageError),
              ],
              const SizedBox(height: 12),
              // ── Note ──────────────────────────────────────────────────────
              TextField(
                controller: noteController,
                decoration: InputDecoration(
                  hintText: 'Note (optional)',
                  hintStyle: Theme.of(ctx).textTheme.labelSmall,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      width: 2,
                      color: Theme.of(ctx).textTheme.labelMedium?.color ??
                          Theme.of(ctx).colorScheme.onSurface,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      width: 2,
                      color: Theme.of(ctx).textTheme.labelMedium?.color ??
                          Theme.of(ctx).colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(ctx)
                        .floatingActionButtonTheme
                        .backgroundColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: fetchingMileage
                      ? null
                      : () {
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
                  child: Text(
                    'Log Service',
                    style: Theme.of(ctx).textTheme.labelLarge,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMileageStatus(
    BuildContext ctx,
    bool fetchingMileage,
    double? fetchedMileage,
    String? mileageError,
  ) {
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
            style: Theme.of(ctx).textTheme.labelSmall,
          ),
        ],
      );
    }

    if (mileageError == 'scope') {
      return Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              size: 14, color: Color(0xFFE05545)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'Re-connect Strava in settings to fetch mileage',
              style: Theme.of(ctx).textTheme.labelSmall?.copyWith(
                    color: const Color(0xFFE05545),
                  ),
            ),
          ),
        ],
      );
    }

    if (mileageError == 'error') {
      return Row(
        children: [
          const Icon(Icons.close, size: 14, color: Color(0xFFE05545)),
          const SizedBox(width: 6),
          Text(
            'Could not fetch mileage from Strava',
            style: Theme.of(ctx).textTheme.labelSmall?.copyWith(
                  color: const Color(0xFFE05545),
                ),
          ),
        ],
      );
    }

    if (fetchedMileage != null) {
      return Row(
        children: [
          const Icon(Icons.route, size: 14, color: Color(0xFFD4883A)),
          const SizedBox(width: 6),
          Text(
            '${fetchedMileage.round().toString()} km at service',
            style: Theme.of(ctx).textTheme.labelSmall?.copyWith(
                  color: const Color(0xFFD4883A),
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  Future<void> _confirmDeleteEntry(ServiceEntry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(ctx).cardTheme.color,
        title: Text('Delete Entry',
            style: Theme.of(ctx).textTheme.titleLarge),
        content: const Text('Are you sure you want to delete this service entry?'),
        actionsAlignment: MainAxisAlignment.spaceAround,
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  Theme.of(ctx).floatingActionButtonTheme.backgroundColor,
            ),
            onPressed: () => Navigator.of(ctx).pop(false),
            child:
                Text('Cancel', style: Theme.of(ctx).textTheme.labelLarge),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE05545),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child:
                Text('Delete', style: Theme.of(ctx).textTheme.labelLarge),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _db.deleteServiceEntry(widget.component.id, entry.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,###');

    return Scaffold(
      appBar: AppBar(
        scrolledUnderElevation: 0,
        title: Text(
          widget.component.type.label,
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.component.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Service every ${formatter.format(widget.component.serviceIntervalKm)} km',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  'SERVICE HISTORY',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        letterSpacing: 1.5,
                        fontSize: 11,
                      ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<ServiceEntry>>(
              stream: _db.getEntriesForComponent(widget.component.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator.adaptive());
                }
                final entries = snapshot.data ?? [];
                if (entries.isEmpty) {
                  return Center(
                    child: Text(
                      'No service entries yet',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  itemCount: entries.length,
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    return Dismissible(
                      key: Key(entry.id),
                      direction: DismissDirection.endToStart,
                      confirmDismiss: (_) async {
                        await _confirmDeleteEntry(entry);
                        return false;
                      },
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        color: const Color(0xFFE05545),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      child: ListTile(
                        title: Text(
                          entry.mileageAtServiceKm != null
                              ? '${formatter.format(entry.mileageAtServiceKm!.round())} km'
                              : '— km',
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                        subtitle: entry.note != null && entry.note!.isNotEmpty
                            ? Text(
                                entry.note!,
                                style: Theme.of(context).textTheme.labelSmall,
                              )
                            : null,
                        trailing: Text(
                          DateFormat('MMM d, yyyy').format(entry.date),
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showLogServiceSheet,
        child: const Icon(Icons.add),
      ),
    );
  }
}
