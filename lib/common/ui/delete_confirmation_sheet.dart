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
                  style: AppTextStyles.inter(
                      size: 14, color: ctx.palette.inkMuted)),
              const SizedBox(height: 28),
              AppActionButton(
                label: actionLabel,
                textStyle:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                color: AppColors.destructiveFill,
                onPressed: () => Navigator.pop(ctx, true),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                style: TextButton.styleFrom(
                  foregroundColor: ctx.palette.ink,
                  textStyle: Theme.of(ctx)
                      .textTheme
                      .labelLarge
                      ?.copyWith(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      ),
    ) ??
    false;
