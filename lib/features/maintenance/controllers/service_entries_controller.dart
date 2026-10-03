import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/service_entry.dart';
import 'maintenance_controller.dart';

class ServiceEntriesController extends ChangeNotifier {
  ServiceEntriesController(this._maintenance);
  final MaintenanceController _maintenance;
  final Map<String, ServiceEntry?> _entries = {};
  final Set<String> _errors = {};
  final Map<String, StreamSubscription<ServiceEntry?>> _subscriptions = {};
  Set<String> _ids = {};
  int _generation = 0;
  bool _disposed = false;
  Map<String, ServiceEntry?> get entries => Map.unmodifiable(_entries);
  bool get hasError => _errors.isNotEmpty;
  bool get loading => _ids.any((id) => !_entries.containsKey(id));

  void watch(Iterable<String> componentIds) {
    final ids = componentIds.toSet();
    if (setEquals(ids, _ids)) return;
    _ids = ids;
    _restart();
  }

  void retry() => _restart();

  void _restart() {
    final generation = ++_generation;
    _cancelAll();
    _entries.clear();
    _errors.clear();
    for (final id in _ids) {
      _subscriptions[id] =
          _maintenance.streamLatestEntryForComponent(id).listen((entry) {
        if (_disposed || generation != _generation) return;
        _entries[id] = entry;
        _errors.remove(id);
        notifyListeners();
      }, onError: (Object error, StackTrace stack) {
        if (_disposed || generation != _generation) return;
        _errors.add(id);
        notifyListeners();
      });
    }
    notifyListeners();
  }

  void _cancelAll() {
    for (final sub in _subscriptions.values) {
      sub.cancel();
    }
    _subscriptions.clear();
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    _cancelAll();
    super.dispose();
  }
}
