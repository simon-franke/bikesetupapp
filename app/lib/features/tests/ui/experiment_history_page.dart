import 'package:flutter/material.dart';
import 'package:bikesetupapp/common/ui/app_components.dart';
import '../models/setup_test.dart';
import 'experiment_comparison.dart';
import 'experiment_ride_card.dart';

class ExperimentHistoryPage extends StatelessWidget {
  const ExperimentHistoryPage({super.key, required this.test});
  final SetupTest test;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: buildDetailAppBar(context, title: test.name),
        body: ListView(
          padding: EdgeInsets.fromLTRB(
              20,
              MediaQuery.paddingOf(context).top + 12,
              20,
              MediaQuery.paddingOf(context).bottom + 24),
          children: [
            ExperimentComparison(
                test: test,
                badge: test.result.isEmpty ? 'Finished' : test.result,
                showName: false),
            for (var i = 0; i < test.rides.length; i++)
              ExperimentRideCard(ride: test.rides[i], index: i + 1),
          ],
        ),
      );
}
