import 'package:bikesetupapp/widgets/app_components.dart';
import 'package:bikesetupapp/app_services/responsive_layout.dart';
import 'dart:async';

import 'package:bikesetupapp/app_services/theme_data.dart';
import 'package:bikesetupapp/database_service/service_database.dart';
import 'package:bikesetupapp/models/service_component.dart';
import 'package:bikesetupapp/models/service_entry.dart';
import 'package:bikesetupapp/widgets/service_component_card.dart';
import 'package:bikesetupapp/widgets/service_status.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ServiceComponentsList extends StatefulWidget {
  final String userID;
  final String bikeId;
  final double currentMileageKm;
  final bool mileageAvailable;
  final void Function(ServiceComponent component)? onComponentTap;
  final void Function(ServiceComponent component)? onComponentLog;
  final void Function(ServiceComponent component)? onComponentDefer;
  final void Function(bool hasAlert)? onAlertChanged;
  final VoidCallback? onAddComponent;

  const ServiceComponentsList({
    super.key,
    required this.userID,
    required this.bikeId,
    required this.currentMileageKm,
    this.mileageAvailable = true,
    this.onComponentTap,
    this.onComponentLog,
    this.onComponentDefer,
    this.onAlertChanged,
    this.onAddComponent,
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
    _resetStream();
  }

  void _resetStream() {
    _db = ServiceDatabaseService(widget.userID);
    _componentsStream = _db.getComponentsForBike(widget.bikeId);
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
            message: 'Could not load components.',
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
          db: _db,
          components: snapshot.data!,
          currentMileageKm: widget.currentMileageKm,
          mileageAvailable: widget.mileageAvailable,
          onComponentTap: widget.onComponentTap,
          onComponentLog: widget.onComponentLog,
          onComponentDefer: widget.onComponentDefer,
          onAlertChanged: widget.onAlertChanged,
          onAddComponent: widget.onAddComponent,
        );
      },
    );
  }
}

class _ComponentListWithEntries extends StatefulWidget {
  final ServiceDatabaseService db;
  final List<ServiceComponent> components;
  final double currentMileageKm;
  final bool mileageAvailable;
  final void Function(ServiceComponent)? onComponentTap;
  final void Function(ServiceComponent)? onComponentLog;
  final void Function(ServiceComponent)? onComponentDefer;
  final void Function(bool)? onAlertChanged;
  final VoidCallback? onAddComponent;

  const _ComponentListWithEntries({
    super.key,
    required this.db,
    required this.components,
    required this.currentMileageKm,
    required this.mileageAvailable,
    this.onComponentTap,
    this.onComponentLog,
    this.onComponentDefer,
    this.onAlertChanged,
    this.onAddComponent,
  });

  @override
  State<_ComponentListWithEntries> createState() =>
      _ComponentListWithEntriesState();
}

class _ComponentListWithEntriesState extends State<_ComponentListWithEntries> {
  final Map<String, ServiceEntry?> _latestEntries = {};
  final Map<String, StreamSubscription<ServiceEntry?>> _subs = {};
  final Set<String> _entryErrors = {};
  bool? _lastAlert;

  @override
  void initState() {
    super.initState();
    _subscribe();
  }

  @override
  void didUpdateWidget(_ComponentListWithEntries oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldIds = oldWidget.components.map((c) => c.id).toSet();
    final newIds = widget.components.map((c) => c.id).toSet();
    if (!setEquals(oldIds, newIds)) {
      _cancelAll();
      _latestEntries.removeWhere((id, _) => !newIds.contains(id));
      _entryErrors.removeWhere((id) => !newIds.contains(id));
      _subscribe();
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

  void _subscribe() {
    for (final component in widget.components) {
      _subs[component.id] =
          widget.db.streamLatestEntryForComponent(component.id).listen(
        (entry) {
          if (!mounted) return;
          setState(() {
            _latestEntries[component.id] = entry;
            _entryErrors.remove(component.id);
          });
        },
        onError: (_) {
          if (!mounted) return;
          setState(() => _entryErrors.add(component.id));
        },
      );
    }
  }

  void _retry() {
    _cancelAll();
    setState(() {
      _latestEntries.clear();
      _entryErrors.clear();
    });
    _subscribe();
  }

  @override
  Widget build(BuildContext context) {
    if (_entryErrors.isNotEmpty) {
      return _LoadError(
          message: 'Could not load service history.', onRetry: _retry);
    }
    if (widget.components.any((c) => !_latestEntries.containsKey(c.id))) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator.adaptive()),
      );
    }
    final services = widget.components
        .map((component) => annotateService(
              component: component,
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
      onAddComponent: widget.onAddComponent,
      services: services,
      cardBuilder: (service) => ServiceComponentCard(
        key: ValueKey(service.component.id),
        margin: ResponsiveLayout.isWide(context)
            ? EdgeInsets.zero
            : const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        component: service.component,
        currentMileageKm: widget.currentMileageKm,
        latestEntry: _latestEntries[service.component.id],
        mileageAvailable: widget.mileageAvailable,
        onTap: widget.onComponentTap == null
            ? null
            : () => widget.onComponentTap!(service.component),
        onLog: widget.onComponentLog == null
            ? null
            : () => widget.onComponentLog!(service.component),
        onDefer: widget.onComponentDefer == null
            ? null
            : () => widget.onComponentDefer!(service.component),
      ),
    );
  }
}

