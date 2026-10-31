import 'package:bikesetupapp/common/ui/app_load_error.dart';
import 'package:bikesetupapp/common/ui/app_components.dart';
import '../../rides/models/ride.dart';
import '../controllers/service_entries_controller.dart';
import 'package:bikesetupapp/app/app_dependencies.dart';
import 'package:bikesetupapp/features/maintenance/controllers/maintenance_controller.dart';

import 'package:bikesetupapp/common/theme/theme_data.dart';
import 'package:bikesetupapp/features/maintenance/models/service_component.dart';
import 'package:bikesetupapp/features/maintenance/models/service_entry.dart';
import 'package:bikesetupapp/features/maintenance/ui/service_component_card.dart';
import 'package:bikesetupapp/features/maintenance/ui/service_status.dart';
import 'package:flutter/material.dart';

class ServiceComponentsList extends StatefulWidget {
  final VoidCallback? onAdd;
  final String userID;
  final String bikeId;
  final double currentMileageKm;
  final bool mileageAvailable;
  final void Function(ServiceComponent component)? onComponentTap;
  final void Function(bool hasAlert)? onAlertChanged;

  const ServiceComponentsList({
    super.key,
    required this.userID,
    this.onAdd,
    required this.bikeId,
    required this.currentMileageKm,
    this.mileageAvailable = true,
    this.onComponentTap,
    this.onAlertChanged,
  });

  @override
  State<ServiceComponentsList> createState() => _ServiceComponentsListState();
}

class _ServiceComponentsListState extends State<ServiceComponentsList> {
  late MaintenanceController _db;
  late Stream<List<ServiceComponent>> _componentsStream;
  Stream<List<Ride>>? _ridesStream;

  @override
  void initState() {
    super.initState();
    _resetStream();
  }

  void _resetStream() {
    _db = AppDependencies.of(context).forUser(widget.userID).maintenance;
    _componentsStream = _db.getComponentsForBike(widget.bikeId);
    _ridesStream = null;
  }

  @override
  void didUpdateWidget(ServiceComponentsList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userID != widget.userID ||
        oldWidget.bikeId != widget.bikeId) {
      _resetStream();
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ServiceComponent>>(
      stream: _componentsStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _LoadError(
            message: 'Your components couldn’t load. Give it another try.',
            onRetry: () => setState(_resetStream),
          );
        }
        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: CircularProgressIndicator.adaptive()),
          );
        }
        return _ComponentListWithEntries(
          key: ValueKey('${widget.userID}_${widget.bikeId}'),
          onAdd: widget.onAdd,
          db: _db,
          rides: (_ridesStream ??= AppDependencies.of(context)
              .forUser(widget.userID)
              .rides
              .watch(widget.bikeId)),
          components: snapshot.data!,
          currentMileageKm: widget.currentMileageKm,
          mileageAvailable: widget.mileageAvailable,
          onComponentTap: widget.onComponentTap,
          onAlertChanged: widget.onAlertChanged,
        );
      },
    );
  }
}

class _ComponentListWithEntries extends StatefulWidget {
  final Stream<List<Ride>>? rides;
  final VoidCallback? onAdd;
  final MaintenanceController db;
  final List<ServiceComponent> components;
  final double currentMileageKm;
  final bool mileageAvailable;
  final void Function(ServiceComponent)? onComponentTap;
  final void Function(bool)? onAlertChanged;

  const _ComponentListWithEntries({
    super.key,
    required this.db,
    this.onAdd,
    this.rides,
    required this.components,
    required this.currentMileageKm,
    required this.mileageAvailable,
    this.onComponentTap,
    this.onAlertChanged,
  });

  @override
  State<_ComponentListWithEntries> createState() =>
      _ComponentListWithEntriesState();
}

class _ComponentListWithEntriesState extends State<_ComponentListWithEntries> {
  late final ServiceEntriesController _entries;
  bool? _lastAlert;
  Map<String, ServiceEntry?> get _latestEntries => _entries.entries;

