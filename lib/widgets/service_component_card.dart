import 'package:bikesetupapp/app_services/theme_data.dart';
import 'package:bikesetupapp/models/service_component.dart';
import 'package:bikesetupapp/models/service_entry.dart';
import 'package:bikesetupapp/widgets/service_status.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ServiceComponentCard extends StatelessWidget {
  final ServiceComponent component;
  final double currentMileageKm;
  final ServiceEntry? latestEntry;
  final VoidCallback? onTap;
  final VoidCallback? onLog;
  final VoidCallback? onDefer;

  const ServiceComponentCard({
    super.key,
    required this.component,
    required this.currentMileageKm,
    this.latestEntry,
    this.onTap,
    this.onLog,
    this.onDefer,
  });

  @override
  Widget build(BuildContext context) {
    final s = annotateService(
      component: component,
      currentMileageKm: currentMileageKm,
      latestEntry: latestEntry,
    );
    switch (s.status) {
      case ServiceStatus.red:
        return ServiceCardLarge(
          service: s,
          onTap: onTap,
          onLog: onLog ?? onTap,
          onDefer: onDefer,
        );
      case ServiceStatus.amber:
        return ServiceCardMedium(service: s, onTap: onTap);
      case ServiceStatus.green:
        return ServiceCardCompact(service: s, onTap: onTap);
      case ServiceStatus.unknown:
        return ServiceCardUnknown(service: s, onTap: onTap);
    }
  }
}

