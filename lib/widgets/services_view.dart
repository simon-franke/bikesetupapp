import 'package:bikesetupapp/app_pages/component_detail_page.dart';
import 'package:bikesetupapp/app_services/app_routes.dart';
import 'package:bikesetupapp/app_services/strava_sync_service.dart';
import 'package:bikesetupapp/app_services/strava_token_storage.dart';
import 'package:bikesetupapp/database_service/service_database.dart';
import 'package:bikesetupapp/database_service/strava_auth_service.dart';
import 'package:bikesetupapp/models/service_component.dart';
import 'package:bikesetupapp/widgets/mileage_banner.dart';
import 'package:bikesetupapp/widgets/service_components_list.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ServicesView extends StatefulWidget {
  final User user;
  final String uBikeID;
  final void Function(bool hasAlert)? onAlertChanged;

  const ServicesView({
    super.key,
    required this.user,
    required this.uBikeID,
    this.onAlertChanged,
  });

  @override
  State<ServicesView> createState() => _ServicesViewState();
}

class _ServicesViewState extends State<ServicesView> {
  bool _isStravaConnected = false;
  bool _isSyncing = false;
  double _mileageKm = 0;
  DateTime? _lastSyncTime;

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
    final auth = await StravaTokenStorage.getAuth();
    final lastSync = await StravaSyncService.getLastSyncTime();
    if (mounted) {
      setState(() {
        _isStravaConnected = auth != null;
        _lastSyncTime = lastSync;
      });
    }
    await _loadMileage();
  }

  Future<void> _loadMileage() async {
    final db = ServiceDatabaseService(widget.user.uid);
    final km = await db.getMileageForBike(widget.uBikeID);
    if (mounted) {
      setState(() {
        _mileageKm = km ?? 0;
      });
    }
  }

  Future<void> _syncStrava() async {
    setState(() => _isSyncing = true);
    final db = ServiceDatabaseService(widget.user.uid);
    final syncService = StravaSyncService(db);
    await syncService.sync();
    await _loadState();
    if (mounted) {
      setState(() => _isSyncing = false);
    }
  }

  Future<void> _connectStrava() async {
    final auth = await StravaAuthService().authorize();
    if (auth != null && mounted) {
      setState(() => _isStravaConnected = true);
      await _syncStrava();
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _syncStrava,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            const SizedBox(height: 8),
            MileageBanner(
              mileageKm: _mileageKm,
              lastSyncTime: _lastSyncTime,
              isLoading: _isSyncing,
              isConnected: _isStravaConnected,
              onSync: _syncStrava,
              onConnect: _connectStrava,
            ),
            const SizedBox(height: 8),
            ServiceComponentsList(
              userID: widget.user.uid,
              bikeId: widget.uBikeID,
              currentMileageKm: _mileageKm,
              onAlertChanged: widget.onAlertChanged,
              onComponentTap: (component) => _openComponentDetail(component),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  void _openComponentDetail(ServiceComponent component) {
    Navigator.of(context).push(
      AppRoutes.fadeSlide(
        ComponentDetailPage(
          user: widget.user,
          component: component,
          currentMileageKm: _mileageKm,
        ),
      ),
    );
  }
}
