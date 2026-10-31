import 'package:bikesetupapp/common/ui/app_haptics.dart';
import 'app_error_banner.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../theme/theme_data.dart';
import 'app_components.dart';

/// Shared navigation and progress for guided setup flows.
class AppFlowHeader extends StatelessWidget {
  const AppFlowHeader(
      {super.key,
      required this.progress,
      required this.progressLabel,
      this.onBack,
      this.backTooltip = 'Back',
      this.onClose,
      this.closeTooltip = 'Close'});
  final double progress;
  final String progressLabel, backTooltip, closeTooltip;
  final VoidCallback? onBack, onClose;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 20, 16),
        child: Row(children: [
          SizedBox(
              width: 48,
              height: 48,
              child: onBack == null
                  ? null
                  : IconButton(
                      tooltip: backTooltip,
                      onPressed: AppHaptics.wrap(onBack, selection: true),
                      icon: const Icon(CupertinoIcons.chevron_left, size: 20))),
          const SizedBox(width: 8),
          Expanded(
              child: LinearProgressIndicator(
            value: progress,
            semanticsLabel: progressLabel,
            minHeight: 14,
            borderRadius: BorderRadius.circular(20),
            color: context.palette.accent,
            backgroundColor: context.palette.bg,
          )),
          if (onClose != null) ...[
            const SizedBox(width: 8),
            IconButton(
                tooltip: closeTooltip,
                onPressed: AppHaptics.wrap(onClose, selection: true),
                icon: const Icon(CupertinoIcons.xmark, size: 20)),
          ],
        ]),
      );
}

class AppFlowHeading extends StatelessWidget {
  const AppFlowHeading(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: Semantics(
            header: true,
            child: Text(text,
                style: AppTextStyles.inter(
                    size: 26,
                    weight: FontWeight.w600,
                    color: context.palette.ink))),
      );
}

class AppFlowFooter extends StatelessWidget {
  const AppFlowFooter(
      {super.key,
      required this.label,
      required this.onPressed,
      this.error,
      this.onDismissError});
  final String label;
  final VoidCallback? onPressed;
  final String? error;
  final VoidCallback? onDismissError;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (error != null)
              Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: AppErrorBanner(
                      message: error!, onDismiss: onDismissError)),
            AppActionButton(label: label, onPressed: onPressed),
          ],
        ),
      );
}
