import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:bikesetupapp/common/theme/theme_data.dart';
import 'package:bikesetupapp/common/ui/app_components.dart';
import 'package:bikesetupapp/common/ui/app_sheet.dart';

class TrackTimeSheet extends StatefulWidget {
  const TrackTimeSheet({super.key, required this.initial});
  final String initial;

  @override
  State<TrackTimeSheet> createState() => _TrackTimeSheetState();
}

class _TrackTimeSheetState extends State<TrackTimeSheet> {
  late final minutes = TextEditingController(
      text: widget.initial.isEmpty ? '' : widget.initial.split(':').first);
  late final seconds = TextEditingController(
      text: widget.initial.isEmpty
          ? ''
          : widget.initial.split(':').last.split('.').first);
  late final milliseconds = TextEditingController(
      text: widget.initial.contains('.') ? widget.initial.split('.').last : '');
  final minuteFocus = FocusNode();
  final secondFocus = FocusNode();
  final millisecondFocus = FocusNode();
  String? error;

  @override
  void dispose() {
    for (final controller in [minutes, seconds, milliseconds]) {
      controller.dispose();
    }
    for (final focus in [minuteFocus, secondFocus, millisecondFocus]) {
      focus.dispose();
    }
    super.dispose();
  }

  void submit() {
    if ((int.tryParse(seconds.text) ?? 0) > 59) {
      setState(() => error = 'Seconds must be between 00 and 59.');
      secondFocus.requestFocus();
      selectAll(seconds);
      return;
    }
    Navigator.pop(context,
        '${minutes.text.padLeft(2, '0')}:${seconds.text.padLeft(2, '0')}.${milliseconds.text.padLeft(3, '0')}');
  }

  void selectAll(TextEditingController controller) {
    controller.selection =
        TextSelection(baseOffset: 0, extentOffset: controller.text.length);
  }

  Widget segment(String label, String hint, TextEditingController controller,
      FocusNode focus, int length,
      {FocusNode? next}) {
    final p = context.palette;
    return Expanded(
      child: Column(children: [
        TextField(
          key: ValueKey(label),
          controller: controller,
          focusNode: focus,
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          textInputAction:
              next == null ? TextInputAction.done : TextInputAction.next,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(length,
                maxLengthEnforcement: MaxLengthEnforcement.enforced),
          ],
          style: AppTextStyles.heading
              .copyWith(color: p.ink)
              .copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
          cursorColor: p.accentText,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTextStyles.heading
                .copyWith(color: p.inkMuted)
                .copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
            filled: false,
            contentPadding:
                const EdgeInsets.symmetric(vertical: 12, horizontal: 2),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: p.accentText)),
          ),
          onTap: () => selectAll(controller),
          onChanged: (value) {
            if (error != null) setState(() => error = null);
            if (next != null && value.length == length) {
              next.requestFocus();
              selectAll(next == secondFocus ? seconds : milliseconds);
            }
          },
          onSubmitted: (_) {
            if (next == null) {
              submit();
            } else {
              next.requestFocus();
              selectAll(next == secondFocus ? seconds : milliseconds);
            }
          },
        ),
        const SizedBox(height: 4),
        Text(label, style: AppTextStyles.caption.copyWith(color: p.inkMuted)),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: EdgeInsets.fromLTRB(
          24,
          16,
          24,
          24 +
              MediaQuery.paddingOf(context).bottom +
              MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AppSheetHandle(),
          const SizedBox(height: 24),
          Row(children: [
            Expanded(
                child: Text('Track time',
                    style: AppTextStyles.heading.copyWith(color: p.ink))),
            TextButton(
                onPressed: () => Navigator.pop(context, ''),
                child: const Text('Clear')),
          ]),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 16),
            decoration: BoxDecoration(
                color: p.surface2, borderRadius: BorderRadius.circular(14)),
            child: LayoutBuilder(builder: (context, constraints) {
              // Keep every digit visible at enlarged text sizes.
              final minimumWidth =
                  MediaQuery.textScalerOf(context).scale(26) * 6 + 40;
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: constraints.maxWidth < minimumWidth
                      ? minimumWidth
                      : constraints.maxWidth,
                  child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        segment('min', '00', minutes, minuteFocus, 3,
                            next: secondFocus),
                        separator(':'),
                        segment('sec', '00', seconds, secondFocus, 2,
                            next: millisecondFocus),
                        separator('.'),
                        segment('ms', '000', milliseconds, millisecondFocus, 3),
                      ]),
                ),
              );
            }),
          ),
          if (error != null) ...[
            const SizedBox(height: 12),
            Text(error!, style: TextStyle(color: p.red)),
          ],
          const SizedBox(height: 24),
          AppActionButton(label: 'Done', onPressed: submit),
        ],
      ),
    );
  }

  Widget separator(String text) => Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Text(text,
            style: AppTextStyles.heading
                .copyWith(color: context.palette.inkMuted)),
      );
}
