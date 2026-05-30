import 'dart:math' as math;

import 'package:bikesetupapp/app_services/theme_data.dart';
import 'package:bikesetupapp/database_service/database.dart';
import 'package:bikesetupapp/widgets/add_field_bottom_sheet.dart';
import 'package:bikesetupapp/widgets/field_icon.dart';
import 'package:bikesetupapp/widgets/field_meta.dart';
import 'package:bikesetupapp/widgets/setting_value_editor.dart';
import 'package:bikesetupapp/widgets/unit_system.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class _CardDef {
  final String key;
  final String iconAsset;
  final UnitFamily? fallbackFamily;
  final UnitDef? fallbackUnit;
  const _CardDef(this.key, this.iconAsset, this.fallbackFamily, this.fallbackUnit);

  factory _CardDef.fromKey(String key) {
    final meta = kFieldMeta[key];
    if (meta != null) {
      return _CardDef(key, meta.iconAsset, meta.family, meta.defaultUnit);
    }
    return _CardDef(key, kDefaultFieldMeta.iconAsset, null, null);
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

Future<void> showSettingStepperSheet(
  BuildContext context, {
  required User user,
  required String uBikeID,
  required String category,
  required String uSetupID,
  required String settingKey,
  required String currentValue,
  required bool isDefault,
  UnitFamily? familyOverride,
}) {
  final p = context.palette;
  final knownMeta = kFieldMeta[settingKey];
  final rawForParse = currentValue == '--' ? '' : currentValue;
  final parsed = SettingValue.parse(
    rawForParse,
    fallbackFamily: knownMeta?.family,
    fallbackUnit: knownMeta?.defaultUnit,
  );

  final UnitFamily? predetermined = familyOverride ?? knownMeta?.family;

  late UnitFamily family;
  late UnitDef unit;
  late bool isFreeText;

  if (predetermined != null) {
    family = predetermined;
    if (family == UnitFamily.freeText) {
      isFreeText = true;
      unit = const UnitDef(id: '', label: '', toCanonical: 1.0);
    } else {
      isFreeText = false;
      final familyUnits = kUnitFamilies[family] ?? const <UnitDef>[];
      final parsedUnit = parsed.unit;
      if (parsedUnit != null && familyUnits.any((u) => u.id == parsedUnit.id)) {
        unit = parsedUnit;
      } else if (knownMeta != null && knownMeta.family == family) {
        unit = knownMeta.defaultUnit;
      } else if (familyUnits.isNotEmpty) {
        unit = familyUnits.first;
      } else {
        unit = const UnitDef(id: '', label: '', toCanonical: 1.0);
      }
    }
  } else if (parsed.isText) {
    family = UnitFamily.freeText;
    unit = const UnitDef(id: '', label: '', toCanonical: 1.0);
    isFreeText = true;
  } else if (parsed.unit != null && parsed.family != null) {
    family = parsed.family!;
    unit = parsed.unit!;
    isFreeText = false;
  } else {
    family = UnitFamily.count;
    unit = unitDefById(UnitFamily.count, 'count');
    isFreeText = false;
  }

  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: p.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (ctx) => _StepperSheetContent(
      user: user,
      uBikeID: uBikeID,
      category: category,
      uSetupID: uSetupID,
      settingKey: settingKey,
      iconAsset: knownMeta?.iconAsset ?? kDefaultFieldMeta.iconAsset,
      family: family,
      initialUnit: unit,
      initialNumeric: parsed.number ?? 0,
      initialText: parsed.text ?? '',
      knownMeta: knownMeta,
      isFreeText: isFreeText,
      isDefault: isDefault,
    ),
  );
}

class _StepperSheetContent extends StatefulWidget {
  final User user;
  final String uBikeID;
  final String category;
  final String uSetupID;
  final String settingKey;
  final String iconAsset;
  final UnitFamily family;
  final UnitDef initialUnit;
  final double initialNumeric;
  final String initialText;
  final FieldMeta? knownMeta;
  final bool isFreeText;
  final bool isDefault;

