import 'package:flutter/material.dart';
import '../../../app/app_dependencies.dart';
import '../../rides/models/ride.dart';
import 'workspace_title.dart';

class WorkspaceActivityTitle extends StatefulWidget {
  const WorkspaceActivityTitle(
      {super.key,
      required this.uid,
      required this.bikeId,
      required this.bikeName,
      required this.setupName,
      required this.bikeOnly,
      this.mileageKm});
  final String? uid;
  final String bikeId, bikeName, setupName;
  final bool bikeOnly;
  final double? mileageKm;
  @override
  State<WorkspaceActivityTitle> createState() => _WorkspaceActivityTitleState();
}

class _WorkspaceActivityTitleState extends State<WorkspaceActivityTitle> {
  late final Stream<List<Ride>>? rides = widget.uid == null
      ? null
      : AppDependencies.of(context)
          .forUser(widget.uid!)
          .rides
          .watch(widget.bikeId);
  @override
  Widget build(BuildContext context) => StreamBuilder<List<Ride>>(
        stream: rides,
        builder: (context, snapshot) {
          final hours = snapshot.hasError
              ? null
              : snapshot.data?.fold<double>(0, (sum, ride) => sum + ride.hours);
          final distances = snapshot.hasError
              ? <double>[]
              : snapshot.data
                      ?.map((ride) => ride.distanceKm)
                      .whereType<double>()
                      .toList() ??
                  <double>[];
          final distance = widget.mileageKm ??
              (distances.isEmpty
                  ? null
                  : distances.fold<double>(0, (sum, km) => sum + km));
          final summary = [
            if (distance != null) '${distance.round()} km',
            if (hours != null && hours > 0) '${hours.toStringAsFixed(1)} h',
          ].join('   ');
          return WorkspaceTitle(
              bikeName: widget.bikeName,
              setupName: widget.setupName,
              bikeOnly: widget.bikeOnly,
              mileageKm: distance,
              hours: hours,
              activitySummary: summary.isEmpty ? null : summary);
        },
      );
}
