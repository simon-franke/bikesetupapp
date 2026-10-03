import 'package:bikesetupapp/widgets/add_component_bottom_sheet.dart';
import 'package:bikesetupapp/app_pages/google_sign_in.dart';
import 'package:bikesetupapp/app_pages/settings_page.dart';
import 'package:bikesetupapp/app_services/app_routes.dart';
import 'package:bikesetupapp/app_services/responsive_layout.dart';
import 'package:bikesetupapp/app_services/theme_data.dart';
import 'package:bikesetupapp/database_service/service_database.dart';
import 'package:bikesetupapp/widgets/bike_chooser_sheet.dart';
import 'package:bikesetupapp/widgets/control_panel_grid.dart';
import 'package:bikesetupapp/widgets/home_page_bubbles.dart';
import 'package:bikesetupapp/widgets/services_view.dart';
import 'package:bikesetupapp/widgets/view_toggle.dart';
import 'package:bikesetupapp/bike_enums/bike_type.dart';
import 'package:bikesetupapp/bike_enums/category.dart';

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MyHomePage extends StatefulWidget {
  final User? user;
  final String bikeName;
  final String uBikeID;
  final BikeType bikeType;
  final String setupName;
  final String uSetupID;
  const MyHomePage(
      {super.key,
      required this.user,
      required this.bikeType,
      required this.bikeName,
      required this.uBikeID,
      required this.setupName,
      required this.uSetupID});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late Category chosenCategory;
  late String _bikeName;
  late String _uBikeID;
  late BikeType _bikeType;
  late String _setupName;
  late String _uSetupID;
  ActiveView _activeView = ActiveView.setup;
  bool _showServiceAlert = false;
  double? _currentMileageKm;

  @override
  void initState() {
    super.initState();
    _bikeName = widget.bikeName;
    _uBikeID = widget.uBikeID;
    _bikeType = widget.bikeType;
    _setupName = widget.setupName;
    _uSetupID = widget.uSetupID;
    chosenCategory = _initialCategoryFor(_bikeType);
    if (widget.user == null || _uBikeID.isEmpty || _uSetupID.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).push(AppRoutes.fadeSlide(const LoginPage()));
      });
    }
    _loadMileage();
  }

  Category _initialCategoryFor(BikeType t) {
    if (t.hasShock) return Category.shock;
    return Category.rearTire;
  }

  Future<void> _loadMileage() async {
    if (widget.user == null) return;
    final bikeID = _uBikeID;
    final db = ServiceDatabaseService(widget.user!.uid);
    final km = await db.getMileageForBike(bikeID);
    if (mounted && bikeID == _uBikeID) {
      setState(() => _currentMileageKm = km);
    }
  }

  void _onBikeSelected(String bikeName, String uBikeID, BikeType bikeType,
      String setupName, String uSetupID) {
    setState(() {
      _bikeName = bikeName;
      _uBikeID = uBikeID;
      _bikeType = bikeType;
      _setupName = setupName;
      _uSetupID = uSetupID;
      chosenCategory = _initialCategoryFor(bikeType);
    });
    _loadMileage();
  }

  Widget _buildBikeHeader(
      BuildContext context, double contentWidth, double headerHeight) {
    final wide = ResponsiveLayout.isWide(context);
    final p = context.palette;
    const double imgNativeW = 1080.0, imgNativeH = 664.0;
    final double padL = wide ? 12 : 24, padR = wide ? 12 : 24;
    final double padT = wide ? 24 : 40, padB = wide ? 24 : 28;
    final double availW =
        contentWidth - (ResponsiveLayout.isWide(context) ? 0 : 24);
    final double availH = headerHeight;
    final double padW = availW - padL - padR;
    final double padH = availH - padT - padB;
    final double scale = math.min(padW / imgNativeW, padH / imgNativeH);
    final double imgRenderW = imgNativeW * scale;
    final double imgRenderH = imgNativeH * scale;
    final double imgLeft = padL + (padW - imgRenderW) / 2;
    final double imgTop = padT + (padH - imgRenderH) / 2;

    final anchors = _kBikeAnchors[_bikeType] ?? _kBikeAnchors[BikeType.enduro]!;
    double anchorL(_AnchorFrac f) => imgLeft + f.fx * imgRenderW;
    double anchorB(_AnchorFrac f) => availH - (imgTop + f.fy * imgRenderH);

    final double rtAnchorL = anchorL(anchors.rearTire);
    final double rtAnchorB = anchorB(anchors.rearTire);
    final double ftAnchorL = anchorL(anchors.frontTire);
    final double ftAnchorB = anchorB(anchors.frontTire);
    final double shAnchorL = anchorL(anchors.shock ?? anchors.geometry);
    final double shAnchorB = anchorB(anchors.shock ?? anchors.geometry);
    final double gsAnchorL = anchorL(anchors.geometry);
    final double gsAnchorB = anchorB(anchors.geometry);
    final double fkAnchorL = anchorL(anchors.fork ?? anchors.frontTire);
    final double fkAnchorB = anchorB(anchors.fork ?? anchors.frontTire);

    // Bubble card slot positions — corners/edges of the panel, chosen to stay
    // off the bike silhouette. Layout depends on which parts the bike has.
    final cardSize = schematicCardSize(context);
    final bubbleCardW = cardSize.width;
    final bubbleCardH = cardSize.height;
    const double sideGap = 16, topGap = 16, botGap = 16;
    final double topRow = wide
        ? (availH - imgTop - bubbleCardH / 2)
            .clamp(botGap, availH - bubbleCardH - topGap)
        : availH - bubbleCardH - topGap;
    final double botRow = wide
        ? (availH - imgTop - imgRenderH - bubbleCardH / 2)
            .clamp(botGap, availH - bubbleCardH - topGap)
        : botGap;
    final double midRow = (availH - bubbleCardH) / 2;
    final double leftCol = sideGap;
    final double rightCol = availW - bubbleCardW - sideGap;
    final double midCol = (availW - bubbleCardW) / 2;

    final double rtBubbleL, rtBubbleB;
    final double ftBubbleL, ftBubbleB;
    final double shBubbleL, shBubbleB;
    final double fkBubbleL, fkBubbleB;
    final double gsBubbleL, gsBubbleB;

    if (_bikeType.hasShock) {
      // DH, Enduro: rear/shock/fork across the top row, front on right-middle.
      rtBubbleL = leftCol;
      rtBubbleB = topRow;
      shBubbleL = availW < bubbleCardW * 3 + 48 ? leftCol : midCol;
      shBubbleB = availW < bubbleCardW * 3 + 48 ? midRow : topRow;
      fkBubbleL = rightCol;
      fkBubbleB = topRow;
      ftBubbleL = rightCol;
      ftBubbleB = midRow;
    } else if (_bikeType.hasFork) {
      // Dirt, XC: rear left-middle, fork top-right, front right-middle.
      rtBubbleL = leftCol;
      rtBubbleB = midRow;
      fkBubbleL = rightCol;
      fkBubbleB = topRow;
      ftBubbleL = rightCol;
      ftBubbleB = midRow;
      shBubbleL = midCol;
      shBubbleB = topRow; // unused (show=false)
    } else {
      // Singlespeed, Road: rear left-middle, front right-middle.
      rtBubbleL = leftCol;
      rtBubbleB = midRow;
      ftBubbleL = rightCol;
      ftBubbleB = midRow;
      shBubbleL = midCol;
      shBubbleB = topRow; // unused
      fkBubbleL = rightCol;
      fkBubbleB = topRow; // unused
    }
    gsBubbleL = midCol;
    gsBubbleB = botRow;

    return Container(
      margin: EdgeInsets.symmetric(
          horizontal: ResponsiveLayout.isWide(context) ? 0 : 12),
      height: headerHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(padL, padT, padR, padB),
            child: Center(
              child: Image.asset(
                _bikeType.path,
                fit: BoxFit.contain,
                color: p.inkMuted,
                colorBlendMode: BlendMode.srcIn,
              ),
            ),
          ),
          SchematicBubble(
            user: widget.user!,
            anchorLeft: rtAnchorL,
            anchorBottom: rtAnchorB,
            bubbleLeft: rtBubbleL,
            bubbleBottom: rtBubbleB,
            containerHeight: headerHeight,
            bikeName: _uBikeID,
            category: Category.rearTire,
            chosenCategory: chosenCategory,
            setup: _uSetupID,
            onPressed: () => setState(() => chosenCategory = Category.rearTire),
            onValueChange: (value) {
              chosenCategory = Category.rearTire;
              showSettingStepperSheet(
                context,
                user: widget.user!,
                uBikeID: _uBikeID,
                category: chosenCategory.category,
                uSetupID: _uSetupID,
                settingKey: 'Pressure',
                currentValue: value,
                isDefault: true,
              );
            },
            show: true,
          ),
          SchematicBubble(
            user: widget.user!,
            anchorLeft: ftAnchorL,
            anchorBottom: ftAnchorB,
            bubbleLeft: ftBubbleL,
            bubbleBottom: ftBubbleB,
            containerHeight: headerHeight,
            bikeName: _uBikeID,
            category: Category.frontTire,
            chosenCategory: chosenCategory,
            setup: _uSetupID,
            onPressed: () =>
                setState(() => chosenCategory = Category.frontTire),
            onValueChange: (value) {
              chosenCategory = Category.frontTire;
              showSettingStepperSheet(
                context,
                user: widget.user!,
                uBikeID: _uBikeID,
                category: chosenCategory.category,
                uSetupID: _uSetupID,
                settingKey: 'Pressure',
                currentValue: value,
                isDefault: true,
              );
            },
            show: true,
          ),
          SchematicBubble(
            user: widget.user!,
            anchorLeft: shAnchorL,
            anchorBottom: shAnchorB,
            bubbleLeft: shBubbleL,
            bubbleBottom: shBubbleB,
            containerHeight: headerHeight,
            bikeName: _uBikeID,
            category: Category.shock,
            chosenCategory: chosenCategory,
            setup: _uSetupID,
            onPressed: () => setState(() => chosenCategory = Category.shock),
            onValueChange: (value) {
              chosenCategory = Category.shock;
              showSettingStepperSheet(
                context,
                user: widget.user!,
                uBikeID: _uBikeID,
                category: chosenCategory.category,
                uSetupID: _uSetupID,
                settingKey: 'Pressure',
                currentValue: value,
                isDefault: true,
              );
            },
            show: _bikeType.hasShock,
          ),
          SchematicBubble(
            user: widget.user!,
            anchorLeft: gsAnchorL,
            anchorBottom: gsAnchorB,
            bubbleLeft: gsBubbleL,
            bubbleBottom: gsBubbleB,
            containerHeight: headerHeight,
            bikeName: _uBikeID,
            category: Category.generalSettings,
            chosenCategory: chosenCategory,
            setup: _uSetupID,
            onPressed: () =>
                setState(() => chosenCategory = Category.generalSettings),
            onValueChange: (value) {},
            show: true,
          ),
          SchematicBubble(
            user: widget.user!,
            anchorLeft: fkAnchorL,
            anchorBottom: fkAnchorB,
            bubbleLeft: fkBubbleL,
            bubbleBottom: fkBubbleB,
            containerHeight: headerHeight,
            bikeName: _uBikeID,
            category: Category.fork,
            chosenCategory: chosenCategory,
            setup: _uSetupID,
            onPressed: () => setState(() => chosenCategory = Category.fork),
            onValueChange: (value) {
              chosenCategory = Category.fork;
              showSettingStepperSheet(
                context,
                user: widget.user!,
                uBikeID: _uBikeID,
                category: chosenCategory.category,
                uSetupID: _uSetupID,
                settingKey: 'Pressure',
                currentValue: value,
                isDefault: true,
              );
            },
            show: _bikeType.hasFork,
          ),
        ],
      ),
    );
  }

  Widget _buildSetupView(BuildContext context, double contentWidth) {
    return SetupWorkspace(
      diagramBuilder: (width, height) =>
          _buildBikeHeader(context, width, height),
      settings: ControlPanelGrid(
        user: widget.user!,
        uBikeID: _uBikeID,
        category: chosenCategory.category,
        uSetupID: _uSetupID,
        topPadding: 0,
        sectionLabel: _sectionLabelFor(chosenCategory),
      ),
    );
  }

  String _sectionLabelFor(Category cat) {
    switch (cat) {
      case Category.rearTire:
        return 'Rear tire settings';
      case Category.frontTire:
        return 'Front tire settings';
      case Category.shock:
        return 'Shock settings';
      case Category.fork:
        return 'Fork settings';
      case Category.generalSettings:
        return 'Geometry settings';
    }
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final p = context.palette;
    final textScaler = MediaQuery.textScalerOf(context);
    final wide = ResponsiveLayout.isWide(context) && textScaler.scale(14) < 23;
    final toggle = ViewToggle(
      activeView: _activeView,
      showServiceAlert: _showServiceAlert,
      onChanged: (view) {
        HapticFeedback.lightImpact();
        setState(() => _activeView = view);
      },
    );
    final settingsButton = IconButton(
      tooltip: 'Settings',
      onPressed: () => Navigator.of(context).push(
        AppRoutes.fadeSlide(SettingsPage(
          bikeName: _bikeName,
          bikeType: _bikeType,
          chosenSetup: _setupName,
        )),
      ),
      icon: Icon(Icons.settings_outlined, size: 23, color: p.inkMuted),
    );
    return AppBar(
      backgroundColor: p.bg,
      elevation: 0,
      scrolledUnderElevation: 0,
      toolbarHeight: math.max(64, textScaler.scale(20) * 2.5 + 10),
      titleSpacing: wide ? 0 : 18,
      title: AppContentFrame(
          maxWidth: wide ? double.infinity : kContentMaxWidth,
          padding: EdgeInsets.symmetric(horizontal: wide ? 24 : 0),
          child: Row(
            children: [
              Expanded(
                child: Semantics(
                  button: true,
                  label: 'Choose bike and setup',
                  child: InkWell(
                    onTap: _showBikeSelector,
                    borderRadius: BorderRadius.circular(8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_bikeType.bikeType} · $_setupName',
                          style: AppTextStyles.inter(
                            size: 12,
                            weight: FontWeight.w500,
                            color: p.inkMuted,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                _bikeName,
                                style: AppTextStyles.inter(
                                  size: 20,
                                  weight: FontWeight.w700,
                                  color: p.ink,
                                  letterSpacing: -0.3,
                                  height: 1.1,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(Icons.expand_more,
                                size: 20, color: p.inkMuted),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (wide) ...[
                SizedBox(width: 280, child: toggle),
              ],
              if (wide)
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: settingsButton,
                  ),
                )
              else
                settingsButton,
            ],
          )),
      bottom: wide
          ? null
          : PreferredSize(
              preferredSize: Size.fromHeight(
                  math.max(44, textScaler.scale(14) * 2.8) + 18),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                child: toggle,
              ),
            ),
      automaticallyImplyLeading: false,
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
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: _activeView == ActiveView.setup
          ? KeyedSubtree(
              key: ValueKey('setup_$_uBikeID'),
              child: _buildSetupView(context, contentWidth),
            )
          : ServicesView(
              key: ValueKey('services_$_uBikeID'),
              user: widget.user!,
              uBikeID: _uBikeID,
              onAddComponent: _addComponent,
              onAlertChanged: (hasAlert) {
                if (_showServiceAlert != hasAlert) {
                  setState(() => _showServiceAlert = hasAlert);
                }
              },
            ),
    );
  }

  Future<void> _addComponent() async {
    try {
      await _loadMileage();
      if (!mounted) return;
      showAddComponentSheet(context,
          user: widget.user!,
          uBikeID: _uBikeID,
          currentMileageKm: _currentMileageKm);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Could not load mileage. Try again.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final wide = ResponsiveLayout.isWide(context);
    return Scaffold(
      appBar: _buildAppBar(context),
      body: SafeArea(
          top: false,
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
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add component'))
          : null,
    );
  }
}

class _AnchorFrac {
  final double fx;
  final double fy;
  const _AnchorFrac(this.fx, this.fy);
}

class _BikeAnchors {
  final _AnchorFrac rearTire;
  final _AnchorFrac frontTire;
  final _AnchorFrac? shock;
  final _AnchorFrac? fork;
  final _AnchorFrac geometry;
  const _BikeAnchors({
    required this.rearTire,
    required this.frontTire,
    required this.geometry,
    this.shock,
    this.fork,
  });
}

const Map<BikeType, _BikeAnchors> _kBikeAnchors = {
  BikeType.enduro: _BikeAnchors(
    rearTire: _AnchorFrac(0.249, 0.724),
    frontTire: _AnchorFrac(0.748, 0.724),
    shock: _AnchorFrac(0.453, 0.475),
    fork: _AnchorFrac(0.724, 0.472),
    geometry: _AnchorFrac(0.377, 0.734),
  ),
  BikeType.dh: _BikeAnchors(
    rearTire: _AnchorFrac(0.251, 0.715),
    frontTire: _AnchorFrac(0.749, 0.715),
    shock: _AnchorFrac(0.451, 0.465),
    fork: _AnchorFrac(0.728, 0.474),
    geometry: _AnchorFrac(0.397, 0.728),
  ),
  BikeType.dirtjump: _BikeAnchors(
    rearTire: _AnchorFrac(0.249, 0.721),
    frontTire: _AnchorFrac(0.743, 0.723),
    fork: _AnchorFrac(0.714, 0.454),
    geometry: _AnchorFrac(0.439, 0.789),
  ),
  BikeType.xc: _BikeAnchors(
    rearTire: _AnchorFrac(0.249, 0.721),
    frontTire: _AnchorFrac(0.742, 0.721),
    fork: _AnchorFrac(0.719, 0.464),
    geometry: _AnchorFrac(0.393, 0.743),
  ),
  BikeType.singlespeed: _BikeAnchors(
    rearTire: _AnchorFrac(0.257, 0.726),
    frontTire: _AnchorFrac(0.739, 0.727),
    geometry: _AnchorFrac(0.431, 0.749),
  ),
  BikeType.road: _BikeAnchors(
    rearTire: _AnchorFrac(0.253, 0.736),
    frontTire: _AnchorFrac(0.741, 0.736),
    geometry: _AnchorFrac(0.447, 0.746),
  ),
};