  const _StepperSheetContent({
    required this.user,
    required this.uBikeID,
    required this.category,
    required this.uSetupID,
    required this.settingKey,
    required this.iconAsset,
    required this.family,
    required this.initialUnit,
    required this.initialNumeric,
    required this.initialText,
    required this.knownMeta,
    required this.isFreeText,
    required this.isDefault,
  });

  @override
  State<_StepperSheetContent> createState() => _StepperSheetContentState();
}

class _StepperSheetContentState extends State<_StepperSheetContent> {
  late UnitDef _unit;
  late double _value;
  late TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _unit = widget.initialUnit;
    _value = widget.initialNumeric;
    _textController = TextEditingController(text: widget.initialText);
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _onChipTap(UnitDef target) {
    if (target.id == _unit.id) return;
    setState(() {
      _value = convertValue(_value, _unit, target);
      _unit = target;
    });
  }

  void _onSave() {
    Navigator.of(context).pop();
    final stored = widget.isFreeText
        ? _textController.text.trim()
        : SettingValue.numeric(_value, widget.family, _unit).format();
    DatabaseService(widget.user.uid).setSetting(
      widget.settingKey,
      stored,
      widget.uBikeID,
      widget.category,
      widget.uSetupID,
    );
  }

  Future<void> _onDelete() async {
    final p = context.palette;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dlgCtx) => AlertDialog(
        title: const Text('Delete Field'),
        content: Text('Delete "${widget.settingKey}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dlgCtx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dlgCtx).pop(true),
            child: Text('Delete', style: TextStyle(color: p.red)),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      Navigator.of(context).pop();
      final db = DatabaseService(widget.user.uid);
      db.deleteSetting(
        widget.settingKey,
        widget.uBikeID,
        widget.category,
        widget.uSetupID,
      );
      db.deleteSettingMeta(
        widget.settingKey,
        widget.uBikeID,
        widget.category,
        widget.uSetupID,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final units = kUnitFamilies[widget.family] ?? const <UnitDef>[];

    return Padding(
      padding: EdgeInsets.only(
        left: 22,
        right: 22,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 28,
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
              FieldIcon(asset: widget.iconAsset, size: 15, color: p.inkMuted),
              const SizedBox(width: 8),
              Text(
                widget.settingKey.toUpperCase(),
                style: AppTextStyles.inter(
                  size: 11,
                  weight: FontWeight.w800,
                  color: p.inkMuted,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          if (!widget.isFreeText && units.length > 1) ...[
            const SizedBox(height: 14),
            _UnitChipRow(units: units, selected: _unit, onTap: _onChipTap),
          ],
          const SizedBox(height: 22),
          if (widget.isFreeText)
            _FreeTextField(controller: _textController)
          else
            _buildEditor(),
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
              onPressed: _onSave,
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
          if (!widget.isDefault) ...[
            const SizedBox(height: 6),
            TextButton(
              onPressed: _onDelete,
              child: Text(
                'Delete field',
                style: AppTextStyles.inter(
                  size: 12,
                  weight: FontWeight.w700,
                  color: p.red,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEditor() {
    final knownMeta = widget.knownMeta;
    double minInActive;
    double maxInActive;
    if (knownMeta != null) {
      final defaultUnit = knownMeta.defaultUnit;
      minInActive = convertValue(knownMeta.min, defaultUnit, _unit);
      maxInActive = convertValue(knownMeta.max, defaultUnit, _unit);
    } else {
      minInActive = 0;
      maxInActive = 100;
    }
    final step =
        _unit.decimals <= 0 ? 1.0 : math.pow(10, -_unit.decimals).toDouble();
    return SettingValueEditor(
      key: ValueKey('${widget.settingKey}-${_unit.id}'),
      initialValue: _value,
      min: minInActive,
      max: maxInActive,
      step: step,
      decimals: _unit.decimals,
      unitLabel: _unit.label,
      onChanged: (v) => _value = v,
    );
  }
}

class _UnitChipRow extends StatelessWidget {
  final List<UnitDef> units;
  final UnitDef selected;
  final ValueChanged<UnitDef> onTap;

  const _UnitChipRow({
    required this.units,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      alignment: WrapAlignment.center,
      children: units.map((u) {
        final isSelected = u.id == selected.id;
        return GestureDetector(
          onTap: () => onTap(u),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected ? p.accent : p.surface2,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isSelected ? p.accent : p.border),
            ),
            child: Text(
              u.label.isEmpty ? u.id : u.label,
              style: AppTextStyles.inter(
                size: 11,
                weight: FontWeight.w700,
                color: isSelected ? p.accentInk : p.inkMuted,
                letterSpacing: 0.5,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _FreeTextField extends StatelessWidget {
  final TextEditingController controller;
  const _FreeTextField({required this.controller});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return TextField(
      controller: controller,
      autofocus: true,
      style: AppTextStyles.inter(size: 16, color: p.ink),
      decoration: InputDecoration(
        hintText: 'Enter value',
        hintStyle: AppTextStyles.inter(size: 16, color: p.inkDim),
        filled: true,
        fillColor: p.surface2,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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

class _ControlPanelGridState extends State<ControlPanelGrid> {
  @override
  Widget build(BuildContext context) {
    final db = DatabaseService(widget.user.uid);
    return StreamBuilder(
      stream: db.getSettings(widget.uBikeID, widget.category, widget.uSetupID),
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

        return StreamBuilder(
          stream: db.getSettingsMeta(
              widget.uBikeID, widget.category, widget.uSetupID),
          builder: (context, metaSnap) {
            final Map<String, String> metaMap = {};
            final metaRaw = metaSnap.hasData ? metaSnap.data?.data() : null;
            if (metaRaw is Map) {
              metaRaw.forEach((k, v) {
                if (v is String) metaMap[k.toString()] = v;
              });
            }
            return _buildGrid(allKeys, settings, metaMap);
          },
        );
      },
    );
  }

  Widget _buildGrid(
    List<String> allKeys,
    Map<String, dynamic> settings,
    Map<String, String> metaMap,
  ) {
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
                    final familyOverride =
                        unitFamilyFromName(metaMap[key] ?? '');
                    return _AnimatedTile(
                      key: ValueKey('tile_$key'),
                      child: _ControlCard(
                        config: card,
                        value: value,
                        onTap: () => showSettingStepperSheet(
                          context,
                          user: widget.user,
                          uBikeID: widget.uBikeID,
                          category: widget.category,
                          uSetupID: widget.uSetupID,
                          settingKey: key,
                          currentValue: value,
                          isDefault: isDefault,
                          familyOverride: familyOverride,
                        ),
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
    final parsed = SettingValue.parse(
      value == '--' ? '' : value,
      fallbackFamily: config.fallbackFamily,
      fallbackUnit: config.fallbackUnit,
    );
    String displayValue;
    String displayUnit;
    if (value == '--' || parsed.isEmpty) {
      displayValue = '--';
      displayUnit = config.fallbackUnit?.label ?? '';
    } else if (parsed.isText) {
      displayValue = parsed.text!;
      displayUnit = '';
    } else {
      displayValue = parsed.displayNumber();
      displayUnit = parsed.displayUnit();
    }
    final isText = parsed.isText;

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
                      FieldIcon(asset: config.iconAsset, size: 14, color: p.inkDim),
                    ],
                  ),
                  const Spacer(),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Flexible(
                        child: Text(
                          displayValue,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.mono(
                            size: isText ? 18 : 32,
                            weight: FontWeight.w700,
                            color: p.ink,
                            letterSpacing: isText ? 0 : -1,
                            height: 1,
                          ),
                        ),
                      ),
                      if (displayUnit.isNotEmpty) ...[
                        const SizedBox(width: 4),
                        Text(
                          displayUnit,
                          style: AppTextStyles.inter(
                            size: 11,
                            weight: FontWeight.w600,
                            color: p.inkMuted,
                          ),
                        ),
                      ],
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
