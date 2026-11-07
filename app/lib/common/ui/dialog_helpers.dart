import 'package:bikesetupapp/common/theme/theme_data.dart';
import 'package:flutter/material.dart';

class WorkshopDialog extends StatelessWidget {
  final String title;
  final Widget content;
  final List<Widget> actions;

  const WorkshopDialog({
    super.key,
    required this.title,
    required this.content,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return AlertDialog(
      backgroundColor: p.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: p.border),
      ),
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      actionsPadding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      title: Text(
        title,
        style: AppTextStyles.label.copyWith(color: p.ink),
      ),
      content: DefaultTextStyle(
        style: AppTextStyles.body.copyWith(color: p.inkMuted),
        child: content,
      ),
      actions: actions,
    );
  }
}
