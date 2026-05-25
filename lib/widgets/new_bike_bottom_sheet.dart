import 'package:bikesetupapp/alert_dialogs/dialog_helpers.dart';
import 'package:bikesetupapp/app_services/theme_data.dart';
import 'package:bikesetupapp/bike_enums/bike_type.dart';
import 'package:bikesetupapp/bike_enums/new_bike_mode.dart';
import 'package:bikesetupapp/database_service/database.dart';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';

Future<void> showNewBikeSheet(
  BuildContext context,
  User user,
  NewBikeMode mode, {
  BikeType bikeType = BikeType.dh,
  String uBikeID = '',
  String bikeName = '',
  String uSetupID = '',
  String setupName = '',
  required void Function(String, String, BikeType, String, String)
      onBikeSelected,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: context.palette.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (context) => _NewBikeSheetContent(
      user: user,
      mode: mode,
      initialBikeType: bikeType,
      uBikeID: uBikeID,
      bikeName: bikeName,
      uSetupID: uSetupID,
      setupName: setupName,
      onBikeSelected: onBikeSelected,
    ),
  );
}

class _NewBikeSheetContent extends StatefulWidget {
  final User user;
  final NewBikeMode mode;
  final BikeType initialBikeType;
  final String uBikeID;
  final String bikeName;
  final String uSetupID;
  final String setupName;
  final void Function(String, String, BikeType, String, String) onBikeSelected;

  const _NewBikeSheetContent({
    required this.user,
    required this.mode,
    required this.initialBikeType,
    required this.uBikeID,
    required this.bikeName,
    required this.uSetupID,
    required this.setupName,
    required this.onBikeSelected,
  });

  @override
  State<_NewBikeSheetContent> createState() => _NewBikeSheetContentState();
}

