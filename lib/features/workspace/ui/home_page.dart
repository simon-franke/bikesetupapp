import 'package:bikesetupapp/features/setups/models/setup_configuration.dart';
import 'package:flutter/cupertino.dart';
import 'workspace_transition.dart';
import 'package:bikesetupapp/features/setups/ui/setup_category_view.dart';
import 'package:bikesetupapp/common/ui/command_feedback.dart';
import '../controllers/workspace_controller.dart';
import 'package:bikesetupapp/app/app_dependencies.dart';
import 'package:bikesetupapp/features/maintenance/ui/add_component_bottom_sheet.dart';
import 'package:bikesetupapp/features/auth/ui/google_sign_in.dart';
import 'package:bikesetupapp/features/settings/ui/settings_page.dart';
import 'package:bikesetupapp/app/routing/app_routes.dart';
import 'package:bikesetupapp/common/layout/responsive_layout.dart';
import 'package:bikesetupapp/common/theme/theme_data.dart';
import 'package:bikesetupapp/features/bikes/ui/bike_chooser_sheet.dart';
import 'package:bikesetupapp/features/setups/ui/setup_overview.dart';
import 'package:bikesetupapp/features/tests/ui/tests_view.dart';
import 'package:bikesetupapp/features/maintenance/ui/services_view.dart';
import 'package:bikesetupapp/features/workspace/ui/view_toggle.dart';
import 'package:bikesetupapp/features/setups/models/category.dart';

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MyHomePage extends StatefulWidget {
  final User? user;
  final String bikeName;
  final String uBikeID;

  final String setupName;
  final String uSetupID;
  const MyHomePage(
      {super.key,
      required this.user,

      required this.bikeName,
      required this.uBikeID,
      required this.setupName,
      required this.uSetupID});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late final WorkspaceController _workspace;
  String? _detailCategory;
  String _configurationScope = '';
  late Future<SetupConfiguration?> _configurationFuture;

  void _bindConfiguration() {
    final scope = '${widget.user?.uid}/$_uBikeID/$_uSetupID';
    if (_configurationScope == scope) return;
    _configurationScope = scope;
    _configurationFuture = widget.user == null || _uBikeID.isEmpty || _uSetupID.isEmpty
        ? Future.value(null)
        : AppDependencies.of(context).forUser(widget.user!.uid).setups
            .getSetupInformation(_uBikeID, _uSetupID)
            .then(SetupConfiguration.fromInformation);
  }

  Future<void> _startTest() async {
    final saved = await presentCommand(
        context,
        () => AppDependencies.of(context)
            .forUser(widget.user!.uid)
            .tests
            .create(
                _uBikeID, _uSetupID, _setupName, setupCategories()));
    if (mounted && saved) _workspace.selectView(ActiveView.tests);
  }

  Category get chosenCategory => _workspace.category;
  String get _bikeName => _workspace.bikeName;
  String get _uBikeID => _workspace.bikeId;
  String get _setupName => _workspace.setupName;
  String get _uSetupID => _workspace.setupId;
  ActiveView get _activeView => _workspace.activeView;
  bool get _showServiceAlert => _workspace.serviceAlert;
  double? get _currentMileageKm => _workspace.mileageKm;

  @override
  void initState() {
    super.initState();
    _workspace = WorkspaceController(
        bikeName: widget.bikeName,
        bikeId: widget.uBikeID,

        setupName: widget.setupName,
        setupId: widget.uSetupID,
        strava: widget.user == null
            ? null
            : AppDependencies.of(context).forUser(widget.user!.uid).strava)
      ..addListener(_changed);
    _bindConfiguration();
    if (widget.user == null || _uBikeID.isEmpty || _uSetupID.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).push(AppRoutes.fadeSlide(const LoginPage()));
        }
      });
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) presentCommand(context, _workspace.loadMileage);
    });
  }

  void _changed() {
    _bindConfiguration();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _workspace.dispose();
    super.dispose();
  }

  void _onBikeSelected(String bikeName, String uBikeID,
      String setupName, String uSetupID) {
    _detailCategory = null;
    _configurationScope = '';
    presentCommand(
        context,
        () => _workspace.selectBike(
            bikeName, uBikeID, setupName, uSetupID));
  }

  Widget _buildSetupView(BuildContext context, double contentWidth, SetupConfiguration? configuration) =>
      _detailCategory != null
          ? SetupCategoryView(
              key: ValueKey('$_uBikeID/$_uSetupID/$_detailCategory'),
              user: widget.user!,
              bike: _uBikeID,
              setup: _uSetupID,
              category: _detailCategory!,
              configuration: configuration,
              onTest: _startTest)
          : SetupOverview(
              key: ValueKey('$_uBikeID/$_uSetupID'),
              user: widget.user!,
              bike: _uBikeID,
              setup: _uSetupID,
              configuration: configuration,
              onCategory: (category) =>
                  setState(() => _detailCategory = category));

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final p = context.palette;
    if (_activeView == ActiveView.setup && _detailCategory != null) {
      return AppBar(
          automaticallyImplyLeading: false,
          toolbarHeight: math.max(112, MediaQuery.textScalerOf(context).scale(32) * 3),
          centerTitle: false,
          titleSpacing: 20,
          title: SizedBox(
              width: double.infinity,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextButton.icon(
                        style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            alignment: Alignment.centerLeft),
                        onPressed: () => setState(() => _detailCategory = null),
                        icon: const Icon(CupertinoIcons.chevron_left, size: 18),
                        label: const Text('Setup')),
                    Text(categoryLabel(_detailCategory!),
                        style: AppTextStyles.inter(
                            size: 30, weight: FontWeight.w700, color: p.ink)),
                    const SizedBox(height: 8),
                    Text(_setupName,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: p.inkMuted))
                  ])));
    }
    return AppBar(
      automaticallyImplyLeading: false,
      toolbarHeight: math.max(80, MediaQuery.textScalerOf(context).scale(32) * 2.2),
      titleSpacing: 20,
      centerTitle: false,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_bikeName,
              style: AppTextStyles.inter(size: 13, color: p.inkMuted),
              maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Row(children: [
            Expanded(
              child: InkWell(
                onTap: _showBikeSelector,
                child: Semantics(
                  button: true,
                  label: 'Choose bike and setup',
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 48),
                    child: Row(children: [
                      Flexible(
                        child: Text(_setupName,
                            style: AppTextStyles.inter(
                                size: 30, weight: FontWeight.w700,
                                color: p.ink, letterSpacing: -1),
                            maxLines: 1, overflow: TextOverflow.ellipsis)),
                      const SizedBox(width: 8),
                      Icon(CupertinoIcons.chevron_down,
                          color: p.inkMuted, size: 15),
                    ]),
                  ),
                ),
              ),
            ),
            IconButton(
                tooltip: 'Settings',
                icon: const Icon(CupertinoIcons.gear_alt, size: 20),
                onPressed: () => Navigator.of(context).push(AppRoutes.fadeSlide(
                    SettingsPage(bikeName: _bikeName,
                        chosenSetup: _setupName)))),
          ]),
        ],
      ),
    );
  }

  void _showBikeSelector() {
    final user = widget.user;
    if (user == null) return;
    showBikeChooserSheet(
      context: context,
      user: user,
      selectedBikeId: _uBikeID,
      selectedSetupId: _uSetupID,
      onBikeSelected: _onBikeSelected,
    );
  }

  Widget _buildBody(BuildContext context, double contentWidth) {
    if (widget.user == null) return const SizedBox.shrink();
    return FutureBuilder<SetupConfiguration?>(
      future: _configurationFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator.adaptive());
        }
        if (snapshot.hasError) {
          return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('Could not load this setup.'),
            TextButton(onPressed: () => setState(() {
              _configurationScope = '';
              _bindConfiguration();
            }), child: const Text('Retry')),
          ]));
        }
        return _buildWorkspace(context, contentWidth, snapshot.data);
      },
    );
  }

  Widget _buildWorkspace(BuildContext context, double contentWidth, SetupConfiguration? configuration) {
    return WorkspaceTransition(
      child: _activeView == ActiveView.setup
          ? KeyedSubtree(
              key: ValueKey('setup_$_uBikeID'),
              child: _buildSetupView(context, contentWidth, configuration),
            )
          : _activeView == ActiveView.tests
              ? TestsView(
                  key: ValueKey('tests_$_uBikeID/$_uSetupID'),
                  uid: widget.user!.uid,
                  bike: _uBikeID,
                  setup: _uSetupID,
                  setupName: _setupName,
                      onApplied: () => _workspace.selectView(ActiveView.setup),
                  onSetupSaved: (name, id) {
                    _onBikeSelected(_bikeName, _uBikeID, name, id);
                    _workspace.selectView(ActiveView.setup);
                  })
              : ServicesView(
                  key: ValueKey('services_$_uBikeID'),
                  bikeName: _bikeName,
                  user: widget.user!,
                  uBikeID: _uBikeID,
                  onAddComponent: _addComponent,
                  onAlertChanged: (hasAlert) {
                    if (_showServiceAlert != hasAlert) {
                      _workspace.setServiceAlert(hasAlert);
                    }
                  },
                ),
    );
  }

  Future<void> _addComponent() async {
    final loaded = await presentCommand(context, _workspace.loadMileage);
    if (!mounted || !loaded) return;
    await showAddComponentSheet(context,
        user: widget.user!,
        uBikeID: _uBikeID,
        currentMileageKm: _currentMileageKm);
  }

  @override
  Widget build(BuildContext context) {
    final wide = ResponsiveLayout.isWide(context);
    return Scaffold(
      extendBody: true,
      appBar: _buildAppBar(context),
      bottomNavigationBar: ViewToggle(
          activeView: _activeView,
          showServiceAlert: _showServiceAlert,
          onChanged: (view) {
            if (view == ActiveView.setup) _detailCategory = null;
            _workspace.selectView(view);
          }),
      body: SafeArea(
          top: false,
          bottom: false,
          child: AppContentFrame(
            maxWidth: wide ? double.infinity : kContentMaxWidth,
            child: Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: wide ? 24 : 0, vertical: wide ? 24 : 0),
              child: LayoutBuilder(
                  builder: (context, constraints) =>
                      _buildBody(context, constraints.maxWidth)),
            ),
          )),
      floatingActionButton: _activeView == ActiveView.services && !wide
          ? FloatingActionButton.extended(
              onPressed: _addComponent,
              icon: const Icon(CupertinoIcons.plus),
              label: const Text('Add component'))
          : null,
    );
  }
}
