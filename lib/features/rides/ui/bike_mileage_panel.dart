import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../app/app_dependencies.dart';
import '../../../common/ui/command_feedback.dart';
import '../../maintenance/controllers/services_controller.dart';
import '../../strava/ui/mileage_banner.dart';

class BikeMileagePanel extends StatefulWidget {
  const BikeMileagePanel({super.key, required this.uid, required this.bikeId});
  final String uid, bikeId;
  @override
  State<BikeMileagePanel> createState() => _BikeMileagePanelState();
}

class _BikeMileagePanelState extends State<BikeMileagePanel> {
  late final ServicesController controller;
  @override
  void initState() {
    super.initState();
    final dependencies = AppDependencies.of(context);
    controller = ServicesController(dependencies.forUser(widget.uid).strava,
        dependencies.stravaConnection, widget.bikeId);
    presentCommand(context, controller.load);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: controller,
        builder: (context, _) => MileageBanner(
          margin: EdgeInsets.zero,
          mileageKm: controller.mileageKm,
          lastSyncTime: controller.lastSyncTime,
          isLoading: controller.syncing,
          isConnected: controller.connected,
          onSync: () => presentCommand(context, controller.sync),
          onConnect: () =>
              presentCommand(context, () => controller.connect(web: kIsWeb)),
        ),
      );
}
