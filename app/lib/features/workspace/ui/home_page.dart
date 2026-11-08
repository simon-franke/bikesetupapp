import 'setup_workspace.dart';
import 'workspace_header.dart';
import 'package:bikesetupapp/common/ui/app_loading.dart';
import 'package:bikesetupapp/features/setups/models/setup_configuration.dart';
import 'package:flutter/foundation.dart' show SynchronousFuture;
import 'workspace_transition.dart';
import '../../rides/ui/ride_log_page.dart';
import 'package:bikesetupapp/common/ui/command_feedback.dart';
import '../controllers/workspace_controller.dart';
import 'package:bikesetupapp/app/app_dependencies.dart';
import 'package:bikesetupapp/features/settings/ui/settings_page.dart';
import 'package:bikesetupapp/app/routing/app_routes.dart';
import 'package:bikesetupapp/features/bikes/ui/bike_chooser_sheet.dart';
import 'package:bikesetupapp/features/tests/ui/tests_view.dart';
import 'package:bikesetupapp/features/maintenance/ui/services_view.dart';
import 'package:bikesetupapp/features/workspace/ui/view_toggle.dart';

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MyHomePage extends StatefulWidget {
  final SetupConfiguration? initialConfiguration;
  final VoidCallback? onNoBikes;
  final User? user;
  final String bikeName;
  final String uBikeID;

  final String setupName;
  final String uSetupID;

  const MyHomePage(
      {super.key,
      required this.user,
      this.initialConfiguration,
      this.onNoBikes,
      required this.bikeName,
      required this.uBikeID,
      required this.setupName,
      required this.uSetupID});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _contentNavigator = GlobalKey<NavigatorState>();

  late final WorkspaceController _workspace;
  String _configurationScope = '';
  bool _initialConfigurationConsumed = false;
  late Future<SetupConfiguration?> _configurationFuture;

  void _bindConfiguration() {
    final scope = '${widget.user?.uid}/$_uBikeID/$_uSetupID';
    if (_configurationScope == scope) return;

    final firstConfiguration = !_initialConfigurationConsumed &&
        _uBikeID == widget.uBikeID &&
        _uSetupID == widget.uSetupID &&
        widget.initialConfiguration != null;
    _configurationScope = scope;
    _initialConfigurationConsumed = true;
    if (firstConfiguration) {
      _configurationFuture = SynchronousFuture(widget.initialConfiguration);
      return;
    }

    _configurationFuture =
        widget.user == null || _uBikeID.isEmpty || _uSetupID.isEmpty
            ? Future.value(null)
            : AppDependencies.of(context)
                .forUser(widget.user!.uid)
                .setups
                .getSetupInformation(_uBikeID, _uSetupID)
                .then(SetupConfiguration.fromInformation);
  }

  String get _bikeName => _workspace.bikeName;
  String get _uBikeID => _workspace.bikeId;
  String get _setupName => _workspace.setupName;
  String get _uSetupID => _workspace.setupId;
  ActiveView get _activeView => _workspace.activeView;
  bool get _showServiceAlert => _workspace.serviceAlert;

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

  void _onBikeSelected(
      String bikeName, String uBikeID, String setupName, String uSetupID) {
    _configurationScope = '';
    presentCommand(context,
        () => _workspace.selectBike(bikeName, uBikeID, setupName, uSetupID));
  }

  Future<SetupConfiguration?> _reloadConfiguration() {
    _configurationScope = '';
    _bindConfiguration();
    _workspace.selectView(_activeView);
    return _configurationFuture;
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) => WorkspaceHeader(
        height: math.max(
            104, MediaQuery.textScalerOf(context).scale(28) * 2.6 + 24),
        uid: widget.user?.uid,
        bikeId: _uBikeID,
        bikeName: _bikeName,
        setupName: _setupName,
        mileageKm: _workspace.mileageKm,
        activeView: _activeView,
        onChooseBike: _showBikeSelector,
        onRideActivity: () async {
          await Navigator.of(context).push(AppRoutes.fadeSlide(RideLogPage(
              uid: widget.user!.uid, bikeId: _uBikeID, bikeName: _bikeName)));
          if (context.mounted) presentCommand(context, _workspace.loadMileage);
        },
        onSettings: () => Navigator.of(context, rootNavigator: true).push(
            AppRoutes.fadeSlide(
                SettingsPage(bikeName: _bikeName, chosenSetup: _setupName))),
      );

  void _showBikeSelector() {
    final user = widget.user;
    if (user == null) return;

    showBikeChooserSheet(
      context: context,
      user: user,
      bikesOnly: _activeView == ActiveView.services,
      selectedBikeId: _uBikeID,
      selectedSetupId: _uSetupID,
      onBikeSelected: _onBikeSelected,
      onNoBikes: widget.onNoBikes,
    );
  }

  Widget _buildBody(BuildContext context, double contentWidth) {
    if (widget.user == null) return const SizedBox.shrink();

    return FutureBuilder<SetupConfiguration?>(
      key: ValueKey('${widget.user!.uid}/$_uBikeID/$_uSetupID'),
      future: _configurationFuture,
      builder: (context, snapshot) {
        // Keep category actions mounted while refreshing the same setup.
        if (snapshot.connectionState != ConnectionState.done &&
            !snapshot.hasData) {
          return const Center(child: AppLoadingState());
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('Could not load this setup.'),
            TextButton(
                onPressed: () => setState(() {
                      _configurationScope = '';
                      _bindConfiguration();
                    }),
                child: const Text('Retry')),
          ]));
        }

        return _buildWorkspace(context, contentWidth, snapshot.data!);
      },
    );
  }

  Widget _buildWorkspace(BuildContext context, double contentWidth,
      SetupConfiguration configuration) {
    return WorkspaceTransition(
      key: ValueKey('${widget.user!.uid}/$_uBikeID/$_uSetupID'),
      child: _activeView == ActiveView.setup
          ? KeyedSubtree(
              key: ValueKey('setup_$_uBikeID'),
              child: SetupWorkspace(
                  key: ValueKey('$_uBikeID/$_uSetupID'),
                  user: widget.user!,
                  bike: _uBikeID,
                  setup: _uSetupID,
                  configuration: configuration,
                  navigatorKey: _contentNavigator,
                  reloadConfiguration: _reloadConfiguration),
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
                  onAlertChanged: (hasAlert) {
                    if (_showServiceAlert != hasAlert) {
                      _workspace.setServiceAlert(hasAlert);
                    }
                  },
                ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        extendBody: true,
        bottomNavigationBar: ViewToggle(
            activeView: _activeView,
            showServiceAlert: _showServiceAlert,
            onChanged: (view) {
              _contentNavigator.currentState
                  ?.popUntil((route) => route.isFirst);
              _workspace.selectView(view);
            }),
        body: NavigatorPopHandler(
          onPopWithResult: (_) => _contentNavigator.currentState?.pop(),
          child: Navigator(
            key: _contentNavigator,
            onGenerateRoute: (_) => MaterialPageRoute<void>(
              builder: (context) => ListenableBuilder(
                listenable: _workspace,
                builder: (context, _) => Scaffold(
                  extendBody: true,
                  extendBodyBehindAppBar: true,
                  appBar: _buildAppBar(context),
                  body: SafeArea(
                      top: false,
                      bottom: false,
                      child: LayoutBuilder(
                          builder: (context, constraints) =>
                              _buildBody(context, constraints.maxWidth))),
                ),
              ),
            ),
          ),
        ),
      );
}
