import '../controllers/setting_save_controller.dart';
import 'package:bikesetupapp/app/app_dependencies.dart';
import 'package:bikesetupapp/common/ui/adaptive_modal.dart';
import 'package:bikesetupapp/features/setups/ui/inline_setting_editor.dart';
import 'package:bikesetupapp/common/layout/responsive_layout.dart';
import 'package:bikesetupapp/common/ui/app_components.dart';
import 'dart:math' as math;

import 'package:bikesetupapp/common/theme/theme_data.dart';
import 'package:bikesetupapp/features/setups/ui/add_field_bottom_sheet.dart';
import 'package:bikesetupapp/features/setups/ui/field_icon.dart';
import 'package:bikesetupapp/features/setups/ui/field_meta.dart';
import 'package:bikesetupapp/features/setups/ui/setting_value_editor.dart';
import 'package:bikesetupapp/features/setups/models/unit_system.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class _CardDef {
  final String key;
  final String iconAsset;
  final UnitFamily? fallbackFamily;
  final UnitDef? fallbackUnit;
  const _CardDef(
      this.key, this.iconAsset, this.fallbackFamily, this.fallbackUnit);

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

  return showAdaptiveModal<void>(
    context: context,
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
    AppDependencies.of(context).forUser(widget.user.uid).setups.setSetting(
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
      final db = AppDependencies.of(context).forUser(widget.user.uid);
      db.setups.deleteSetting(
        widget.settingKey,
        widget.uBikeID,
        widget.category,
        widget.uSetupID,
      );
      db.setups.deleteSettingMeta(
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
          const AppSheetHandle(),
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
              onPressed: _onSave,
              child: Text('Save'),
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
              border: Border.all(color: isSelected ? p.accentText : p.border),
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
    return AppTextField(
        controller: controller, hint: 'Enter value', autofocus: true);
  }
}

class _ControlPanelGridState extends State<ControlPanelGrid> {
  late Stream<Map<String, dynamic>> _settingsStream;
  late Stream<Map<String, dynamic>> _metadataStream;

  void _connect() {
    final db = AppDependencies.of(context).forUser(widget.user.uid);
    _settingsStream =
        db.setups.getSettings(widget.uBikeID, widget.category, widget.uSetupID);
    _metadataStream = db.setups
        .getSettingsMeta(widget.uBikeID, widget.category, widget.uSetupID);
  }

  @override
  void initState() {
    super.initState();
    _connect();
  }

  @override
  void didUpdateWidget(ControlPanelGrid old) {
    super.didUpdateWidget(old);
    if (old.user.uid != widget.user.uid ||
        old.uBikeID != widget.uBikeID ||
        old.uSetupID != widget.uSetupID ||
        old.category != widget.category) {
      _connect();
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: _settingsStream,
      builder: (context, snapshot) {
        Map<String, dynamic> settings = {};
        if (snapshot.hasData && snapshot.data != null) {
          settings = snapshot.data!;
        }

        final defaults = kDefaultFieldKeys[widget.category] ?? [];
        final extras =
            settings.keys.where((k) => !defaults.contains(k)).toList();
        final allKeys = [
          ...defaults.where((k) => settings.containsKey(k)),
          ...extras,
        ];

        return StreamBuilder(
          stream: _metadataStream,
          builder: (context, metaSnap) {
            final Map<String, String> metaMap = {};
            final metaRaw = metaSnap.hasData ? metaSnap.data : null;
            if (metaRaw != null) {
              metaRaw.forEach((k, v) {
                if (v is String) metaMap[k.toString()] = v;
              });
            }
            if (snapshot.hasError || metaSnap.hasError) {
              return Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Text('Could not load settings.'),
                TextButton(
                    onPressed: () => setState(_connect),
                    child: const Text('Retry')),
              ]));
            }
            return _buildGrid(allKeys, settings, metaMap,
                loading: snapshot.connectionState != ConnectionState.active ||
                    metaSnap.connectionState != ConnectionState.active);
          },
        );
      },
    );
  }

  Widget _buildGrid(
    List<String> allKeys,
    Map<String, dynamic> settings,
    Map<String, String> metaMap, {
    bool loading = false,
  }) {
    final wide = ResponsiveLayout.isWide(context);
    if (wide) {
      final bikeId = widget.uBikeID;
      final setupId = widget.uSetupID;
      final category = widget.category;
      final userId = widget.user.uid;
      return TabletSettingsPanel(
        scope: '$userId/$bikeId/$setupId/$category',
        title: widget.sectionLabel ?? 'Settings',
        loading: loading,
        settings: {
          for (final key in allKeys) key: settings[key]?.toString() ?? '--'
        },
        metadata: metaMap,
        onAdd: () => showAddFieldSheet(context,
            user: widget.user,
            uBikeID: bikeId,
            category: category,
            uSetupID: setupId),
        onManage: (key) => showSettingStepperSheet(context,
            user: widget.user,
            uBikeID: bikeId,
            category: category,
            uSetupID: setupId,
            settingKey: key,
            currentValue: settings[key]?.toString() ?? '--',
            isDefault: isRequiredField(category, key),
            familyOverride: unitFamilyFromName(metaMap[key] ?? '')),
        onSave: (key, value) async {
          try {
            await AppDependencies.of(context)
                .forUser(userId)
                .setups
                .setSetting(key, value, bikeId, category, setupId);
          } catch (_) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Could not save $key. Try again.')));
            }
            rethrow;
          }
        },
      );
    }
    final delegate = SliverChildBuilderDelegate(
      (context, index) {
        final key = allKeys[index];
        final card = _CardDef.fromKey(key);
        final value = settings[key]?.toString() ?? '--';
        final isDefault = isRequiredField(widget.category, key);
        final familyOverride = unitFamilyFromName(metaMap[key] ?? '');
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
      childCount: allKeys.length,
      findChildIndexCallback: (Key key) {
        final v = (key as ValueKey<String>).value;
        final name = v.substring('tile_'.length);
        final idx = allKeys.indexOf(name);
        return idx >= 0 ? idx : null;
      },
    );
    return CustomScrollView(
      shrinkWrap: true,
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, widget.topPadding + 16, 20, 4),
            child: AppSectionToolbar(
              title: _SectionLabel(widget.sectionLabel ?? 'Settings'),
              action: TextButton.icon(
                onPressed: () => showAddFieldSheet(
                  context,
                  user: widget.user,
                  uBikeID: widget.uBikeID,
                  category: widget.category,
                  uSetupID: widget.uSetupID,
                ),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add setting'),
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
              20, 4, 20, ResponsiveLayout.isWide(context) ? 20 : 100),
          sliver: wide
              ? SliverList(delegate: delegate)
              : SliverGrid(
                  gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent:
                        220 * (MediaQuery.textScalerOf(context).scale(14) / 14),
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    mainAxisExtent: 112 +
                        (MediaQuery.textScalerOf(context).scale(14) / 14 - 1) *
                            80,
                  ),
                  delegate: delegate,
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
    return Text(
      text,
      style: AppTextStyles.inter(
        size: 14,
        weight: FontWeight.w600,
        color: p.inkMuted,
      ),
    );
  }
}

