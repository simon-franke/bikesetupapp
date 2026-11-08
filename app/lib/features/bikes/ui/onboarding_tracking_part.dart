import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:bikesetupapp/common/theme/theme_data.dart';

class OnboardingTrackingPart extends StatelessWidget {
  const OnboardingTrackingPart(this.title, this.detail, this.selected,
      {super.key, this.onChanged, this.spring, this.onSpringChanged});
  final String title, detail;
  final bool selected;
  final ValueChanged<bool>? onChanged;
  final String? spring;
  final ValueChanged<String>? onSpringChanged;
  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Semantics(
          selected: selected,
          button: onChanged != null,
          child: InkWell(
            onTap: onChanged == null ? null : () => onChanged!(!selected),
            child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                child: Row(children: [
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text(title,
                            style: AppTextStyles.label
                                .copyWith(color: context.palette.ink)),
                        if (detail.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(detail,
                              style: AppTextStyles.caption
                                  .copyWith(color: context.palette.inkMuted)),
                        ],
                      ])),
                  const SizedBox(width: 16),
                  if (onChanged == null)
                    Text('Included',
                        style: AppTextStyles.caption
                            .copyWith(color: context.palette.inkMuted))
                  else
                    Icon(
                        selected
                            ? CupertinoIcons.checkmark_circle_fill
                            : CupertinoIcons.circle,
                        size: AppIconSizes.control,
                        color: selected
                            ? context.palette.accentText
                            : context.palette.inkDim),
                ])),
          )),
      if (spring != null)
        TweenAnimationBuilder<double>(
          tween: Tween(begin: selected ? 1 : 0, end: selected ? 1 : 0),
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 240),
          curve: Curves.easeInOutCubic,
          builder: (context, value, child) => ClipRect(
              child: Align(
                  alignment: Alignment.topCenter,
                  heightFactor: value,
                  child: SizedBox(
                      width: double.infinity,
                      child: Opacity(opacity: value, child: child)))),
          child: ExcludeSemantics(
              excluding: !selected,
              child: IgnorePointer(
                  ignoring: !selected,
                  child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                      child: CupertinoSlidingSegmentedControl<String>(
                        groupValue: spring == 'Coil' ? 'Coil' : 'Air',
                        backgroundColor: context.palette.surface,
                        thumbColor: context.palette.accent,
                        children: {
                          for (final type in ['Air', 'Coil'])
                            type: Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 10, horizontal: 16),
                                child: Text(type,
                                    style: AppTextStyles.body.copyWith(
                                        color: spring == type
                                            ? context.palette.accentInk
                                            : context.palette.inkMuted)))
                        },
                        onValueChanged: (value) {
                          if (value != null) onSpringChanged!(value);
                        },
                      )))),
        ),
    ]);
  }
}
