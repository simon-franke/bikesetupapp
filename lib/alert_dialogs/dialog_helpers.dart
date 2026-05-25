import 'package:bikesetupapp/app_services/theme_data.dart';
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
        style: AppTextStyles.inter(size: 16, weight: FontWeight.w700, color: p.ink),
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
    final p = context.palette;
    final bg = color ?? p.accent;
    final fg = color == null ? p.accentInk : Colors.white;
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(9),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(9),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          child: Text(
            label.toUpperCase(),
            style: AppTextStyles.inter(
              size: 11, weight: FontWeight.w800,
              color: fg, letterSpacing: 0.6,
            ),
          ),
        ),
      ),
    );
  }
}

class DialogSecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  const DialogSecondaryButton({super.key, required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return TextButton(
      onPressed: onPressed,
      child: Text(
        label.toUpperCase(),
        style: AppTextStyles.inter(
          size: 11, weight: FontWeight.w700,
          color: p.inkMuted, letterSpacing: 0.6,
        ),
      ),
    );
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
    final p = context.palette;
    return TextField(
      controller: controller,
      autofocus: true,
      keyboardType: keyboardType,
      cursorColor: p.accent,
      style: AppTextStyles.inter(size: 13, color: p.ink),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTextStyles.inter(size: 13, color: p.inkDim),
        filled: true,
        fillColor: p.surface2,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: p.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: p.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: p.accent),
        ),
      ),
    );
  }
}
