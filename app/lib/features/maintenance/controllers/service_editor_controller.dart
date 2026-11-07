import 'package:bikesetupapp/common/controllers/operation_controller.dart';
import 'package:bikesetupapp/common/models/command_result.dart';
import 'package:bikesetupapp/features/strava/controllers/strava_connection_controller.dart';
import 'package:uuid/uuid.dart';
import '../models/service_component.dart';
import 'maintenance_controller.dart';

/// Owns the service form's async operations; widgets own input and navigation.
class ServiceEditorController extends OperationController {
  ServiceEditorController(this._maintenance, this._connection,
      {required this.component,
      required this.currentMileageKm,
      this.gearId,
      String Function()? newId,
      DateTime Function()? now})
      : _newId = newId ?? const Uuid().v4,
        _now = now ?? DateTime.now,
        _mileageKm = gearId == null ? null : currentMileageKm;
  final MaintenanceController _maintenance;
  final StravaConnectionController _connection;
  final ServiceComponent component;
  final double currentMileageKm;
  final String? gearId;
  final String Function() _newId;
  final DateTime Function() _now;
  double? _mileageKm;
  bool _fetchingMileage = false;
  bool _saving = false;
  Object? _mileageError;
  Object? _saveError;
  Object? _draft;
  String? _entryId;
  DateTime? _entryDate;
  double? get mileageKm => _mileageKm;
  bool get fetchingMileage => _fetchingMileage;
  bool get saving => _saving;
  Object? get mileageError => _mileageError;
  Object? get saveError => _saveError;

  Future<CommandResult<void>> fetchMileage(DateTime date) => command(() async {
        if (_saving) throw const AppFailure(FailureCode.invalidInput);
        final generation = beginRequest('mileage');
        _fetchingMileage = true;
        _mileageKm = null;
        _mileageError = null;
        emit();
        try {
          final now = _now();
          final today = (date.year, date.month, date.day) ==
              (now.year, now.month, now.day);
          final mileage = gearId == null
              ? null
              : today
                  ? currentMileageKm
                  : await _connection.mileageAtDate(
                      gearId: gearId!,
                      date: date,
                      currentTotalKm: currentMileageKm);
          if (!isCurrentRequest('mileage', generation)) {
            throw const CommandAborted();
          }
          if (gearId != null && mileage == null) {
            throw const AppFailure(FailureCode.connectionExpired);
          }
          _mileageKm = mileage;
        } catch (error) {
          if (isCurrentRequest('mileage', generation) &&
              error is! CommandAborted) {
            _mileageError = error;
          }
          rethrow;
        } finally {
          if (isCurrentRequest('mileage', generation)) {
            _fetchingMileage = false;
            emit();
          }
        }
      });

  Future<CommandResult<void>> logService(
      {required DateTime date, String? note}) {
    final mileage = _mileageKm;
    return _save(
        ('log', date, mileage, note?.trim()),
        (id, _) => _maintenance.logService(
            componentId: component.id,
            date: date,
            mileageAtServiceKm: mileage,
            note: note,
            entryId: id));
  }

  Future<CommandResult<void>> deferService(int extendKm) => _save(
      ('defer', extendKm),
      (id, date) => _maintenance.deferService(
          component: component,
          currentMileageKm: currentMileageKm,
          extendKm: extendKm,
          entryId: id,
          date: date));

  Future<CommandResult<void>> _save(Object draft,
          Future<CommandResult<void>> Function(String, DateTime) write) =>
      share(
          'save',
          () => command(() async {
                if (_fetchingMileage) {
                  throw const AppFailure(FailureCode.invalidInput);
                }
                if (_draft != draft) {
                  _draft = draft;
                  _entryId = _newId();
                  _entryDate = _now();
                }
                _saving = true;
                _saveError = null;
                emit();
                try {
                  (await write(_entryId!, _entryDate!)).requireValue();
                  if (isDisposed) throw const CommandAborted();
                  _draft = null;
                  _entryId = null;
                  _entryDate = null;
                } catch (error) {
                  if (!isDisposed && error is! CommandAborted) {
                    _saveError = error;
                  }
                  rethrow;
                } finally {
                  if (!isDisposed) {
                    _saving = false;
                    emit();
                  }
                }
              }));
}
