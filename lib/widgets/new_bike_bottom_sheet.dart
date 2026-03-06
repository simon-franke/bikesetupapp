import 'package:bikesetupapp/app_pages/home_page.dart';
import 'package:bikesetupapp/app_services/app_routes.dart';
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
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => _NewBikeSheetContent(
      user: user,
      mode: mode,
      initialBikeType: bikeType,
      uBikeID: uBikeID,
      bikeName: bikeName,
      uSetupID: uSetupID,
      setupName: setupName,
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

  const _NewBikeSheetContent({
    required this.user,
    required this.mode,
    required this.initialBikeType,
    required this.uBikeID,
    required this.bikeName,
    required this.uSetupID,
    required this.setupName,
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
  late Future<void> _initFuture;

  BikeType get _activeBikeType =>
      widget.mode == NewBikeMode.newBike ? _selectedBikeType : widget.initialBikeType;

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

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a name')),
      );
      return;
    }
    setState(() => _isSaving = true);

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
            const SnackBar(content: Text('Failed to create bike. Please try again.')),
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
      Navigator.of(context).push(
        AppRoutes.fadeSlide(MyHomePage(
          user: widget.user,
          bikeType: bikeType,
          bikeName: bikeName,
          uBikeID: uBikeID,
          setupName: setupName,
          uSetupID: uSetupID,
        )),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
                // Drag handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Theme.of(context).dividerColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Title
                Center(
                  child: Text(
                    widget.mode.appBarTitle,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                const SizedBox(height: 20),
                // Bike type image cards (newBike only)
                if (widget.mode == NewBikeMode.newBike) ...[
                  SizedBox(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: BikeType.values
                          .where((bt) => bt != BikeType.error)
                          .length,
                      itemBuilder: (context, index) {
                        final bt = BikeType.values
                            .where((bt) => bt != BikeType.error)
                            .elementAt(index);
                        final selected = _selectedBikeType == bt;
                        final fabColor = Theme.of(context)
                                .floatingActionButtonTheme
                                .backgroundColor ??
                            Theme.of(context).colorScheme.primary;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () =>
                                setState(() => _selectedBikeType = bt),
                            child: Container(
                              width: 96,
                              height: 116,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: selected
                                      ? fabColor
                                      : Theme.of(context).dividerColor,
                                  width: selected ? 2 : 1,
                                ),
                                color: selected
                                    ? fabColor.withValues(alpha: 0.1)
                                    : Colors.transparent,
                              ),
                              child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    height: 56,
                                    child: Builder(
                                      builder: (context) {
                                        final isDark = Theme.of(context).brightness == Brightness.dark;
                                        final image = Image.asset(bt.path, height: 56, fit: BoxFit.contain);
                                        return isDark
                                            ? ColorFiltered(
                                                colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                                                child: image,
                                              )
                                            : image;
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    _chipLabel(bt),
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall,
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                // Name field
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: widget.mode == NewBikeMode.newBike
                          ? 'Bike Name'
                          : 'Setup Name',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Conditional suspension fields (animated to avoid layout jump)
                AnimatedSize(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Fork type
                      if (_activeBikeType.hasFork) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: DropdownButtonFormField<String>(
                            initialValue: _forkType,
                            decoration: const InputDecoration(
                              labelText: 'Fork Type',
                              border: OutlineInputBorder(),
                            ),
                            items: _suspensionTypes
                                .map((s) =>
                                    DropdownMenuItem(value: s, child: Text(s)))
                                .toList(),
                            onChanged: (v) {
                              if (v != null) setState(() => _forkType = v);
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      // Shock type
                      if (_activeBikeType.hasShock) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: DropdownButtonFormField<String>(
                            initialValue: _shockType,
                            decoration: const InputDecoration(
                              labelText: 'Shock Type',
                              border: OutlineInputBorder(),
                            ),
                            items: _suspensionTypes
                                .map((s) =>
                                    DropdownMenuItem(value: s, child: Text(s)))
                                .toList(),
                            onChanged: (v) {
                              if (v != null) setState(() => _shockType = v);
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      // Front travel
                      if (_activeBikeType.hasFork) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: TextField(
                            controller: _frontTravelController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Front Travel',
                              suffixText: 'mm',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      // Rear travel
                      if (_activeBikeType.hasShock) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: TextField(
                            controller: _rearTravelController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Rear Travel',
                              suffixText: 'mm',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ],
                  ),
                ),
                // Rear wheel size
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    controller: _rearWheelSizeController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Rear Wheel Size',
                      suffixText: '"',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Front wheel size
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    controller: _frontWheelSizeController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Front Wheel Size',
                      suffixText: '"',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Buttons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 12),
                      FilledButton(
                        onPressed: _isSaving ? null : _save,
                        child: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator.adaptive(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Save'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }
}
