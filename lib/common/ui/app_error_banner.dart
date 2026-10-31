import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../theme/theme_data.dart';

/// Persistent feedback for an action or a section that could not load.
class AppErrorBanner extends StatelessWidget {
  const AppErrorBanner(
      {super.key, required this.message, this.onRetry, this.onDismiss});
  final String message;
  final VoidCallback? onRetry;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
        liveRegion: true,
        child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
                color:
                    Color.alphaBlend(p.red.withValues(alpha: .08), p.surface),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: Color.alphaBlend(
                        p.red.withValues(alpha: .25), p.surface))),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Icon(CupertinoIcons.exclamationmark_circle,
                      size: 20, color: p.red)),
              const SizedBox(width: 10),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                    Text(message,
                        style: AppTextStyles.inter(
                            size: 14, color: p.ink, height: 1.4)),
                    if (onRetry != null) ...[
                      const SizedBox(height: 6),
                      TextButton(
                          onPressed: onRetry,
                          style: TextButton.styleFrom(
                              foregroundColor: p.ink,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              side: BorderSide(color: p.borderStrong)),
                          child: const Text('Retry')),
                    ],
                  ])),
              if (onDismiss != null)
                IconButton(
                    onPressed: onDismiss,
                    tooltip: 'Dismiss error',
                    icon: const Icon(CupertinoIcons.xmark, size: 16)),
            ])));
  }
}
