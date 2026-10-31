import 'package:bikesetupapp/common/ui/app_haptics.dart';
import 'package:bikesetupapp/features/setups/ui/add_category_sheet.dart';
import 'package:bikesetupapp/common/ui/app_components.dart';
import 'package:bikesetupapp/common/ui/delete_confirmation_sheet.dart';
import 'package:bikesetupapp/features/setups/ui/field_meta.dart';
import 'package:bikesetupapp/common/ui/app_glass_surface.dart';
import 'package:bikesetupapp/common/ui/app_scroll_edge.dart';
import 'package:bikesetupapp/features/setups/models/setup_configuration.dart';
import 'package:flutter/cupertino.dart';
import 'workspace_transition.dart';
import 'workspace_activity_title.dart';
import '../../rides/ui/ride_log_page.dart';
import 'package:bikesetupapp/features/setups/ui/setup_category_view.dart';
import 'package:bikesetupapp/common/ui/command_feedback.dart';
import '../controllers/workspace_controller.dart';
import 'package:bikesetupapp/app/app_dependencies.dart';
import 'package:bikesetupapp/features/auth/ui/google_sign_in.dart';
import 'package:bikesetupapp/features/settings/ui/settings_page.dart';
import 'package:bikesetupapp/app/routing/app_routes.dart';
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
  final _contentNavigator = GlobalKey<NavigatorState>();

  late final WorkspaceController _workspace;
  String _configurationScope = '';
  late Future<SetupConfiguration?> _configurationFuture;

  void _bindConfiguration() {
    final scope = '${widget.user?.uid}/$_uBikeID/$_uSetupID';
    if (_configurationScope == scope) return;
    _configurationScope = scope;
    _configurationFuture =
        widget.user == null || _uBikeID.isEmpty || _uSetupID.isEmpty
            ? Future.value(null)
            : AppDependencies.of(context)
                .forUser(widget.user!.uid)
                .setups
                .getSetupInformation(_uBikeID, _uSetupID)
                .then(SetupConfiguration.fromInformation);
  }

  Category get chosenCategory => _workspace.category;
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

  void _onBikeSelected(
      String bikeName, String uBikeID, String setupName, String uSetupID) {
    _configurationScope = '';
    presentCommand(context,
        () => _workspace.selectBike(bikeName, uBikeID, setupName, uSetupID));
  }

  Widget _buildSetupView(BuildContext context, double contentWidth,
          SetupConfiguration? configuration) =>
      SetupOverview(
          key: ValueKey('$_uBikeID/$_uSetupID'),
          user: widget.user!,
          bike: _uBikeID,
          setup: _uSetupID,
          configuration: configuration,
          onAddCategory: () => _addCategory(configuration),
          onCategory: (category) => _openCategory(category, configuration));

  Future<bool> _changeCategory(String category, bool enabled) async {
    final saved = await presentCommand(
        context,
        () => AppDependencies.of(context)
            .forUser(widget.user!.uid)
            .setups
            .setCategoryEnabled(
              _uBikeID,
              _uSetupID,
              category,
              enabled,
              legacyFields: {
                for (final key in setupCategories())
                  key: kDefaultFieldKeys[key]!
              },
              addedFields: kDefaultFieldKeys,
            ));
    if (saved && mounted) {
      _configurationScope = '';
      _bindConfiguration();
      _workspace.selectView(_activeView);
    }
    return saved;
  }

  Future<void> _addCategory(SetupConfiguration? configuration) async {
    final active =
        configuration?.fields.keys.toSet() ?? setupCategories().toSet();
    final category = await showAddCategorySheet(context, active);
    if (category == null || !mounted) return;
    if (await _changeCategory(category, true) && mounted) {
      final configuration = await _configurationFuture;
      if (mounted) _openCategory(category, configuration);
    }
  }

  Future<void> _categoryOptions(
      BuildContext routeContext, String category) async {
    final action = await showAppOptionsSheet(
      context: routeContext,
      title: categoryLabel(category),
      entries: const [
        AppSheetOption(
            value: 'remove',
            label: 'Remove category',
            icon: CupertinoIcons.trash,
            destructive: true)
      ],
    );
    if (action != 'remove' || !routeContext.mounted) return;
    final confirmed = await showDeleteConfirmationSheet(
      routeContext,
      title: 'Remove ${categoryLabel(category)}?',
      message: 'Saved settings are kept if you add it again.',
      actionLabel: 'Remove',
    );
    if (!confirmed || !mounted || !routeContext.mounted) return;
    if (await _changeCategory(category, false) && routeContext.mounted) {
      Navigator.of(routeContext).pop();
    }
  }

  void _openCategory(String category, SetupConfiguration? configuration) {
    _contentNavigator.currentState!.push(AppRoutes.fadeSlide(Builder(
        builder: (routeContext) => Scaffold(
              extendBody: true,
              appBar: _buildAppBar(routeContext, category: category),
              body: AppScrollEdge(
                  child: SetupCategoryView(
                      user: widget.user!,
                      bike: _uBikeID,
                      setup: _uSetupID,
                      category: category,
                      configuration: configuration)),
            ))));
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, {String? category}) {
    final p = context.palette;
    if (category != null) {
      return AppBar(
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              tooltip: 'Category options',
              icon: const Icon(CupertinoIcons.ellipsis),
              onPressed:
                  AppHaptics.wrap(() => _categoryOptions(context, category)),
            )
          ],
          toolbarHeight:
              math.max(112, MediaQuery.textScalerOf(context).scale(32) * 3),
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
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(CupertinoIcons.chevron_left, size: 18),
                        label: const Text('Setup')),
                    Text(categoryLabel(category),
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
    return PreferredSize(
      preferredSize: Size.fromHeight(
          math.max(104, MediaQuery.textScalerOf(context).scale(28) * 2.6 + 24)),
      child: Stack(
        clipBehavior: Clip.none,
        fit: StackFit.expand,
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.viewPaddingOf(context).top + 8,
            child: IgnorePointer(
                child: DecoratedBox(
                    decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [p.bg, p.bg, p.bg.withValues(alpha: 0)],
                stops: const [0, 0.85, 1],
              ),
            ))),
          ),
          SafeArea(
              bottom: false,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Align(
                  alignment: Alignment.center,
                  child: AppGlassSurface(
                      child: Row(children: [
                    Expanded(
                        child: Material(
                      color: p.ink.withValues(alpha: .07),
                      borderRadius: BorderRadius.circular(25),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(25),
                        onTap: AppHaptics.wrap(_showBikeSelector),
                        child: Semantics(
                          button: true,
                          label: _activeView == ActiveView.services
                              ? 'Choose bike'
                              : 'Choose bike and setup',
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            child: ConstrainedBox(
                                constraints: BoxConstraints(
                                    minHeight: MediaQuery.textScalerOf(context)
                                                .scale(24) *
                                            1.4 +
                                        MediaQuery.textScalerOf(context)
                                                .scale(12) *
                                            1.4 +
                                        2),
                                child: Row(children: [
                                  Expanded(
                                      child: WorkspaceActivityTitle(
                                    key: ValueKey(
                                        'activity_${widget.user?.uid}/$_uBikeID'),
                                    uid: widget.user?.uid,
                                    bikeId: _uBikeID,
                                    mileageKm: _workspace.mileageKm,
                                    bikeName: _bikeName,
                                    setupName: _setupName,
                                    bikeOnly:
                                        _activeView == ActiveView.services,
                                  )),
                                  const SizedBox(width: 8),
                                  Icon(CupertinoIcons.chevron_down,
                                      color: p.inkMuted, size: 15),
                                ])),
                          ),
                        ),
                      ),
                    )),
                    TweenAnimationBuilder<double>(
                      tween: Tween(
                          end: _activeView == ActiveView.services ? 1 : 0),
                      duration: MediaQuery.disableAnimationsOf(context)
                          ? Duration.zero
                          : const Duration(milliseconds: 280),
                      curve: Curves.easeInOutCubic,
                      builder: (context, progress, child) => ClipRect(
                        child: Align(
                          widthFactor: progress,
                          heightFactor: 1,
                          child: IgnorePointer(
                            ignoring: _activeView != ActiveView.services,
                            child: ExcludeSemantics(
                              excluding: _activeView != ActiveView.services,
                              child: Opacity(
                                  opacity: progress,
                                  child: Transform.scale(
                                      scale: .8 + .2 * progress, child: child)),
                            ),
                          ),
                        ),
                      ),
                      child: IconButton(
                        tooltip: 'Ride activity',
                        icon: Icon(Icons.auto_stories_outlined,
                            size: 22, color: p.inkMuted),
                        onPressed: () async {
                          await Navigator.of(context).push(AppRoutes.fadeSlide(
                              RideLogPage(
                                  uid: widget.user!.uid,
                                  bikeId: _uBikeID,
                                  bikeName: _bikeName)));
                          if (context.mounted) {
                            presentCommand(context, _workspace.loadMileage);
                          }
                        },
                      ),
                    ),
                    Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: IconButton(
                          tooltip: 'Settings',
                          icon: const Icon(CupertinoIcons.gear_alt, size: 22),
                          onPressed: () => Navigator.of(context).push(
                              AppRoutes.fadeSlide(SettingsPage(
                                  bikeName: _bikeName,
                                  chosenSetup: _setupName))),
                        )),
                  ])),
                ),
              )),
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
      bikesOnly: _activeView == ActiveView.services,
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
        return _buildWorkspace(context, contentWidth, snapshot.data);
      },
    );
  }

  Widget _buildWorkspace(BuildContext context, double contentWidth,
      SetupConfiguration? configuration) {
    return WorkspaceTransition(
      key: ValueKey('${widget.user!.uid}/$_uBikeID/$_uSetupID'),
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