/// Presents an already loaded schedule, keeping filtering independent of Firestore.
class ServiceSchedule extends StatefulWidget {
  final List<AnnotatedService> services;
  final VoidCallback? onAddComponent;
  final Widget Function(AnnotatedService) cardBuilder;

  const ServiceSchedule(
      {super.key,
      required this.services,
      required this.cardBuilder,
      this.onAddComponent});

  @override
  State<ServiceSchedule> createState() => _ServiceScheduleState();
}

class _ServiceScheduleState extends State<ServiceSchedule> {
  bool _attentionOnly = false;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final attention =
        widget.services.where((s) => s.status != ServiceStatus.green).length;
    final groups = [
      (ServiceStatus.red, 'Needs attention'),
      (ServiceStatus.amber, 'Upcoming'),
      (ServiceStatus.green, 'Later'),
      (ServiceStatus.unknown, 'Missing service data'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
              ResponsiveLayout.isWide(context) ? 0 : 18,
              16,
              ResponsiveLayout.isWide(context) ? 0 : 18,
              12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppSectionToolbar(
                  title: Text('Service schedule',
                      style: Theme.of(context).textTheme.titleLarge),
                  action: widget.onAddComponent == null
                      ? null
                      : AppActionButton(
                          label: 'Add component',
                          icon: Icons.add,
                          onPressed: widget.onAddComponent)),
              const SizedBox(height: 6),
              Text(
                  '${widget.services.length} components · $attention need attention',
                  style: TextStyle(fontSize: 13, color: p.inkMuted)),
              if (widget.services.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: Text('All (${widget.services.length})'),
                      selected: !_attentionOnly,
                      onSelected: (_) => setState(() => _attentionOnly = false),
                      selectedColor: p.surface2,
                      showCheckmark: false,
                      labelStyle: TextStyle(
                          color: p.ink,
                          fontSize: 13,
                          fontWeight: FontWeight.w500),
                    ),
                    ChoiceChip(
                      label: Text('Needs attention ($attention)'),
                      selected: _attentionOnly,
                      onSelected: (_) => setState(() => _attentionOnly = true),
                      selectedColor: p.surface2,
                      showCheckmark: false,
                      labelStyle: TextStyle(
                          color: p.ink,
                          fontSize: 13,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        if (widget.services.isEmpty)
          _Message(
              title: 'No components yet',
              text: 'Use Add component to start a maintenance schedule.')
        else if (_attentionOnly && attention == 0)
          _Message(
              title: 'Nothing needs attention',
              text:
                  'Switch to All to see every component and its service history.'),
        for (final group in groups)
          if (!_attentionOnly ||
              group.$1 == ServiceStatus.red ||
              group.$1 == ServiceStatus.amber ||
              group.$1 == ServiceStatus.unknown)
            ..._group(group.$1, group.$2),
      ],
    );
  }

  List<Widget> _group(ServiceStatus status, String label) {
    final services = widget.services.where((s) => s.status == status).toList()
      ..sort((a, b) {
        final remaining = a.remainingKm.compareTo(b.remainingKm);
        if (remaining != 0) return remaining;
        final overdue = b.kmSinceService.compareTo(a.kmSinceService);
        if (overdue != 0) return overdue;
        return a.component.id.compareTo(b.component.id);
      });
    if (services.isEmpty) return [];
    return [
      Padding(
        padding: EdgeInsets.fromLTRB(ResponsiveLayout.isWide(context) ? 0 : 18,
            14, ResponsiveLayout.isWide(context) ? 0 : 18, 12),
        child: Text('$label (${services.length})',
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: context.palette.inkMuted)),
      ),
      ResponsiveCardGrid(children: services.map(widget.cardBuilder).toList()),
    ];
  }
}

class _Message extends StatelessWidget {
  final String title;
  final String text;
  const _Message({required this.title, required this.text});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(text,
                style:
                    TextStyle(fontSize: 14, color: context.palette.inkMuted)),
          ],
        ),
      );
}

class _LoadError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _LoadError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(children: [
          Text(message),
          TextButton(onPressed: onRetry, child: const Text('Try again')),
        ]),
      );
}
