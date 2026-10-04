import 'package:bikesetupapp/common/ui/command_feedback.dart';
import '../controllers/services_controller.dart';
import 'package:bikesetupapp/app/app_dependencies.dart';
import 'package:bikesetupapp/common/layout/responsive_layout.dart';
import 'package:bikesetupapp/features/maintenance/ui/component_detail_page.dart';
import 'package:bikesetupapp/app/routing/app_routes.dart';
import 'package:bikesetupapp/features/maintenance/models/service_component.dart';
import 'package:bikesetupapp/features/maintenance/ui/defer_service_sheet.dart';
import 'package:bikesetupapp/features/maintenance/ui/log_service_sheet.dart';
import 'package:bikesetupapp/features/strava/ui/mileage_banner.dart';
import 'package:bikesetupapp/features/maintenance/ui/service_components_list.dart';
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
  late ServicesController _controller;
  bool get _isStravaConnected => _controller.connected;
  bool get _isSyncing => _controller.syncing;
  double? get _mileageKm => _controller.mileageKm;
  DateTime? get _lastSyncTime => _controller.lastSyncTime;
  bool get _mileageError => _controller.mileageError;

  void _createController() {
    final dependencies = AppDependencies.of(context);
    _controller = ServicesController(
        dependencies.forUser(widget.user.uid).strava,
        dependencies.stravaConnection,
        widget.uBikeID)
      ..addListener(_changed);
    presentCommand(context, _controller.load);
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _createController();
  }

  @override
  void didUpdateWidget(ServicesView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.user.uid != widget.user.uid) {
      _controller.dispose();
      _createController();
    } else if (oldWidget.uBikeID != widget.uBikeID) {
      presentCommand(context, () => _controller.selectBike(widget.uBikeID));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadState() async {
    await presentCommand(context, _controller.load);
  }

  Future<void> _syncStrava() async {
    await presentCommand(context, _controller.sync);
  }

  Future<void> _connectStrava() async {
    await presentCommand(context, () => _controller.connect(web: kIsWeb));
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
    final db = AppDependencies.of(context).forUser(widget.user.uid);
    final stravaGearId = await db.strava.getStravaGearIdForBike(widget.uBikeID);
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
    final db = AppDependencies.of(context).forUser(widget.user.uid);
    final stravaGearId = await db.strava.getStravaGearIdForBike(widget.uBikeID);
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
