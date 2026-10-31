import 'add_component_flow.dart';
import 'package:bikesetupapp/common/ui/command_feedback.dart';
import '../controllers/services_controller.dart';
import 'package:bikesetupapp/app/app_dependencies.dart';
import 'package:bikesetupapp/features/maintenance/ui/component_detail_page.dart';
import 'package:bikesetupapp/app/routing/app_routes.dart';
import 'package:bikesetupapp/features/maintenance/models/service_component.dart';
import 'package:bikesetupapp/features/maintenance/ui/service_components_list.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ServicesView extends StatefulWidget {
  final User user;
  final String uBikeID;
  final String bikeName;
  final void Function(bool hasAlert)? onAlertChanged;

  const ServicesView({
    super.key,
    required this.user,
    required this.uBikeID,
    this.bikeName = 'Bike',
    this.onAlertChanged,
  });

  @override
  State<ServicesView> createState() => _ServicesViewState();
}

class _ServicesViewState extends State<ServicesView> {
  late ServicesController _controller;
  double? get _mileageKm => _controller.mileageKm;
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

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _syncStrava,
      child: SingleChildScrollView(
        padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            if (_mileageError)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(children: [
                  const Expanded(child: Text('Could not load bike mileage.')),
                  TextButton(onPressed: _loadState, child: const Text('Retry')),
                ]),
              ),
            const SizedBox(height: 12),
            ServiceComponentsList(
              onAdd: () => showAddComponentFlow(context,
                  user: widget.user,
                  uBikeID: widget.uBikeID,
                  currentMileageKm: _mileageKm),
              userID: widget.user.uid,
              bikeId: widget.uBikeID,
              currentMileageKm: _mileageKm ?? 0,
              mileageAvailable: _mileageKm != null,
              onAlertChanged: widget.onAlertChanged,
              onComponentTap: (component) => _openComponentDetail(component),
            ),
            SizedBox(height: MediaQuery.paddingOf(context).bottom + 120),
          ],
        ),
      ),
    );
  }

  Future<void> _openComponentDetail(ServiceComponent component) async {
    final db = AppDependencies.of(context).forUser(widget.user.uid);
    final stravaGearId = component.usesHours
        ? null
        : await db.strava.getStravaGearIdForBike(widget.uBikeID);
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
}