class _ControlCard extends StatelessWidget {
  final _CardDef config;
  final String value;
  final VoidCallback onTap;
  final bool selected;
  final bool forceText;

  const _ControlCard({
    super.key,
    required this.config,
    required this.value,
    required this.onTap,
    this.selected = false,
    this.forceText = false,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final parsed = forceText
        ? SettingValue.freeText(value)
        : SettingValue.parse(
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

    return Semantics(
        selected: selected,
        button: true,
        child: Material(
          color: selected ? p.surface2 : p.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(
                color: selected ? p.accentText : p.border,
                width: selected ? 2 : 1),
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
                              config.key,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.inter(
                                size: 12,
                                weight: FontWeight.w700,
                                color: p.inkMuted,
                              ),
                            ),
                          ),
                          FieldIcon(
                              asset: config.iconAsset,
                              size: 14,
                              color: p.inkDim),
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
              ],
            ),
          ),
        ));
  }
}

/// Tablet settings stay compact and align names and values for scanning.
class SettingRow extends StatelessWidget {
  final String name;
  final String value;
  final String unit;
  final String iconAsset;
  final VoidCallback onTap;
  const SettingRow(
      {super.key,
      required this.name,
      required this.value,
      required this.unit,
      required this.iconAsset,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Material(
      color: p.surface,
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 72),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: p.border))),
          child: Row(children: [
            FieldIcon(asset: iconAsset, size: 20, color: p.inkMuted),
            const SizedBox(width: 12),
            Expanded(
                child:
                    Text(name, style: Theme.of(context).textTheme.bodyLarge)),
            const SizedBox(width: 16),
            Expanded(
                child: Text(unit.isEmpty ? value : '$value $unit',
                    textAlign: TextAlign.right,
                    style: AppTextStyles.mono(
                        size: 20, weight: FontWeight.w600, color: p.ink))),
            const SizedBox(width: 12),
            Icon(Icons.chevron_right, size: 18, color: p.inkMuted),
          ]),
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
    _scale = Tween<double>(begin: 0.98, end: 1.0).animate(
      CurvedAnimation(parent: _c, curve: Curves.easeOut),
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

/// Persistent tablet inspector with the same setting tiles used on phones.
class TabletSettingsPanel extends StatefulWidget {
  final String scope;
  final String title;
  final Map<String, String> settings;
  final Map<String, String> metadata;
  final Future<void> Function(String key, String value) onSave;
  final VoidCallback onAdd;
  final ValueChanged<String>? onManage;
  final bool loading;

  const TabletSettingsPanel(
      {super.key,
      required this.scope,
      required this.title,
      required this.settings,
      this.metadata = const {},
      required this.onSave,
      required this.onAdd,
      this.onManage,
      this.loading = false});

  @override
  State<TabletSettingsPanel> createState() => _TabletSettingsPanelState();
}

class _TabletSettingsPanelState extends State<TabletSettingsPanel> {
  final Map<String, String> _selectedByScope = {};
  final Map<String, SettingWriteQueue> _writesByField = {};

  @override
  Widget build(BuildContext context) {
    if (widget.loading) {
      return const Center(child: CircularProgressIndicator.adaptive());
    }
    final keys = widget.settings.keys.toList();
    var selected = _selectedByScope[widget.scope];
    if (!keys.contains(selected)) selected = keys.isEmpty ? null : keys.first;
    if (selected != null) _selectedByScope[widget.scope] = selected;
    final selectedKey = selected;
    final onSave = widget.onSave;
    final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
    return LayoutBuilder(builder: (context, constraints) {
      final editor = selectedKey == null
          ? Padding(
              padding: const EdgeInsets.all(20),
              child: Text('Add a setting to start adjusting this part.',
                  style: Theme.of(context).textTheme.bodyLarge))
          : InlineSettingEditor(
              key: ValueKey('${widget.scope}/$selectedKey'),
              writes: _writesByField.putIfAbsent(
                  '${widget.scope}/$selectedKey', SettingWriteQueue.new),
              name: selectedKey,
              value: widget.settings[selectedKey]!,
              familyOverride:
                  unitFamilyFromName(widget.metadata[selectedKey] ?? ''),
              onSave: (value) => onSave(selectedKey, value),
              onManage: widget.onManage == null
                  ? null
                  : () => widget.onManage!(selectedKey),
            );
      final tiles = GridView.builder(
        primary: false,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: constraints.maxWidth >= 330 * scale ? 2 : 1,
            mainAxisExtent: 112 + (scale - 1) * 80,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12),
        itemCount: keys.length,
        itemBuilder: (context, index) {
          final key = keys[index];
          return _ControlCard(
              key: ValueKey('tablet-tile-$key'),
              config: _CardDef.fromKey(key),
              value: widget.settings[key]!,
              selected: selectedKey == key,
              forceText: widget.metadata[key] == UnitFamily.freeText.name,
              onTap: () =>
                  setState(() => _selectedByScope[widget.scope] = key));
        },
      );
      final content = Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            editor,
            const SizedBox(height: 24),
            Row(children: [
              Expanded(
                  child: Text('Settings',
                      style: Theme.of(context).textTheme.titleMedium)),
              TextButton.icon(
                  onPressed: widget.onAdd,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add setting')),
            ]),
            const SizedBox(height: 12),
            tiles,
            const SizedBox(height: 24),
          ]);
      // Long lists scroll below a pinned editor. Short windows and enlarged text
      // scroll the complete inspector so no controls become unreachable.
      if (!constraints.hasBoundedHeight ||
          constraints.maxHeight < 680 ||
          scale >= 1.6) {
        return SingleChildScrollView(primary: false, child: content);
      }
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(widget.title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        editor,
        const SizedBox(height: 24),
        Row(children: [
          Expanded(
              child: Text('Settings',
                  style: Theme.of(context).textTheme.titleMedium)),
          TextButton.icon(
              onPressed: widget.onAdd,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add setting')),
        ]),
        const SizedBox(height: 12),
        Expanded(child: SingleChildScrollView(primary: false, child: tiles)),
      ]);
    });
  }
}
