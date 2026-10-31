import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../app/app_dependencies.dart';
import '../../../common/models/command_result.dart';
import '../../../common/ui/app_components.dart';
import '../../../common/ui/app_error_banner.dart';
import '../../../common/ui/app_select.dart';
import '../../../common/ui/app_sheet.dart';
import '../models/unit_system.dart';
import 'control_panel_grid.dart';
import 'field_meta.dart';

Future<void> showAddFieldSheet(
  BuildContext context, {
  required User user,
  required String uBikeID,
  required String category,
  required String uSetupID,
}) =>
    showAppSheet<void>(
        context: context,
        builder: (_) => _AddFieldSheet(
            user: user, bike: uBikeID, category: category, setup: uSetupID));

class _AddFieldSheet extends StatefulWidget {
  const _AddFieldSheet(
      {required this.user,
      required this.bike,
      required this.category,
      required this.setup});
  final User user;
  final String bike, category, setup;
  @override
  State<_AddFieldSheet> createState() => _AddFieldSheetState();
}

const Map<UnitFamily, String> _kFamilyLabel = {
  UnitFamily.pressure: 'Pressure',
  UnitFamily.percent: 'Percentage',
  UnitFamily.length: 'Length',
  UnitFamily.weight: 'Weight',
  UnitFamily.angle: 'Angle',
  UnitFamily.torque: 'Torque',
  UnitFamily.springRate: 'Spring rate',
  UnitFamily.distance: 'Distance',
  UnitFamily.count: 'Count',
  UnitFamily.freeText: 'Free text',
};

class _AddFieldSheetState extends State<_AddFieldSheet> {
  final _name = TextEditingController();
  Set<String> _existing = {};
  bool _loading = true, _failed = false, _custom = false, _opening = false;
  String? _nameError;
  UnitFamily _family = UnitFamily.count;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final values = await AppDependencies.of(context)
          .forUser(widget.user.uid)
          .setups
          .getSettings(widget.bike, widget.category, widget.setup)
          .first;
      if (mounted) {
        setState(() {
          _existing = values.keys.toSet();
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _failed = true;
          _loading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _edit(String key, {UnitFamily? family}) async {
    if (_opening) return;
    final name = key.trim();
    if (name.isEmpty ||
        _existing.any((k) => k.toLowerCase() == name.toLowerCase())) {
      setState(() => _nameError = name.isEmpty
          ? 'Enter a setting name.'
          : 'This setting already exists.');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _opening = true);
    var saved = false;
    final setups = AppDependencies.of(context).forUser(widget.user.uid).setups;
    await showSettingStepperSheet(context,
        user: widget.user,
        uBikeID: widget.bike,
        category: widget.category,
        uSetupID: widget.setup,
        settingKey: name,
        currentValue: '',
        isDefault: true,
        familyOverride: family,
        saveLabel: 'Add setting', onSave: (value) async {
      if (value.trim().isEmpty) {
        return const CommandFailure<void>(AppFailure(FailureCode.invalidInput));
      }
      final result = await setups.addField(
          name, value, widget.bike, widget.category, widget.setup,
          familyName: kFieldMeta.containsKey(name) ? null : family?.name);
      saved = result.isSuccess;
      return result;
    });
    if (!mounted) return;
    if (saved) {
      Navigator.of(context).pop();
    } else {
      setState(() => _opening = false);
    }
  }

  Widget _choice(String title, VoidCallback onTap, {bool custom = false}) =>
      AppSuggestionTile(
          label: title, onTap: _opening ? null : onTap, isNew: custom);

  @override
  Widget build(BuildContext context) {
    final suggestions = (kSuggestedFieldKeys[widget.category] ?? <String>[])
        .where((key) => !_existing.contains(key));
    final showNewSetting =
        _custom || (!_loading && !_failed && suggestions.isEmpty);
    return Padding(
        padding: EdgeInsets.fromLTRB(
            22, 12, 22, MediaQuery.viewInsetsOf(context).bottom + 28),
        child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const AppSheetHandle(),
              const SizedBox(height: 18),
              Row(children: [
                if (_custom && suggestions.isNotEmpty)
                  IconButton(
                      tooltip: 'Back',
                      onPressed: () => setState(() => _custom = false),
                      icon: const Icon(CupertinoIcons.chevron_left, size: 20)),
                Expanded(
                    child: Text(showNewSetting ? 'New setting' : 'Add setting',
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.w600))),
              ]),
              const SizedBox(height: 22),
              if (_loading)
                const Center(child: CircularProgressIndicator.adaptive())
              else if (_failed)
                AppErrorBanner(
                    message: 'Couldn’t load your settings.', onRetry: _load)
              else if (!showNewSetting) ...[
                for (final key in suggestions) _choice(key, () => _edit(key)),
                _choice('New setting…', () => setState(() => _custom = true),
                    custom: true),
              ] else ...[
                AppTextField(
                    controller: _name,
                    hint: 'Setting name',
                    autofocus: true,
                    errorText: _nameError,
                    textInputAction: TextInputAction.next,
                    onChanged: (_) => setState(() => _nameError = null)),
                const SizedBox(height: 14),
                if (!kFieldMeta.containsKey(_name.text.trim()))
                  AppSelect<UnitFamily>(
                      label: 'Value type',
                      value: _family,
                      items: UnitFamily.values
                          .map((family) => DropdownMenuItem(
                              value: family,
                              child: Text(_kFamilyLabel[family]!)))
                          .toList(),
                      onChanged: (family) {
                        if (family != null) setState(() => _family = family);
                      }),
                const SizedBox(height: 24),
                AppActionButton(
                    label: 'Continue',
                    onPressed: _opening
                        ? null
                        : () => _edit(_name.text,
                            family: kFieldMeta[_name.text.trim()]?.family ??
                                _family)),
              ],
            ]));
  }
}
