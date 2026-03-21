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

  const ComponentDetailPage({
    super.key,
    required this.user,
    required this.component,
    required this.currentMileageKm,
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
    final mileageController = TextEditingController(
        text: widget.currentMileageKm.round().toString());
    final noteController = TextEditingController();
    DateTime selectedDate = DateTime.now();

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
              TextField(
                controller: mileageController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Mileage (km)',
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
              const SizedBox(height: 12),
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
                  }
                },
                child: Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
              const SizedBox(height: 12),
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
                  onPressed: () {
                    final mileage =
                        double.tryParse(mileageController.text.trim()) ??
                            widget.currentMileageKm;
                    final note = noteController.text.trim();
                    final entryId = const Uuid().v4();

                    final entry = ServiceEntry(
                      id: entryId,
                      componentId: widget.component.id,
                      mileageAtServiceKm: mileage,
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
                          '${formatter.format(entry.mileageAtServiceKm.round())} km',
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
