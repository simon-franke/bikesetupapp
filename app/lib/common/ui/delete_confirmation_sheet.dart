import 'dart:async';
import 'package:flutter/material.dart';
import '../models/command_result.dart';
import 'command_feedback.dart';
import 'app_error_banner.dart';
import '../theme/theme_data.dart';
import 'app_components.dart';
import 'app_sheet.dart';

Future<bool> showDeleteConfirmationSheet<T>(
  BuildContext context, {
  required String title,
  required String message,
  String actionLabel = 'Delete',
  Future<CommandResult<T>> Function()? onConfirm,
  FutureOr<void> Function(T)? onConfirmed,
}) async =>
    await showAppSheet<bool>(
      context: context,
      dismissible: onConfirm == null,
      builder: (_) => _DeleteConfirmation<T>(
          title: title,
          message: message,
          actionLabel: actionLabel,
          onConfirm: onConfirm,
          onConfirmed: onConfirmed),
    ) ??
    false;

class _DeleteConfirmation<T> extends StatefulWidget {
  const _DeleteConfirmation(
      {required this.title,
      required this.message,
      required this.actionLabel,
      this.onConfirm,
      this.onConfirmed});

  final String title, message, actionLabel;
  final Future<CommandResult<T>> Function()? onConfirm;
  final FutureOr<void> Function(T)? onConfirmed;

  @override
  State<_DeleteConfirmation<T>> createState() => _DeleteConfirmationState<T>();
}

class _DeleteConfirmationState<T> extends State<_DeleteConfirmation<T>> {
  bool deleting = false;
  String? error;

  Future<void> confirm() async {
    if (deleting) return;

    if (widget.onConfirm == null) {
      Navigator.pop(context, true);
      return;
    }

    setState(() {
      deleting = true;
      error = null;
    });
    CommandResult<T>? result;
    final success = await presentCommand<T>(context, () async {
      result = await widget.onConfirm!();
      return result!;
    }, onFailure: (message) => setState(() => error = message));
    if (!mounted) return;

    if (success) {
      await widget.onConfirmed?.call(result!.requireValue());
      if (mounted) Navigator.pop(context, true);
    } else {
      setState(() => deleting = false);
    }
  }

  @override
  Widget build(BuildContext ctx) => PopScope(
      canPop: !deleting,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const AppSheetHandle(),
              const SizedBox(height: 24),
              Text(widget.title, style: Theme.of(ctx).textTheme.titleLarge),
              const SizedBox(height: 12),
              Text(widget.message,
                  style:
                      AppTextStyles.body.copyWith(color: ctx.palette.inkMuted)),
              const SizedBox(height: 28),
              if (error != null) ...[
                AppErrorBanner(message: error!),
                const SizedBox(height: 16),
              ],
              AppActionButton(
                label: deleting ? 'Deleting…' : widget.actionLabel,
                textStyle: AppTextStyles.label,
                destructive: true,
                onPressed: deleting ? null : confirm,
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: deleting ? null : () => Navigator.pop(ctx, false),
                style: TextButton.styleFrom(
                  foregroundColor: ctx.palette.ink,
                  textStyle: AppTextStyles.label,
                ),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      ));
}
