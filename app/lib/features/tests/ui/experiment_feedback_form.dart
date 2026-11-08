import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:bikesetupapp/common/theme/theme_data.dart';
import 'package:bikesetupapp/common/ui/app_sheet.dart';
import 'package:bikesetupapp/common/ui/app_components.dart';
import 'track_time_sheet.dart';
import '../models/setup_test.dart';

class ExperimentFeedbackForm extends StatefulWidget {
  const ExperimentFeedbackForm(
      {super.key,
      required this.initial,
      required this.busy,
      required this.onChanged,
      required this.onLog});

  final RideFeedback initial;
  final bool busy;
  final ValueChanged<RideFeedback> onChanged;
  final Future<bool> Function(RideFeedback) onLog;

  @override
  State<ExperimentFeedbackForm> createState() => _ExperimentFeedbackFormState();
}

class _ExperimentFeedbackFormState extends State<ExperimentFeedbackForm> {
  late final notes = TextEditingController(text: widget.initial.note);
  late final time = TextEditingController(text: widget.initial.time);
  late String? feeling = widget.initial.feeling;
  String? error;

  @override
  void dispose() {
    notes.dispose();
    time.dispose();
    super.dispose();
  }

  RideFeedback get enteredFeedback =>
      RideFeedback(feeling: feeling, note: notes.text, time: time.text);

  void persistFeedback() => widget.onChanged(enteredFeedback);

  void selectFeeling(double value) {
    final next = RideFeedback.feelings[value.round()];
    if (feeling == next) return;
    HapticFeedback.selectionClick();
    setState(() {
      feeling = next;
      error = null;
    });
  }

  @override
  Widget build(BuildContext context) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('Ride feedback', style: AppTextStyles.label)),
            Text(feeling ?? 'How did it feel?',
                textAlign: TextAlign.center,
                style: AppTextStyles.label.copyWith(
                    color: feeling == null
                        ? context.palette.inkMuted
                        : context.palette.playfulText)),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 16,
                trackShape: const RoundedRectSliderTrackShape(),
                thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 10, elevation: 1, pressedElevation: 2),
                tickMarkShape: SliderTickMarkShape.noTickMark,
                activeTrackColor: context.palette.playful,
                inactiveTrackColor: context.palette.surface2,
                thumbColor: context.palette.playful,
                showValueIndicator: ShowValueIndicator.never,
              ),
              child: Slider(
                min: 0,
                max: 4,
                divisions: 4,
                value: feeling == null
                    ? 2
                    : RideFeedback.feelings
                        .indexOf(feeling!)
                        .clamp(0, 4)
                        .toDouble(),
                label: feeling ?? 'Not rated',
                semanticFormatterCallback: (value) =>
                    RideFeedback.feelings[value.round()],
                onChanged: selectFeeling,
                onChangeEnd: (value) {
                  selectFeeling(value);
                  persistFeedback();
                },
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                    child: Text('Much worse',
                        style: AppTextStyles.body
                            .copyWith(color: context.palette.inkMuted))),
                const SizedBox(width: 16),
                Expanded(
                    child: Text('Much better',
                        textAlign: TextAlign.end,
                        style: AppTextStyles.body
                            .copyWith(color: context.palette.inkMuted))),
              ],
            ),
            const SizedBox(height: 20),
            AppFormField(
                label: 'Notes',
                child: AppTextField(
                    controller: notes,
                    hint: 'How did the bike feel?',
                    maxLines: 3,
                    onChanged: (_) => persistFeedback())),
            const SizedBox(height: 24),
            AppFormField(
                label: 'Track time',
                child: TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: context.palette.surface2,
                    foregroundColor: context.palette.ink,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 18),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () async {
                    FocusScope.of(context).unfocus();
                    final selected = await showAppSheet<String>(
                        context: context,
                        builder: (_) => TrackTimeSheet(initial: time.text));
                    if (selected == null || !mounted) return;
                    setState(() {
                      time.text = selected;
                      error = null;
                    });
                    persistFeedback();
                  },
                  child: Row(children: [
                    Expanded(
                        child: Text(time.text.isEmpty
                            ? 'Add time (optional)'
                            : time.text)),
                    const Icon(Icons.chevron_right, size: AppIconSizes.compact),
                  ]),
                )),
            if (error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child:
                    Text(error!, style: TextStyle(color: context.palette.red)),
              ),
            const SizedBox(height: 18),
            Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: AppActionButton(
                    label: 'Log ride',
                    onPressed: widget.busy
                        ? null
                        : () async {
                            final feedback = enteredFeedback;
                            if (feedback.validationError != null) {
                              setState(() => error = feedback.validationError);
                              return;
                            }

                            if (await widget.onLog(feedback)) {
                              if (!mounted) return;
                              setState(() {
                                feeling = null;
                                error = null;
                                notes.clear();
                                time.clear();
                              });
                            }
                          })),
          ]);
}
