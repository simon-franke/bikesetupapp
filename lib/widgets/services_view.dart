import 'package:bikesetupapp/app_services/responsive_layout.dart';
import 'package:bikesetupapp/app_pages/component_detail_page.dart';
import 'package:bikesetupapp/app_services/app_routes.dart';
import 'package:bikesetupapp/app_services/strava_sync_service.dart';
import 'package:bikesetupapp/app_services/strava_token_storage.dart';
import 'package:bikesetupapp/database_service/service_database.dart';
import 'package:bikesetupapp/database_service/strava_auth_service.dart';
import 'package:bikesetupapp/models/service_component.dart';
import 'package:bikesetupapp/widgets/defer_service_sheet.dart';
import 'package:bikesetupapp/widgets/log_service_sheet.dart';
import 'package:bikesetupapp/widgets/mileage_banner.dart';
import 'package:bikesetupapp/widgets/service_components_list.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

class ServicesView extends StatefulWidget {
  final User user;
  final String uBikeID;
  final VoidCallback? onAddComponent;
  final void Function(bool hasAlert)? onAlertChanged;

  const ServicesView({
    super.key,
    required this.user,
    required this.uBikeID,
    this.onAlertChanged,
    this.onAddComponent,
  });

  @override
  State<ServicesView> createState() => _ServicesViewState();
}

class _ServicesViewState extends State<ServicesView> {
  bool _isStravaConnected = false;
  bool _isSyncing = false;
  double? _mileageKm;
  DateTime? _lastSyncTime;
  bool _mileageError = false;

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  @override
  void didUpdateWidget(ServicesView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.uBikeID != widget.uBikeID) {
      _loadMileage();
    }
  }

  Future<void> _loadState() async {
    try {
      final auth = await StravaTokenStorage.getAuth();
      final lastSync = await StravaSyncService.getLastSyncTime();
      if (mounted) {
        setState(() {
          _isStravaConnected = auth != null;
          _lastSyncTime = lastSync;
        });
      }
      await _loadMileage();
    } catch (_) {
      if (mounted) setState(() => _mileageError = true);
    }
  }

  Future<void> _loadMileage() async {
    final bikeId = widget.uBikeID;
    final db = ServiceDatabaseService(widget.user.uid);
    try {
      final km = await db.getMileageForBike(bikeId);
      if (mounted && bikeId == widget.uBikeID) {
        setState(() {
          _mileageKm = km;
          _mileageError = false;
        });
      }
    } catch (_) {
      if (mounted && bikeId == widget.uBikeID) {
        setState(() {
          _mileageKm = null;
          _mileageError = true;
        });
      }
    }
  }

  Future<void> _syncStrava() async {
    if (_isSyncing) return;
    if (!_isStravaConnected) {
      await _loadMileage();
      return;
    }
    setState(() => _isSyncing = true);
    try {
      final db = ServiceDatabaseService(widget.user.uid);
      final sync = StravaSyncService(db);
      final synced = await sync.sync();
      await _loadState();
      if (!synced && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(sync.lastError ?? 'Could not sync Strava. Try again.'),
              duration: const Duration(seconds: 8)),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not load mileage. Try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  Future<void> _connectStrava() async {
    if (kIsWeb) {
      // On web, navigate the tab to Strava's auth page. The Firebase Function
      // handles the callback and redirects back to the app with tokens encoded
      // in the URL, which main() detects and saves on the next page load.
      await StravaAuthService().authorizeWeb();
      return;
    }
    final auth = await StravaAuthService().authorize();
    if (auth != null && mounted) {
      setState(() => _isStravaConnected = true);
      await _syncStrava();
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final wide = ResponsiveLayout.isWide(context);
      final mileage = MileageBanner(
        margin:
            wide ? EdgeInsets.zero : const EdgeInsets.fromLTRB(14, 8, 14, 12),
        mileageKm: _mileageKm,
        lastSyncTime: _lastSyncTime,
        isLoading: _isSyncing,
        isConnected: _isStravaConnected,
        onSync: _syncStrava,
        onConnect: _connectStrava,
      );
      return RefreshIndicator(
        onRefresh: _syncStrava,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              const SizedBox(height: 8),
              mileage,
              if (_mileageError)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Row(children: [
                    const Expanded(child: Text('Could not load bike mileage.')),
                    TextButton(
                        onPressed: _loadState, child: const Text('Retry')),
                  ]),
                ),
              const SizedBox(height: 8),
              ServiceComponentsList(
                onAddComponent: wide ? widget.onAddComponent : null,
                userID: widget.user.uid,
                bikeId: widget.uBikeID,
                currentMileageKm: _mileageKm ?? 0,
                mileageAvailable: _mileageKm != null,
                onAlertChanged: widget.onAlertChanged,
                onComponentTap: (component) => _openComponentDetail(component),
                onComponentLog: (component) =>
                    _logServiceForComponent(component),
                onComponentDefer: (component) =>
                    _deferServiceForComponent(component),
              ),
              SizedBox(height: wide ? 24 : 80),
            ],
          ),
        ),
      );
    });
  }

  Future<void> _openComponentDetail(ServiceComponent component) async {
    final db = ServiceDatabaseService(widget.user.uid);
    final stravaGearId = await db.getStravaGearIdForBike(widget.uBikeID);
    if (!mounted) return;
    Navigator.of(context).push(
      AppRoutes.fadeSlide(
        ComponentDetailPage(
          user: widget.user,
          component: component,
          currentMileageKm: _mileageKm ?? 0,
          mileageAvailable: _mileageKm != null,
          stravaGearId: stravaGearId,
        ),
      ),
    );
  }

  Future<void> _logServiceForComponent(ServiceComponent component) async {
    final db = ServiceDatabaseService(widget.user.uid);
    final stravaGearId = await db.getStravaGearIdForBike(widget.uBikeID);
    if (!mounted) return;
    await showLogServiceSheet(
      context: context,
      userID: widget.user.uid,
      component: component,
      currentMileageKm: _mileageKm ?? 0,
      stravaGearId: _mileageKm == null ? null : stravaGearId,
    );
  }

  Future<void> _deferServiceForComponent(ServiceComponent component) async {
    if (_mileageKm == null) return;
    await showDeferServiceSheet(
      context: context,
      userID: widget.user.uid,
      component: component,
      currentMileageKm: _mileageKm!,
    );
  }
}