class ServiceCardLarge extends StatelessWidget {
  final AnnotatedService service;
  final VoidCallback? onTap;
  final VoidCallback? onLog;
  final VoidCallback? onDefer;
  const ServiceCardLarge({
    super.key,
    required this.service,
    this.onTap,
    this.onLog,
    this.onDefer,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final color = p.red;
    final formatter = NumberFormat('#,###');
    final kmText = formatter.format(service.kmSinceService.round());
    final intervalText = formatter.format(service.component.serviceIntervalKm);
    final lastDays = service.lastServicedAt == null
        ? null
        : DateTime.now().difference(service.lastServicedAt!).inDays;
    return _CardShell(
      color: p.surface,
      borderColor: color,
      glow: color.withValues(alpha: 0.18),
      onTap: onTap,
      child: Stack(
        children: [
          Positioned(
            top: 0, right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(8),
                ),
              ),
              child: Text(
                'DUE NOW',
                style: AppTextStyles.inter(
                  size: 8.5, weight: FontWeight.w800,
                  color: Colors.white, letterSpacing: 1.2,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        iconForComponent(service.component.type.icon),
                        size: 18, color: color,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            service.component.type.label,
                            style: AppTextStyles.inter(
                              size: 14, weight: FontWeight.w700, color: p.ink,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (_hasModel(service.component))
                            Text(
                              service.component.name,
                              style: AppTextStyles.inter(
                                size: 10.5, color: p.inkMuted,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      kmText,
                      style: AppTextStyles.mono(
                        size: 26, weight: FontWeight.w700,
                        color: color, letterSpacing: -1, height: 1,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '/ $intervalText km',
                      style: AppTextStyles.mono(
                        size: 12, weight: FontWeight.w600,
                        color: p.inkDim,
                      ),
                    ),
                  ],
                ),
                if (lastDays != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Last serviced $lastDays days ago',
                    style: AppTextStyles.inter(
                      size: 9.5, color: p.inkMuted,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: service.progress.clamp(0.0, 1.0),
                    minHeight: 4,
                    backgroundColor: Colors.white.withValues(alpha: 0.06),
                    valueColor: AlwaysStoppedAnimation(color),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (onDefer != null) ...[
                      Expanded(
                        child: _CardOutlinedButton(
                          label: 'STILL OK',
                          color: color,
                          onTap: onDefer!,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: _CardFilledButton(
                        label: 'LOG',
                        icon: Icons.check_rounded,
                        color: color,
                        onTap: onLog,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ServiceCardMedium extends StatelessWidget {
  final AnnotatedService service;
  final VoidCallback? onTap;
  const ServiceCardMedium({super.key, required this.service, this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final color = service.status.color(p);
    final formatter = NumberFormat('#,###');
    final remaining = service.remainingKm.round();
    final km = service.kmSinceService.round();
    final interval = service.component.serviceIntervalKm;
    return _CardShell(
      color: p.surface,
      borderColor: p.border,
      onTap: onTap,
      child: Stack(
        children: [
          Positioned(left: 0, top: 0, bottom: 0, width: 3, child: ColoredBox(color: color)),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 26, height: 26,
                      decoration: BoxDecoration(
                        color: p.surface2,
                        border: Border.all(color: p.border),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Icon(
                        iconForComponent(service.component.type.icon),
                        size: 14, color: p.inkMuted,
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            service.component.type.label,
                            style: AppTextStyles.inter(
                              size: 12.5, weight: FontWeight.w600, color: p.ink,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (_hasModel(service.component))
                            Text(
                              service.component.name,
                              style: AppTextStyles.inter(
                                size: 9.5, color: p.inkDim,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              '$remaining',
                              style: AppTextStyles.mono(
                                size: 14, weight: FontWeight.w700, color: color,
                              ),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              'km left',
                              style: AppTextStyles.mono(
                                size: 9, weight: FontWeight.w600, color: p.inkDim,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 1),
                        Text(
                          '${formatter.format(km)} / ${formatter.format(interval)}',
                          style: AppTextStyles.mono(
                            size: 9, weight: FontWeight.w500, color: p.inkDim,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: service.progress.clamp(0.0, 1.0),
                    minHeight: 3,
                    backgroundColor: p.surface2,
                    valueColor: AlwaysStoppedAnimation(color),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ServiceCardCompact extends StatelessWidget {
  final AnnotatedService service;
  final VoidCallback? onTap;
  const ServiceCardCompact({super.key, required this.service, this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final color = service.status.color(p);
    final formatter = NumberFormat('#,###');
    final kmText = formatter.format(service.kmSinceService.round());
    final intervalText = formatter.format(service.component.serviceIntervalKm);
    return _CardShell(
      color: Colors.transparent,
      borderColor: p.border,
      borderRadius: 10,
      marginVertical: 2,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        child: Row(
          children: [
            Icon(
              iconForComponent(service.component.type.icon),
              size: 14, color: p.inkMuted,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                service.component.type.label,
                style: AppTextStyles.inter(
                  size: 12, weight: FontWeight.w600, color: p.ink,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  kmText,
                  style: AppTextStyles.mono(
                    size: 12, weight: FontWeight.w700, color: p.ink,
                  ),
                ),
                const SizedBox(width: 3),
                Text(
                  '/ $intervalText km',
                  style: AppTextStyles.mono(
                    size: 10, weight: FontWeight.w500, color: p.inkDim,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 6),
            Container(
              width: 5, height: 5,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
          ],
        ),
      ),
    );
  }
}

class ServiceCardUnknown extends StatelessWidget {
  final AnnotatedService service;
  final VoidCallback? onTap;
  const ServiceCardUnknown({super.key, required this.service, this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final color = p.inkDim;
    final dateText = service.lastServicedAt == null
        ? 'no service yet'
        : DateFormat('MMM d, yyyy').format(service.lastServicedAt!);
    return _CardShell(
      color: p.surface.withValues(alpha: 0.6),
      borderColor: p.border,
      borderRadius: 10,
      marginVertical: 2,
      onTap: onTap,
      child: Stack(
        children: [
          Positioned(left: 0, top: 0, bottom: 0, width: 3, child: ColoredBox(color: color.withValues(alpha: 0.5))),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
            child: Row(
              children: [
                Icon(iconForComponent(service.component.type.icon), size: 14, color: p.inkDim),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    service.component.type.label,
                    style: AppTextStyles.inter(
                      size: 12.5, weight: FontWeight.w600, color: p.ink.withValues(alpha: 0.8),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      dateText,
                      style: AppTextStyles.inter(size: 11, weight: FontWeight.w500, color: p.inkMuted),
                    ),
                    Text(
                      'no mileage',
                      style: AppTextStyles.inter(size: 8.5, color: p.inkDim),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CardShell extends StatefulWidget {
  final Color color;
  final Color borderColor;
  final Color? glow;
  final double borderRadius;
  final double marginVertical;
  final VoidCallback? onTap;
  final Widget child;
  const _CardShell({
    required this.color,
    required this.borderColor,
    this.glow,
    this.borderRadius = 14,
    this.marginVertical = 4,
    this.onTap,
    required this.child,
  });

  @override
  State<_CardShell> createState() => _CardShellState();
}

class _CardShellState extends State<_CardShell> {
  bool _pressed = false;

  void _setPressed(bool v) {
    if (_pressed == v) return;
    setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      duration: const Duration(milliseconds: 110),
      curve: Curves.easeOut,
      scale: _pressed && widget.onTap != null ? 0.97 : 1.0,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 14, vertical: widget.marginVertical),
        decoration: BoxDecoration(
          color: widget.color,
          border: Border.all(color: widget.borderColor),
          borderRadius: BorderRadius.circular(widget.borderRadius),
          boxShadow: widget.glow == null
              ? null
              : [BoxShadow(color: widget.glow!, blurRadius: 18, offset: const Offset(0, 6))],
        ),
        clipBehavior: Clip.antiAlias,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            onTapDown: (_) => _setPressed(true),
            onTapUp: (_) => _setPressed(false),
            onTapCancel: () => _setPressed(false),
            onHighlightChanged: (v) => _setPressed(v),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

bool _hasModel(ServiceComponent c) =>
    c.name.trim().isNotEmpty && c.name.trim() != c.type.label;

class _CardFilledButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  const _CardFilledButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(9),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: Colors.white),
              const SizedBox(width: 4),
              Text(
                label,
                style: AppTextStyles.inter(
                  size: 10.5, weight: FontWeight.w800,
                  color: Colors.white, letterSpacing: 0.6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CardOutlinedButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _CardOutlinedButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(9),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            border: Border.all(color: color.withValues(alpha: 0.5)),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Center(
            child: Text(
              label,
              style: AppTextStyles.inter(
                size: 10.5, weight: FontWeight.w800,
                color: color, letterSpacing: 0.6,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
