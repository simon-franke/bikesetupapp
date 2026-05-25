import 'dart:async';

import 'package:flutter/material.dart';
import 'package:bikesetupapp/database_service/service_database.dart';
import 'package:bikesetupapp/models/service_component.dart';
import 'package:bikesetupapp/models/service_entry.dart';
import 'package:bikesetupapp/widgets/service_component_card.dart';

class ServiceComponentsList extends StatelessWidget {
  final String userID;
  final String bikeId;
  final double currentMileageKm;
  final void Function(ServiceComponent component)? onComponentTap;
  final void Function(bool hasAlert)? onAlertChanged;

  const ServiceComponentsList({
    super.key,
    required this.userID,
    required this.bikeId,
    required this.currentMileageKm,
    this.onComponentTap,
    this.onAlertChanged,
  });

  @override
  Widget build(BuildContext context) {
    final db = ServiceDatabaseService(userID);

    return StreamBuilder<List<ServiceComponent>>(
      stream: db.getComponentsForBike(bikeId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator.adaptive());
        }

        final components = snapshot.data ?? [];

        if (components.isEmpty) {
          return _buildEmptyState(context);
        }

        return _ComponentListWithEntries(
          db: db,
          components: components,
          currentMileageKm: currentMileageKm,
          onComponentTap: onComponentTap,
          onAlertChanged: onAlertChanged,
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.build_outlined,
              size: 48,
              color: Colors.white.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No components tracked yet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap + to add your first component\nand start tracking service intervals',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ComponentListWithEntries extends StatefulWidget {
  final ServiceDatabaseService db;
  final List<ServiceComponent> components;
  final double currentMileageKm;
  final void Function(ServiceComponent component)? onComponentTap;
  final void Function(bool hasAlert)? onAlertChanged;

  const _ComponentListWithEntries({
    required this.db,
    required this.components,
    required this.currentMileageKm,
    this.onComponentTap,
    this.onAlertChanged,
  });

  @override
  State<_ComponentListWithEntries> createState() =>
      _ComponentListWithEntriesState();
}

class _ComponentListWithEntriesState extends State<_ComponentListWithEntries> {
  final Map<String, ServiceEntry?> _latestEntries = {};
  final Map<String, StreamSubscription<ServiceEntry?>> _subs = {};
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _subscribe(widget.components);
  }

  @override
  void didUpdateWidget(_ComponentListWithEntries oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Re-subscribe only when the set of tracked components changes.
    final oldIds = oldWidget.components.map((c) => c.id).toSet();
    final newIds = widget.components.map((c) => c.id).toSet();
    if (oldIds != newIds) {
      _cancelAll();
      _subscribe(widget.components);
    }
  }

  @override
  void dispose() {
    _cancelAll();
    super.dispose();
  }

  void _cancelAll() {
    for (final sub in _subs.values) {
      sub.cancel();
    }
    _subs.clear();
  }

  void _subscribe(List<ServiceComponent> components) {
    if (components.isEmpty) {
      if (mounted) setState(() => _loaded = true);
      return;
    }

    final targetIds = components.map((c) => c.id).toSet();

    for (final comp in components) {
      final sub = widget.db
          .streamLatestEntryForComponent(comp.id)
          .listen((entry) {
        if (!mounted) return;
        setState(() {
          _latestEntries[comp.id] = entry;
          // Mark loaded once every component has emitted at least once.
          if (!_loaded &&
              targetIds.every((id) => _latestEntries.containsKey(id))) {
            _loaded = true;
          }
        });
        _checkAlert();
      });
      _subs[comp.id] = sub;
    }
  }

  void _checkAlert() {
    if (widget.onAlertChanged == null) return;
    bool hasAlert = false;
    for (final comp in widget.components) {
      final entry = _latestEntries[comp.id];
      // Skip components with unknown mileage — we can't assess their status.
      if (entry != null && entry.mileageAtServiceKm == null) continue;
      final kmSince = entry?.mileageAtServiceKm != null
          ? (widget.currentMileageKm - entry!.mileageAtServiceKm!)
              .clamp(0.0, double.infinity)
          : widget.currentMileageKm;
      final progress =
          comp.serviceIntervalKm > 0 ? kmSince / comp.serviceIntervalKm : 0.0;
      if (progress >= 0.9) {
        hasAlert = true;
        break;
      }
    }
    widget.onAlertChanged!(hasAlert);
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Center(child: CircularProgressIndicator.adaptive());
    }

    // Sort by progress descending
    final sorted = List<ServiceComponent>.from(widget.components);
    sorted.sort((a, b) {
      final aEntry = _latestEntries[a.id];
      final bEntry = _latestEntries[b.id];

      double entryProgress(ServiceComponent comp, ServiceEntry? entry) {
        // Unknown-mileage entries sort to the bottom (progress = -1).
        if (entry != null && entry.mileageAtServiceKm == null) return -1.0;
        final km = entry?.mileageAtServiceKm != null
            ? (widget.currentMileageKm - entry!.mileageAtServiceKm!)
                .clamp(0.0, double.infinity)
            : widget.currentMileageKm;
        return comp.serviceIntervalKm > 0 ? km / comp.serviceIntervalKm : 0.0;
      }

      return entryProgress(b, bEntry).compareTo(entryProgress(a, aEntry));
    });

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sorted.length,
      itemBuilder: (context, index) {
        final comp = sorted[index];
        return ServiceComponentCard(
          component: comp,
          currentMileageKm: widget.currentMileageKm,
          latestEntry: _latestEntries[comp.id],
          onTap: widget.onComponentTap != null
              ? () => widget.onComponentTap!(comp)
              : null,
        );
      },
    );
  }
}
