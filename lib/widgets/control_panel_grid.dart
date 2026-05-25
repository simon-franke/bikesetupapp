import 'package:bikesetupapp/app_services/theme_data.dart';
import 'package:bikesetupapp/database_service/database.dart';
import 'package:bikesetupapp/widgets/add_field_bottom_sheet.dart';
import 'package:bikesetupapp/widgets/field_meta.dart';
import 'package:bikesetupapp/widgets/setting_value_editor.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class _CardDef {
  final String key;
  final String unit;
  final IconData icon;
  const _CardDef(this.key, this.unit, this.icon);

  factory _CardDef.fromKey(String key) {
    final meta = kFieldMeta[key] ?? kDefaultFieldMeta;
    return _CardDef(key, meta.unit, meta.icon);
  }
}

class ControlPanelGrid extends StatefulWidget {
  final User user;
  final String uBikeID;
  final String category;
  final String uSetupID;
  final double topPadding;
  final String? sectionLabel;

  const ControlPanelGrid({
    super.key,
    required this.user,
    required this.uBikeID,
    required this.category,
    required this.uSetupID,
    this.topPadding = 0,
    this.sectionLabel,
  });

  @override
  State<ControlPanelGrid> createState() => _ControlPanelGridState();
}

class _ControlPanelGridState extends State<ControlPanelGrid> {

