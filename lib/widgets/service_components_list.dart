import 'dart:async';

import 'package:bikesetupapp/app_services/theme_data.dart';
import 'package:bikesetupapp/database_service/service_database.dart';
import 'package:bikesetupapp/models/service_component.dart';
import 'package:bikesetupapp/models/service_entry.dart';
import 'package:bikesetupapp/widgets/service_component_card.dart';
import 'package:bikesetupapp/widgets/service_status.dart';
import 'package:flutter/material.dart';

class ServiceComponentsList extends StatefulWidget {
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
  State<ServiceComponentsList> createState() => _ServiceComponentsListState();
}

class _ServiceComponentsListState extends State<ServiceComponentsList> {
  late ServiceDatabaseService _db;
  late Stream<List<ServiceComponent>> _componentsStream;

  @override
  void initState() {
    super.initState();
    _db = ServiceDatabaseService(widget.userID);
    _componentsStream = _db.getComponentsForBike(widget.bikeId);
  }

  @override
  void didUpdateWidget(ServiceComponentsList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userID != widget.userID) {
      _db = ServiceDatabaseService(widget.userID);
    }
    if (oldWidget.userID != widget.userID || oldWidget.bikeId != widget.bikeId) {
      _componentsStream = _db.getComponentsForBike(widget.bikeId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ServiceComponent>>(
      stream: _componentsStream,
      builder: (context, snapshot) {
        final Widget child;
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          child = const Padding(
            key: ValueKey('loading'),
            padding: EdgeInsets.all(40),
            child: Center(child: CircularProgressIndicator.adaptive()),
          );
        } else {
          final components = snapshot.data ?? [];
          if (components.isEmpty) {
            child = _EmptyState(key: const ValueKey('empty'));
          } else {
            child = _ComponentListWithEntries(
              key: const ValueKey('list'),
              db: _db,
              components: components,
              currentMileageKm: widget.currentMileageKm,
              onComponentTap: widget.onComponentTap,
              onComponentLog: widget.onComponentLog,
              onAlertChanged: widget.onAlertChanged,
            );
          }
        }
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          layoutBuilder: (currentChild, previousChildren) => Stack(
            alignment: Alignment.topCenter,
            children: [
              ...previousChildren,
              if (currentChild != null) currentChild,
            ],
          ),
          child: child,
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({super.key});

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
    super.key,
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
      _latestEntries.removeWhere((id, _) => !newIds.contains(id));
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
    for (final comp in components) {
      final sub = widget.db.streamLatestEntryForComponent(comp.id).listen(
        (entry) {
          if (!mounted) return;
          setState(() => _latestEntries[comp.id] = entry);
          _checkAlert();
        },
        onError: (_) {
          if (!mounted) return;
          setState(() => _latestEntries[comp.id] = null);
          _checkAlert();
        },
      );
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
        _AnimatedGroup(
          visible: red.isNotEmpty,
          header: StatusGroupHeader(status: ServiceStatus.red, label: 'Action needed', count: red.length),
          cards: [
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
        ),
        _AnimatedGroup(
          visible: amber.isNotEmpty,
          header: StatusGroupHeader(status: ServiceStatus.amber, label: 'Coming up', count: amber.length),
          cards: [
            for (final s in amber)
              ServiceComponentCard(
                key: ValueKey('amber_${s.component.id}'),
                component: s.component,
                currentMileageKm: widget.currentMileageKm,
                latestEntry: _latestEntries[s.component.id],
                onTap: widget.onComponentTap == null ? null : () => widget.onComponentTap!(s.component),
              ),
          ],
        ),
        _AnimatedGroup(
          visible: green.isNotEmpty,
          header: StatusGroupHeader(status: ServiceStatus.green, label: 'Healthy', count: green.length),
          cards: [
            for (final s in green)
              ServiceComponentCard(
                key: ValueKey('green_${s.component.id}'),
                component: s.component,
                currentMileageKm: widget.currentMileageKm,
                latestEntry: _latestEntries[s.component.id],
                onTap: widget.onComponentTap == null ? null : () => widget.onComponentTap!(s.component),
              ),
          ],
        ),
        _AnimatedGroup(
          visible: unknown.isNotEmpty,
          header: StatusGroupHeader(status: ServiceStatus.unknown, label: 'No mileage data', count: unknown.length),
          cards: [
            for (final s in unknown)
              ServiceComponentCard(
                key: ValueKey('unknown_${s.component.id}'),
                component: s.component,
                currentMileageKm: widget.currentMileageKm,
                latestEntry: _latestEntries[s.component.id],
                onTap: widget.onComponentTap == null ? null : () => widget.onComponentTap!(s.component),
              ),
          ],
        ),
      ],
    );
  }
}

class _AnimatedGroup extends StatelessWidget {
  final bool visible;
  final Widget header;
  final List<Widget> cards;
  const _AnimatedGroup({
    required this.visible,
    required this.header,
    required this.cards,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedCrossFade(
      duration: const Duration(milliseconds: 240),
      sizeCurve: Curves.easeOutCubic,
      firstCurve: Curves.easeOut,
      secondCurve: Curves.easeIn,
      alignment: Alignment.topCenter,
      firstChild: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [header, ...cards],
      ),
      secondChild: const SizedBox(width: double.infinity, height: 0),
      crossFadeState:
          visible ? CrossFadeState.showFirst : CrossFadeState.showSecond,
    );
  }
}
