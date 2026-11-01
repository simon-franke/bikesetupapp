import 'package:flutter/material.dart';
import '../theme/theme_data.dart';
import 'app_components.dart';
import 'app_sheet.dart';

Future<bool> showDeleteConfirmationSheet(
  BuildContext context, {
  required String title,
  required String message,
  String actionLabel = 'Delete',
}) async =>
    await showAppSheet<bool>(
      context: context,
      builder: (ctx) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const AppSheetHandle(),
              const SizedBox(height: 24),
              Text(title, style: Theme.of(ctx).textTheme.titleLarge),
              const SizedBox(height: 12),
              Text(message,
                  style:
                      AppTextStyles.body.copyWith(color: ctx.palette.inkMuted)),
              const SizedBox(height: 28),
              AppActionButton(
                label: actionLabel,
                textStyle: AppTextStyles.label,
                destructive: true,
                onPressed: () => Navigator.pop(ctx, true),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                style: TextButton.styleFrom(
                  foregroundColor: ctx.palette.ink,
                  textStyle: AppTextStyles.label,
                ),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      ),
    ) ??
    false;
