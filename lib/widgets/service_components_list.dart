import 'dart:async';

import 'package:bikesetupapp/app_services/theme_data.dart';
import 'package:bikesetupapp/database_service/service_database.dart';
import 'package:bikesetupapp/models/service_component.dart';
import 'package:bikesetupapp/models/service_entry.dart';
import 'package:bikesetupapp/widgets/service_component_card.dart';
import 'package:bikesetupapp/widgets/service_status.dart';
import 'package:flutter/material.dart';

/// Renders the forecast strip + stats row + 3 urgency-grouped lists of cards.
class ServiceComponentsList extends StatelessWidget {
  final String userID;
  final String bikeId;
  final double currentMileageKm;
  final void Function(ServiceComponent component)? onComponentTap;
  final void Function(ServiceComponent component)? onComponentLog;
  final void Function(bool hasAlert)? onAlertChanged;

  const ServiceComponentsList({
    super.key,
    required this.userID,
    required this.bikeId,
    required this.currentMileageKm,
    this.onComponentTap,
    this.onComponentLog,
    this.onAlertChanged,
  });

  @override
  Widget build(BuildContext context) {
    final db = ServiceDatabaseService(userID);
    return StreamBuilder<List<ServiceComponent>>(
      stream: db.getComponentsForBike(bikeId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(40),
            child: Center(child: CircularProgressIndicator.adaptive()),
          );
        }
        final components = snapshot.data ?? [];
        if (components.isEmpty) return _EmptyState();
        return _ComponentListWithEntries(
          db: db,
          components: components,
          currentMileageKm: currentMileageKm,
          onComponentTap: onComponentTap,
          onComponentLog: onComponentLog,
          onAlertChanged: onAlertChanged,
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.build_outlined, size: 48, color: p.inkDim),
          const SizedBox(height: 16),
          Text(
            'No components tracked yet',
            style: AppTextStyles.inter(
              size: 14, weight: FontWeight.w600, color: p.inkMuted,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Tap + to add your first component\nand start tracking service intervals',
            textAlign: TextAlign.center,
            style: AppTextStyles.inter(size: 12, color: p.inkDim),
          ),
        ],
      ),
    );
  }
}

class _ComponentListWithEntries extends StatefulWidget {
  final ServiceDatabaseService db;
  final List<ServiceComponent> components;
  final double currentMileageKm;
  final void Function(ServiceComponent component)? onComponentTap;
  final void Function(ServiceComponent component)? onComponentLog;
  final void Function(bool hasAlert)? onAlertChanged;

  const _ComponentListWithEntries({
    required this.db,
    required this.components,
    required this.currentMileageKm,
    this.onComponentTap,
    this.onComponentLog,
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

  AnnotatedService _annotate(ServiceComponent comp) {
    final entry = _latestEntries[comp.id];
    final mileageUnknown = entry != null && entry.mileageAtServiceKm == null;
    final kmSince = (entry?.mileageAtServiceKm != null)
        ? (widget.currentMileageKm - entry!.mileageAtServiceKm!).clamp(0.0, double.infinity)
        : widget.currentMileageKm;
    final progress = comp.serviceIntervalKm > 0 ? kmSince / comp.serviceIntervalKm : 0.0;
    final remaining = (comp.serviceIntervalKm - kmSince).clamp(0.0, double.infinity);
    ServiceStatus status;
    if (mileageUnknown) {
      status = ServiceStatus.unknown;
    } else if (progress >= 0.9) {
      status = ServiceStatus.red;
    } else if (progress >= 0.7) {
      status = ServiceStatus.amber;
    } else {
      status = ServiceStatus.green;
    }
    return AnnotatedService(
      component: comp,
      kmSinceService: kmSince,
      remainingKm: remaining,
      progress: progress,
      status: status,
      lastServicedAt: entry?.date,
      mileageUnknown: mileageUnknown,
    );
  }

  void _checkAlert() {
    if (widget.onAlertChanged == null) return;
    final hasAlert =
        widget.components.any((c) => _annotate(c).status == ServiceStatus.red);
    widget.onAlertChanged!(hasAlert);
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Padding(
        padding: EdgeInsets.all(40),
        child: Center(child: CircularProgressIndicator.adaptive()),
      );
    }

    final annotated = widget.components.map(_annotate).toList();
    final red    = annotated.where((s) => s.status == ServiceStatus.red)   .toList()..sort((a, b) => a.remainingKm.compareTo(b.remainingKm));
    final amber  = annotated.where((s) => s.status == ServiceStatus.amber) .toList()..sort((a, b) => a.remainingKm.compareTo(b.remainingKm));
    final green  = annotated.where((s) => s.status == ServiceStatus.green) .toList()..sort((a, b) => a.remainingKm.compareTo(b.remainingKm));
    final unknown= annotated.where((s) => s.status == ServiceStatus.unknown).toList();

    final knownSorted = [...annotated.where((s) => !s.mileageUnknown)]
      ..sort((a, b) => a.remainingKm.compareTo(b.remainingKm));
    final next = knownSorted.isEmpty ? null : knownSorted.first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (next != null) ForecastStrip(next: next),
        ServiceStatsRow(
          dueCount: red.length,
          soonCount: amber.length,
          healthyCount: green.length,
        ),
        if (red.isNotEmpty) ...[
          StatusGroupHeader(status: ServiceStatus.red, label: 'Action needed', count: red.length),
          for (final s in red)
            ServiceComponentCard(
              key: ValueKey('due_${s.component.id}'),
              component: s.component,
              currentMileageKm: widget.currentMileageKm,
              latestEntry: _latestEntries[s.component.id],
              onTap: widget.onComponentTap == null ? null : () => widget.onComponentTap!(s.component),
              onLog: widget.onComponentLog == null ? null : () => widget.onComponentLog!(s.component),
            ),
        ],
        if (amber.isNotEmpty) ...[
          StatusGroupHeader(status: ServiceStatus.amber, label: 'Coming up', count: amber.length),
          for (final s in amber)
            ServiceComponentCard(
              key: ValueKey('amber_${s.component.id}'),
              component: s.component,
              currentMileageKm: widget.currentMileageKm,
              latestEntry: _latestEntries[s.component.id],
              onTap: widget.onComponentTap == null ? null : () => widget.onComponentTap!(s.component),
            ),
        ],
        if (green.isNotEmpty) ...[
          StatusGroupHeader(status: ServiceStatus.green, label: 'Healthy', count: green.length),
          for (final s in green)
            ServiceComponentCard(
              key: ValueKey('green_${s.component.id}'),
              component: s.component,
              currentMileageKm: widget.currentMileageKm,
              latestEntry: _latestEntries[s.component.id],
              onTap: widget.onComponentTap == null ? null : () => widget.onComponentTap!(s.component),
            ),
        ],
        if (unknown.isNotEmpty) ...[
          StatusGroupHeader(status: ServiceStatus.unknown, label: 'No mileage data', count: unknown.length),
          for (final s in unknown)
            ServiceComponentCard(
              key: ValueKey('unknown_${s.component.id}'),
              component: s.component,
              currentMileageKm: widget.currentMileageKm,
              latestEntry: _latestEntries[s.component.id],
              onTap: widget.onComponentTap == null ? null : () => widget.onComponentTap!(s.component),
            ),
        ],
      ],
    );
  }
}
