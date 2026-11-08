import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:bikesetupapp/common/ui/app_components.dart';
import '../models/ride.dart';

class FitImportPreview extends StatelessWidget {
  const FitImportPreview(
      {super.key, required this.bikeName, required this.rides});

  final String bikeName;
  final List<Ride> rides;

  @override
  Widget build(BuildContext context) => SafeArea(
      top: false,
      child: SingleChildScrollView(
          child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Import into $bikeName',
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 16),
                    for (final ride in rides)
                      ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(DateFormat.yMMMd()
                              .add_Hm()
                              .format(ride.startedAt.toLocal())),
                          subtitle: Text('${[
                            if (ride.distanceKm != null)
                              '${ride.distanceKm!.toStringAsFixed(1)} km',
                            if (ride.durationSeconds > 0)
                              '${ride.hours.toStringAsFixed(2)} hours'
                          ].join(' · ')}, ${ride.indoor ? 'Indoor' : 'Outdoor'}')),
                    const Text(
                        'Active riding time only. Previously imported rides are skipped.'),
                    const SizedBox(height: 20),
                    AppActionButton(
                        label: 'Import ${rides.length} rides',
                        onPressed: () => Navigator.pop(context, true)),
                    TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel')),
                  ]))));
}
