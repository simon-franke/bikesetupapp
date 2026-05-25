import 'package:bikesetupapp/alert_dialogs/settings_alert_dialogs.dart';
import 'package:bikesetupapp/widgets/add_component_bottom_sheet.dart';
import 'package:bikesetupapp/app_pages/google_sign_in.dart';
import 'package:bikesetupapp/app_pages/drawer.dart';
import 'package:bikesetupapp/app_services/app_routes.dart';
import 'package:bikesetupapp/app_services/responsive_layout.dart';
import 'package:bikesetupapp/app_services/theme_data.dart';
import 'package:bikesetupapp/database_service/service_database.dart';
import 'package:bikesetupapp/widgets/bike_info_bottom_sheet.dart';
import 'package:bikesetupapp/widgets/control_panel_grid.dart';
import 'package:bikesetupapp/widgets/home_page_bubbles.dart';
import 'package:bikesetupapp/widgets/services_view.dart';
import 'package:bikesetupapp/widgets/sidebar_content.dart';
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
  double _currentMileageKm = 0;

  @override
  void initState() {
    super.initState();
    _bikeName = widget.bikeName;
    _uBikeID = widget.uBikeID;
    _bikeType = widget.bikeType;
    _setupName = widget.setupName;
    _uSetupID = widget.uSetupID;
    chosenCategory = _initialCategoryFor(_bikeType);
    if (widget.user == null ||
        _uBikeID.isEmpty ||
        _uSetupID.isEmpty) {
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
    final db = ServiceDatabaseService(widget.user!.uid);
    final km = await db.getMileageForBike(_uBikeID);
    if (mounted && km != null) {
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

  Widget _buildBikeHeader(BuildContext context, double contentWidth, double headerHeight) {
    const double imgNativeW = 1080.0, imgNativeH = 664.0;
    const double padL = 24, padT = 40, padR = 24, padB = 28;
    final double availW = contentWidth - 24;
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
    const double sideGap = 12, topGap = 14, botGap = 14;
    final double topRow = availH - bubbleCardH - topGap;
    final double botRow = botGap;
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
      rtBubbleL = leftCol;     rtBubbleB = topRow;
      shBubbleL = midCol;      shBubbleB = topRow;
      fkBubbleL = rightCol;    fkBubbleB = topRow;
      ftBubbleL = rightCol;    ftBubbleB = midRow;
    } else if (_bikeType.hasFork) {
      // Dirt, XC: rear left-middle, fork top-right, front right-middle.
      rtBubbleL = leftCol;     rtBubbleB = midRow;
      fkBubbleL = rightCol;    fkBubbleB = topRow;
      ftBubbleL = rightCol;    ftBubbleB = midRow;
      shBubbleL = midCol;      shBubbleB = topRow; // unused (show=false)
    } else {
      // Singlespeed, Road: rear left-middle, front right-middle.
      rtBubbleL = leftCol;     rtBubbleB = midRow;
      ftBubbleL = rightCol;    ftBubbleB = midRow;
      shBubbleL = midCol;      shBubbleB = topRow; // unused
      fkBubbleL = rightCol;    fkBubbleB = topRow; // unused
    }
    gsBubbleL = midCol;        gsBubbleB = botRow;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      height: headerHeight,
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.darkBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, 0.1),
                    radius: 0.95,
                    colors: [
                      Colors.white.withValues(alpha: 0.06),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.75],
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    radius: 1.05,
                    colors: [
                      Color(0x00000000),
                      Color(0x38000000),
                    ],
                    stops: [0.35, 1.0],
                  ),
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(24, 40, 24, 28),
            child: Center(
              child: ColorFiltered(
                colorFilter: const ColorFilter.matrix(<double>[
                  -1, 0, 0, 0, 255,
                  0, -1, 0, 0, 255,
                  0, 0, -1, 0, 255,
                  0, 0, 0, 0.92, 0,
                ]),
                child: Image.asset(_bikeType.path, fit: BoxFit.contain),
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
              SettingsAlerts.editValue(context, widget.user!, 'Pressure',
                  value, _uBikeID, chosenCategory.category, _uSetupID);
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
            onPressed: () => setState(() => chosenCategory = Category.frontTire),
            onValueChange: (value) {
              chosenCategory = Category.frontTire;
              SettingsAlerts.editValue(context, widget.user!, 'Pressure',
                  value, _uBikeID, chosenCategory.category, _uSetupID);
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
              SettingsAlerts.editValue(context, widget.user!, 'Pressure',
                  value, _uBikeID, chosenCategory.category, _uSetupID);
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
            onPressed: () => setState(() => chosenCategory = Category.generalSettings),
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
              SettingsAlerts.editValue(context, widget.user!, 'Pressure',
                  value, _uBikeID, chosenCategory.category, _uSetupID);
            },
            show: _bikeType.hasFork,
          ),
        ],
      ),
    );
  }

  Widget _buildSetupView(BuildContext context, double contentWidth) {
    final Size size = MediaQuery.of(context).size;
    final bool wide = ResponsiveLayout.isWide(context);
    final double headerHeight = wide
        ? (size.height * 0.48).clamp(240.0, 360.0)
        : (size.height / 3.2).clamp(220.0, 320.0);

    return Column(
      children: [
        const SizedBox(height: 4),
        _buildBikeHeader(context, contentWidth, headerHeight),
        const SizedBox(height: 4),
        Expanded(
          child: ControlPanelGrid(
            user: widget.user!,
            uBikeID: _uBikeID,
            category: chosenCategory.category,
            uSetupID: _uSetupID,
            topPadding: 0,
            sectionLabel: _sectionLabelFor(chosenCategory),
          ),
        ),
      ],
    );
  }

  String _sectionLabelFor(Category cat) {
    switch (cat) {
      case Category.rearTire: return 'Rear tire settings';
      case Category.frontTire: return 'Front tire settings';
      case Category.shock: return 'Shock settings';
      case Category.fork: return 'Fork settings';
      case Category.generalSettings: return 'Geometry settings';
    }
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final p = context.palette;
    return AppBar(
      backgroundColor: p.bg,
      elevation: 0,
      scrolledUnderElevation: 0,
      toolbarHeight: 64,
      titleSpacing: 4,
      leading: Builder(
        builder: (ctx) => Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Align(
            alignment: Alignment.centerLeft,
            child: _IconBtn(
              icon: Icons.menu_rounded,
              onTap: () => Scaffold.of(ctx).openDrawer(),
            ),
          ),
        ),
      ),
      leadingWidth: 60,
      title: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onLongPress: () {
                showBikeInfoSheet(
                  context,
                  widget.user!,
                  _uBikeID,
                  _uSetupID,
                  _setupName,
                  _bikeName,
                  _bikeType,
                  onBikeSelected: _onBikeSelected,
                );
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_bikeType.bikeType.toUpperCase()} · ${_setupName.toUpperCase()}',
                    style: AppTextStyles.inter(
                      size: 10,
                      weight: FontWeight.w700,
                      color: p.inkDim,
                      letterSpacing: 1.4,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
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
                ],
              ),
            ),
          ),
          ViewToggle(
            activeView: _activeView,
            showServiceAlert: _showServiceAlert,
            onChanged: (view) {
              HapticFeedback.lightImpact();
              setState(() => _activeView = view);
            },
          ),
          const SizedBox(width: 14),
        ],
      ),
      automaticallyImplyLeading: false,
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
              onAlertChanged: (hasAlert) {
                if (_showServiceAlert != hasAlert) {
                  setState(() => _showServiceAlert = hasAlert);
                }
              },
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    final bool wide = ResponsiveLayout.isWide(context);
    final double cWidth = ResponsiveLayout.contentWidth(context);

    final Widget fab = AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      switchInCurve: Curves.easeOutBack,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) => ScaleTransition(
        scale: animation,
        child: FadeTransition(opacity: animation, child: child),
      ),
      child: _activeView == ActiveView.services
          ? FloatingActionButton(
              key: const ValueKey('add_component_fab'),
              onPressed: () {
                showAddComponentSheet(
                  context,
                  user: widget.user!,
                  uBikeID: _uBikeID,
                  currentMileageKm: _currentMileageKm,
                );
              },
              tooltip: 'Add Component',
              child: const Icon(Icons.add_rounded),
            )
          : const SizedBox.shrink(key: ValueKey('no_fab')),
    );

    if (wide) {
      return Scaffold(
        appBar: _buildAppBar(context),
        body: Row(
          children: [
            SizedBox(
              width: ResponsiveLayout.sidebarWidth,
              child: SidebarContent(
                user: widget.user,
                bikeName: _bikeName,
                bikeType: _bikeType,
                chosenSetup: _setupName,
                onBikeSelected: _onBikeSelected,
              ),
            ),
            Expanded(child: _buildBody(context, cWidth)),
          ],
        ),
        floatingActionButton: fab,
      );
    }

    return Scaffold(
      drawer: NavDrawer(
        user: widget.user,
        bikeName: _bikeName,
        bikeType: _bikeType,
        chosenSetup: _setupName,
        onBikeSelected: _onBikeSelected,
      ),
      appBar: _buildAppBar(context),
      body: _buildBody(context, size.width),
      floatingActionButton: fab,
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _IconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: p.surface2,
          border: Border.all(color: p.border),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 18, color: p.ink),
      ),
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
