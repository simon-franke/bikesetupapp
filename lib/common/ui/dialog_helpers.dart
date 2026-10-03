import 'package:bikesetupapp/common/ui/app_components.dart';
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
        style: AppTextStyles.inter(
            size: 16, weight: FontWeight.w700, color: p.ink),
      ),
      content: DefaultTextStyle(
        style: AppTextStyles.inter(size: 13, color: p.inkMuted, height: 1.4),
        child: content,
      ),
      actions: actions,
    );
  }
}

class DialogPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final Color? color;
  const DialogPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AppActionButton(label: label, onPressed: onPressed, color: color);
  }
}

class DialogSecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  const DialogSecondaryButton(
      {super.key, required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return TextButton(onPressed: onPressed, child: Text(label));
  }
}

class DialogTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  const DialogTextField({
    super.key,
    required this.controller,
    required this.hint,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return AppTextField(
        controller: controller,
        hint: hint,
        keyboardType: keyboardType,
        autofocus: true);
  }
}
