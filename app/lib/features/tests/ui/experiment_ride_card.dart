import 'package:bikesetupapp/features/setups/ui/setup_card.dart';
import 'package:flutter/cupertino.dart';
import 'package:bikesetupapp/common/theme/theme_data.dart';
import '../models/setup_test.dart';

class ExperimentRideCard extends StatelessWidget {
  const ExperimentRideCard(
      {super.key, required this.ride, required this.index});

  final RideFeedback ride;
  final int index;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return SetupCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Wrap(
          alignment: WrapAlignment.spaceBetween,
          spacing: 20,
          runSpacing: 8,
          children: [
            Text('Ride $index',
                style: AppTextStyles.body.copyWith(color: p.inkMuted)),
            if (ride.time.isNotEmpty)
              Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(CupertinoIcons.stopwatch,
                    size: AppIconSizes.compact, color: p.inkMuted),
                const SizedBox(width: 6),
                Text(ride.time,
                    style: AppTextStyles.body.copyWith(color: p.inkMuted)),
              ]),
          ]),
      if (ride.feeling != null) ...[
        const SizedBox(height: 14),
        Text(ride.feeling!,
            style: AppTextStyles.heading.copyWith(color: p.ink)),
      ],
      if (ride.note.isNotEmpty) ...[
        const SizedBox(height: 8),
        Text(ride.note, style: AppTextStyles.body.copyWith(color: p.inkMuted)),
      ],
    ]));
  }
}