  void _showStepperSheet(
      BuildContext context, _CardDef card, String currentValue, bool isDefault) {
    final p = context.palette;
    final int initial = int.tryParse(currentValue) ?? 0;
    final meta = kFieldMeta[card.key] ?? kDefaultFieldMeta;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: p.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
        int value = initial;
        return Padding(
          padding: EdgeInsets.only(
            left: 22,
            right: 22,
            top: 12,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 28,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: p.borderStrong,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 22),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(card.icon, size: 15, color: p.inkMuted),
                  const SizedBox(width: 8),
                  Text(
                    card.key.toUpperCase(),
                    style: AppTextStyles.inter(
                      size: 11,
                      weight: FontWeight.w800,
                      color: p.inkMuted,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              SettingValueEditor(
                initialValue: initial,
                meta: meta,
                onChanged: (v) => value = v,
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: p.accent,
                    foregroundColor: p.accentInk,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    DatabaseService(widget.user.uid).setSetting(
                      card.key,
                      '$value',
                      widget.uBikeID,
                      widget.category,
                      widget.uSetupID,
                    );
                  },
                  child: Text(
                    'SAVE',
                    style: AppTextStyles.inter(
                      size: 13,
                      weight: FontWeight.w800,
                      color: p.accentInk,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
              if (!isDefault) ...[
                const SizedBox(height: 6),
                TextButton(
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: ctx,
                      builder: (dlgCtx) => AlertDialog(
                        title: const Text('Delete Field'),
                        content: Text(
                            'Delete "${card.key}"? This cannot be undone.'),
                        actions: [
                          TextButton(
                            onPressed: () =>
                                Navigator.of(dlgCtx).pop(false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () =>
                                Navigator.of(dlgCtx).pop(true),
                            child: Text(
                              'Delete',
                              style: TextStyle(color: p.red),
                            ),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true) {
                      if (ctx.mounted) Navigator.of(ctx).pop();
                      DatabaseService(widget.user.uid).deleteSetting(
                        card.key,
                        widget.uBikeID,
                        widget.category,
                        widget.uSetupID,
                      );
                    }
                  },
                  child: Text(
                    'Delete field',
                    style: AppTextStyles.inter(
                      size: 12, weight: FontWeight.w700, color: p.red,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: DatabaseService(widget.user.uid)
          .getSettings(widget.uBikeID, widget.category, widget.uSetupID),
      builder: (context, snapshot) {
        Map<String, dynamic> settings = {};
        if (snapshot.hasData && snapshot.data?.data() != null) {
          settings = snapshot.data!.data() as Map<String, dynamic>;
        }

        final defaults = kDefaultFieldKeys[widget.category] ?? [];
        final extras =
            settings.keys.where((k) => !defaults.contains(k)).toList();
        final allKeys = [
          ...defaults.where((k) => settings.containsKey(k)),
          ...extras,
        ];

        return CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            if (widget.sectionLabel != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16, widget.topPadding + 16, 16, 4),
                  child: _SectionLabel(widget.sectionLabel!),
                ),
              ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(14, 4, 14, 100),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 200,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1 / 0.55,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index == allKeys.length) {
                      return _AnimatedTile(
                        key: const ValueKey('tile_add_field'),
                        child: _AddFieldCard(
                          onTap: () => showAddFieldSheet(
                            context,
                            user: widget.user,
                            uBikeID: widget.uBikeID,
                            category: widget.category,
                            uSetupID: widget.uSetupID,
                          ),
                        ),
                      );
                    }
                    final key = allKeys[index];
                    final card = _CardDef.fromKey(key);
                    final value = settings[key]?.toString() ?? '--';
                    final isDefault = isRequiredField(widget.category, key);
                    return _AnimatedTile(
                      key: ValueKey('tile_$key'),
                      child: _ControlCard(
                        config: card,
                        value: value,
                        onTap: () =>
                            _showStepperSheet(context, card, value, isDefault),
                      ),
                    );
                  },
                  childCount: allKeys.length + 1,
                  findChildIndexCallback: (Key key) {
                    final v = (key as ValueKey<String>).value;
                    if (v == 'tile_add_field') return allKeys.length;
                    final name = v.substring('tile_'.length);
                    final idx = allKeys.indexOf(name);
                    return idx >= 0 ? idx : null;
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Row(
      children: [
        Container(width: 12, height: 1, color: p.borderStrong),
        const SizedBox(width: 8),
        Text(
          text.toUpperCase(),
          style: AppTextStyles.eyebrow(color: p.inkDim),
        ),
        const SizedBox(width: 8),
        Expanded(child: Container(height: 1, color: p.border)),
      ],
    );
  }
}

class _ControlCard extends StatelessWidget {
  final _CardDef config;
  final String value;
  final VoidCallback onTap;

  const _ControlCard({
    required this.config,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Material(
      color: p.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: p.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          config.key.toUpperCase(),
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.inter(
                            size: 9.5,
                            weight: FontWeight.w700,
                            color: p.inkDim,
                            letterSpacing: 0.9,
                          ),
                        ),
                      ),
                      Icon(config.icon, size: 14, color: p.inkDim),
                    ],
                  ),
                  const Spacer(),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        value,
                        style: AppTextStyles.mono(
                          size: 32,
                          weight: FontWeight.w700,
                          color: p.ink,
                          letterSpacing: -1,
                          height: 1,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        config.unit,
                        style: AppTextStyles.inter(
                          size: 11,
                          weight: FontWeight.w600,
                          color: p.inkMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Positioned(
              left: 14, right: 14, bottom: 0, height: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Colors.transparent,
                      p.borderStrong,
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddFieldCard extends StatelessWidget {
  final VoidCallback onTap;
  const _AddFieldCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return GestureDetector(
      onTap: onTap,
      child: DottedBorder(
        color: p.borderStrong,
        radius: 14,
        child: Container(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_rounded, size: 22, color: p.inkMuted),
              const SizedBox(height: 6),
              Text(
                'ADD SETTING',
                style: AppTextStyles.inter(
                  size: 10,
                  weight: FontWeight.w700,
                  color: p.inkMuted,
                  letterSpacing: 0.9,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnimatedTile extends StatefulWidget {
  final Widget child;
  const _AnimatedTile({super.key, required this.child});

  @override
  State<_AnimatedTile> createState() => _AnimatedTileState();
}

class _AnimatedTileState extends State<_AnimatedTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _opacity;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
    _opacity = CurvedAnimation(parent: _c, curve: Curves.easeOut);
    _scale = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _c, curve: Curves.easeOutBack),
    );
    _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: ScaleTransition(scale: _scale, child: widget.child),
    );
  }
}

class DottedBorder extends StatelessWidget {
  final Widget child;
  final Color color;
  final double radius;
  const DottedBorder({super.key, required this.child, required this.color, this.radius = 14});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedRectPainter(color: color, radius: radius),
      child: child,
    );
  }
}

class _DashedRectPainter extends CustomPainter {
  final Color color;
  final double radius;
  const _DashedRectPainter({required this.color, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    final rect = RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius));
    final path = Path()..addRRect(rect);

    const double dash = 5, gap = 4;
    for (final m in path.computeMetrics()) {
      double dist = 0;
      while (dist < m.length) {
        final next = (dist + dash).clamp(0.0, m.length);
        canvas.drawPath(m.extractPath(dist, next), paint);
        dist = next + gap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedRectPainter old) => old.color != color || old.radius != radius;
}