  @override
  void initState() {
    super.initState();
    _entries = ServiceEntriesController(widget.db);
    _entries.watch(widget.components.map((c) => c.id));
    _entries.addListener(_changed);
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void didUpdateWidget(_ComponentListWithEntries oldWidget) {
    super.didUpdateWidget(oldWidget);
    _entries.watch(widget.components.map((c) => c.id));
  }

  @override
  void dispose() {
    _entries.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.rides == null
      ? _content(context, null)
      : StreamBuilder<List<Ride>>(
          stream: widget.rides,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Padding(
                  padding: EdgeInsets.all(20),
                  child:
                      Text('Could not load rides. Reopen Service to retry.'));
            }
            if (!snapshot.hasData) {
              return const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator.adaptive()));
            }
            return _content(context, snapshot.data);
          });
  Widget _content(BuildContext context, List<Ride>? rides) {
    if (_entries.hasError) {
      return _LoadError(
          message: 'Could not load service history.', onRetry: _entries.retry);
    }
    if (_entries.loading) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator.adaptive()),
      );
    }
    final services = widget.components
        .map((component) => annotateService(
              component: component,
              rides: rides,
              currentMileageKm: widget.currentMileageKm,
              latestEntry: _latestEntries[component.id],
              mileageAvailable: widget.mileageAvailable,
            ))
        .toList();
    final hasAlert = services.any((s) => s.status == ServiceStatus.red);
    if (_lastAlert != hasAlert) {
      _lastAlert = hasAlert;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _lastAlert == hasAlert) {
          widget.onAlertChanged?.call(hasAlert);
        }
      });
    }
    return ServiceSchedule(
      services: services,
      onAdd: widget.onAdd,
      cardBuilder: (service) => ServiceComponentCard(
        key: ValueKey(service.component.id),
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
        component: service.component,
        rides: rides,
        currentMileageKm: widget.currentMileageKm,
        latestEntry: _latestEntries[service.component.id],
        mileageAvailable: widget.mileageAvailable,
        onTap: widget.onComponentTap == null
            ? null
            : () => widget.onComponentTap!(service.component),
      ),
    );
  }
}

/// Presents the loaded schedule in urgency order.
class ServiceSchedule extends StatefulWidget {
  final VoidCallback? onAdd;
  final List<AnnotatedService> services;
  final Widget Function(AnnotatedService) cardBuilder;

  const ServiceSchedule(
      {super.key,
      required this.services,
      required this.cardBuilder,
      this.onAdd});

  @override
  State<ServiceSchedule> createState() => _ServiceScheduleState();
}

class _ServiceScheduleState extends State<ServiceSchedule> {
  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    if (widget.services.isEmpty) {
      return Padding(
          padding: const EdgeInsets.all(20),
          child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                  color: p.surface, borderRadius: BorderRadius.circular(20)),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Keep your bike ready',
                        style: AppTextStyles.inter(
                            size: 26, weight: FontWeight.w600, color: p.ink)),
                    const SizedBox(height: 12),
                    Text(
                        'Track service intervals and keep a history of the work you do.',
                        style:
                            AppTextStyles.inter(size: 16, color: p.inkMuted)),
                    const SizedBox(height: 24),
                    AppActionButton(label: 'Add component', onPressed: widget.onAdd),
                  ])));
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 12, 8),
          child: Row(children: [
            Expanded(
                child: Text('Service schedule',
                    style: AppTextStyles.inter(
                        size: 22, weight: FontWeight.w600, color: p.ink))),
            IconButton(
                tooltip: 'Add component',
                onPressed: widget.onAdd,
                icon: const Icon(Icons.add)),
          ])),
      ..._group(context, {ServiceStatus.red}, 'Needs attention'),
      ..._group(
          context, {ServiceStatus.amber, ServiceStatus.green}, 'Upcoming'),
      ..._group(context, {ServiceStatus.unknown}, 'Needs a starting point'),
    ]);
  }

  List<Widget> _group(
      BuildContext context, Set<ServiceStatus> statuses, String label) {
    final entries = widget.services.where((s) => statuses.contains(s.status)).toList()
      ..sort((a, b) {
        final remaining = b.progress.compareTo(a.progress);
        if (remaining != 0) return remaining;
        final overdue = b.usage.compareTo(a.usage);
        if (overdue != 0) return overdue;
        return a.component.name
            .toLowerCase()
            .compareTo(b.component.name.toLowerCase());
      });
    if (entries.isEmpty) return [];
    return [
      Padding(
        padding: EdgeInsets.fromLTRB(20, 14, 20, 12),
        child: Text(label,
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: context.palette.inkMuted)),
      ),
      Column(children: entries.map(widget.cardBuilder).toList()),
    ];
  }
}

class _LoadError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _LoadError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(20),
        child: AppLoadError(message: message, onRetry: onRetry),
      );
}
