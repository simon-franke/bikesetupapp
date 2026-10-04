import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:bikesetupapp/common/controllers/operation_controller.dart';
import '../models/service_entry.dart';
import 'maintenance_controller.dart';

class ServiceEntriesController extends OperationController {
  ServiceEntriesController(this._maintenance);
  final MaintenanceController _maintenance;
  final Map<String, ServiceEntry?> _entries = {};
  final Map<String, (Object, StackTrace)> _errors = {};
  Map<String, (Object, StackTrace)> get errors => Map.unmodifiable(_errors);
  final Map<String, StreamSubscription<ServiceEntry?>> _subscriptions = {};
  Set<String> _ids = {};
  Map<String, ServiceEntry?> get entries => Map.unmodifiable(_entries);
  bool get hasError => _errors.isNotEmpty;
  bool get loading =>
      _ids.any((id) => !_entries.containsKey(id) && !_errors.containsKey(id));

  void watch(Iterable<String> componentIds) {
    if (isDisposed) return;
    final ids = componentIds.toSet();
    if (setEquals(ids, _ids)) return;
    _ids = ids;
    _restart();
  }

  void retry() {
    if (!isDisposed) _restart();
  }

  void _restart() {
    final generation = beginRequest('entries');
    _cancelAll();
    _entries.clear();
    _errors.clear();
    for (final id in _ids) {
      _subscriptions[id] =
          _maintenance.streamLatestEntryForComponent(id).listen((entry) {
        if (!isCurrentRequest('entries', generation)) return;
        _entries[id] = entry;
        _errors.remove(id);
        emit();
      }, onError: (Object error, StackTrace stack) {
        if (!isCurrentRequest('entries', generation)) return;
        _errors[id] = (error, stack);
        emit();
      });
    }
    emit();
  }

  void _cancelAll() {
    for (final sub in _subscriptions.values) {
      unawaited(sub.cancel());
    }
    _subscriptions.clear();
  }

  @override
  void dispose() {
    _cancelAll();
    super.dispose();
  }
}