class _NewBikeSheetContentState extends State<_NewBikeSheetContent>
    with SingleTickerProviderStateMixin {
  late BikeType _selectedBikeType;
  late TextEditingController _nameController;
  late TextEditingController _frontTravelController;
  late TextEditingController _rearTravelController;
  late TextEditingController _frontWheelSizeController;
  late TextEditingController _rearWheelSizeController;

  final List<String> _suspensionTypes = ['Air', 'Coil'];
  String _forkType = 'Air';
  String _shockType = 'Air';
  bool _isSaving = false;
  String? _nameError;
  late Future<void> _initFuture;

  BikeType get _activeBikeType => widget.mode == NewBikeMode.newBike
      ? _selectedBikeType
      : widget.initialBikeType;

  @override
  void initState() {
    super.initState();
    _selectedBikeType = widget.initialBikeType;
    _nameController = TextEditingController(
      text: widget.mode.isEdit ? widget.setupName : '',
    );
    _frontTravelController = TextEditingController();
    _rearTravelController = TextEditingController();
    _frontWheelSizeController = TextEditingController();
    _rearWheelSizeController = TextEditingController();

    if (widget.mode == NewBikeMode.editSetup) {
      _initFuture = _loadExistingData();
    } else {
      _initFuture = Future.value();
    }
  }

  Future<void> _loadExistingData() async {
    final data = await DatabaseService(widget.user.uid)
        .getSetupInformationAsMap(widget.uBikeID, widget.uSetupID);
    setState(() {
      _frontTravelController.text =
          (data['front_travel'] ?? '').toString().replaceAll('mm', '');
      _rearTravelController.text =
          (data['rear_travel'] ?? '').toString().replaceAll('mm', '');
      _frontWheelSizeController.text =
          (data['front_wheel_size'] ?? '').toString().replaceAll('"', '');
      _rearWheelSizeController.text =
          (data['rear_wheel_size'] ?? '').toString().replaceAll('"', '');
      _forkType = (data['fork'] ?? _forkType).toString();
      _shockType = (data['shock'] ?? _shockType).toString();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _frontTravelController.dispose();
    _rearTravelController.dispose();
    _frontWheelSizeController.dispose();
    _rearWheelSizeController.dispose();
    super.dispose();
  }

  String _chipLabel(BikeType bt) {
    switch (bt) {
      case BikeType.dh:
        return 'Downhill';
      case BikeType.enduro:
        return 'Enduro';
      case BikeType.dirtjump:
        return 'Dirt Jump';
      case BikeType.xc:
        return 'Cross Country';
      case BikeType.singlespeed:
        return 'Singlespeed';
      case BikeType.road:
        return 'Road';
      default:
        return bt.name;
    }
  }

  String _titleText() {
    if (widget.mode == NewBikeMode.newBike) {
      return _chipLabel(_selectedBikeType);
    }
    return widget.bikeName.isEmpty ? widget.mode.appBarTitle : widget.bikeName;
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = widget.mode == NewBikeMode.newBike
          ? 'Please enter a bike name'
          : 'Please enter a setup name');
      return;
    }
    setState(() {
      _nameError = null;
      _isSaving = true;
    });

    final setupInformation = {
      'fork': _forkType,
      'shock': _shockType,
      'front_travel': _frontTravelController.text,
      'rear_travel': _rearTravelController.text,
      'front_wheel_size': _frontWheelSizeController.text,
      'rear_wheel_size': _rearWheelSizeController.text,
    };

    final String bikeName;
    final String setupName;
    final String uBikeID;
    final String uSetupID;
    final BikeType bikeType = _activeBikeType;

    if (widget.mode == NewBikeMode.newBike) {
      setupName = 'Default';
      bikeName = name;
      try {
        uBikeID = await DatabaseService(widget.user.uid)
            .createBike(name, setupInformation, bikeType.bikeType);
      } catch (e) {
        setState(() => _isSaving = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Failed to create bike. Please try again.')),
          );
        }
        return;
      }
      uSetupID =
          await DatabaseService(widget.user.uid).getDefaultSetup(uBikeID);
      if (uSetupID.isEmpty) {
        setState(() => _isSaving = false);
        return;
      }
    } else if (widget.mode == NewBikeMode.newSetup) {
      setupName = name;
      bikeName = widget.bikeName;
      uBikeID = widget.uBikeID;
      uSetupID = const Uuid().v4();
      await DatabaseService(widget.user.uid)
          .createSetup(uBikeID, uSetupID, name, setupInformation);
    } else {
      // editSetup
      setupName = name;
      bikeName = widget.bikeName;
      uBikeID = widget.uBikeID;
      uSetupID = widget.uSetupID;
      await DatabaseService(widget.user.uid)
          .createSetup(uBikeID, uSetupID, name, setupInformation);
    }

    if (mounted) {
      final cb = widget.onBikeSelected;
      Navigator.of(context).pop();
      cb(bikeName, uBikeID, bikeType, setupName, uSetupID);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return FutureBuilder<void>(
      future: _initFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 200,
            child: Center(child: CircularProgressIndicator.adaptive()),
          );
        }
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 12),
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: p.borderStrong,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.mode.appBarTitle.toUpperCase(),
                        style: AppTextStyles.inter(
                          size: 10,
                          weight: FontWeight.w700,
                          color: p.inkDim,
                          letterSpacing: 1.4,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _titleText(),
                        style: AppTextStyles.inter(
                          size: 20,
                          weight: FontWeight.w700,
                          color: p.ink,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                if (widget.mode == NewBikeMode.newBike) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: _SectionHeader('BIKE TYPE'),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 124,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: BikeType.values
                          .where((bt) => bt != BikeType.error)
                          .length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (context, index) {
                        final bt = BikeType.values
                            .where((bt) => bt != BikeType.error)
                            .elementAt(index);
                        final selected = _selectedBikeType == bt;
                        return InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () =>
                              setState(() => _selectedBikeType = bt),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            curve: Curves.easeOut,
                            width: 92,
                            height: 124,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: selected ? p.accent : p.border,
                                width: selected ? 2 : 1,
                              ),
                              color: selected
                                  ? p.accent.withValues(alpha: 0.10)
                                  : Colors.transparent,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 10),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    height: 56,
                                    child: _BikeIcon(path: bt.path),
                                  ),
                                  const SizedBox(height: 8),
                                  Expanded(
                                    child: Text(
                                      _chipLabel(bt),
                                      style: AppTextStyles.inter(
                                        size: 11,
                                        weight: selected
                                            ? FontWeight.w700
                                            : FontWeight.w600,
                                        color:
                                            selected ? p.ink : p.inkMuted,
                                        height: 1.2,
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 22),
                ],
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const _SectionHeader('DETAILS'),
                      const SizedBox(height: 10),
                      _FieldLabel(widget.mode == NewBikeMode.newBike
                          ? 'Bike name'
                          : 'Setup name'),
                      const SizedBox(height: 6),
                      _PolishedTextField(
                        controller: _nameController,
                        hint: widget.mode.hintTextTextField,
                        errorText: _nameError,
                        textInputAction: TextInputAction.next,
                        onChanged: (_) {
                          if (_nameError != null) {
                            setState(() => _nameError = null);
                          }
                        },
                      ),
                    ],
                  ),
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_activeBikeType.hasFork ||
                          _activeBikeType.hasShock) ...[
                        const SizedBox(height: 20),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20),
                          child: _SectionHeader('SUSPENSION'),
                        ),
                        const SizedBox(height: 10),
                      ],
                      if (_activeBikeType.hasFork)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    const _FieldLabel('Fork type'),
                                    const SizedBox(height: 6),
                                    _PolishedDropdown(
                                      value: _forkType,
                                      items: _suspensionTypes,
                                      onChanged: (v) {
                                        if (v != null) {
                                          setState(() => _forkType = v);
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    const _FieldLabel('Front travel'),
                                    const SizedBox(height: 6),
                                    _PolishedTextField(
                                      controller: _frontTravelController,
                                      hint: '0',
                                      keyboardType: TextInputType.number,
                                      textInputAction: TextInputAction.next,
                                      suffix: 'mm',
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (_activeBikeType.hasShock) ...[
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    const _FieldLabel('Shock type'),
                                    const SizedBox(height: 6),
                                    _PolishedDropdown(
                                      value: _shockType,
                                      items: _suspensionTypes,
                                      onChanged: (v) {
                                        if (v != null) {
                                          setState(() => _shockType = v);
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    const _FieldLabel('Rear travel'),
                                    const SizedBox(height: 6),
                                    _PolishedTextField(
                                      controller: _rearTravelController,
                                      hint: '0',
                                      keyboardType: TextInputType.number,
                                      textInputAction: TextInputAction.next,
                                      suffix: 'mm',
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const _SectionHeader('WHEELS'),
                      const SizedBox(height: 10),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const _FieldLabel('Front wheel'),
                                const SizedBox(height: 6),
                                _PolishedTextField(
                                  controller: _frontWheelSizeController,
                                  hint: '0',
                                  keyboardType: TextInputType.number,
                                  textInputAction: TextInputAction.next,
                                  suffix: '"',
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const _FieldLabel('Rear wheel'),
                                const SizedBox(height: 6),
                                _PolishedTextField(
                                  controller: _rearWheelSizeController,
                                  hint: '0',
                                  keyboardType: TextInputType.number,
                                  textInputAction: TextInputAction.done,
                                  suffix: '"',
                                  onSubmitted: (_) {
                                    if (!_isSaving) _save();
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      DialogSecondaryButton(
                        label: 'Cancel',
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: 8),
                      _SaveButton(
                        isSaving: _isSaving,
                        onPressed: _isSaving ? null : _save,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader(this.label);

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Text(
      label,
      style: AppTextStyles.inter(
        size: 11,
        weight: FontWeight.w800,
        color: p.inkMuted,
        letterSpacing: 1.5,
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String label;
  const _FieldLabel(this.label);

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Text(
      label.toUpperCase(),
      style: AppTextStyles.inter(
        size: 10,
        weight: FontWeight.w700,
        color: p.inkDim,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _PolishedTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final String? errorText;
  final String? suffix;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  const _PolishedTextField({
    required this.controller,
    required this.hint,
    this.errorText,
    this.suffix,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      cursorColor: p.accent,
      style: AppTextStyles.inter(size: 14, color: p.ink),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTextStyles.inter(size: 14, color: p.inkDim),
        errorText: errorText,
        errorStyle: AppTextStyles.inter(size: 11, color: p.red),
        suffixText: suffix,
        suffixStyle: AppTextStyles.inter(size: 13, color: p.inkMuted),
        filled: true,
        fillColor: p.surface2,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: p.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: p.red, width: 1.4),
        ),
      ),
    );
  }
}

class _PolishedDropdown extends StatelessWidget {
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _PolishedDropdown({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return DropdownButtonFormField<String>(
      initialValue: value,
      icon: Icon(Icons.keyboard_arrow_down_rounded, color: p.inkMuted),
      dropdownColor: p.surface,
      style: AppTextStyles.inter(size: 14, color: p.ink),
      decoration: InputDecoration(
        filled: true,
        fillColor: p.surface2,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
      items: items
          .map((s) => DropdownMenuItem(
                value: s,
                child: Text(s,
                    style: AppTextStyles.inter(size: 14, color: p.ink)),
              ))
          .toList(),
      onChanged: onChanged,
    );
  }
}

class _BikeIcon extends StatelessWidget {
  final String path;
  const _BikeIcon({required this.path});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final image = Image.asset(path, height: 56, fit: BoxFit.contain);
    if (!isDark) return image;
    return ColorFiltered(
      colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
      child: image,
    );
  }
}

class _SaveButton extends StatelessWidget {
  final bool isSaving;
  final VoidCallback? onPressed;

  const _SaveButton({required this.isSaving, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: p.accent,
        foregroundColor: p.accentInk,
        disabledBackgroundColor: p.accent.withValues(alpha: 0.6),
        disabledForegroundColor: p.accentInk,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      child: isSaving
          ? SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(p.accentInk),
              ),
            )
          : Text(
              'SAVE',
              style: AppTextStyles.inter(
                size: 12,
                weight: FontWeight.w800,
                color: p.accentInk,
                letterSpacing: 0.8,
              ),
            ),
    );
  }
}
