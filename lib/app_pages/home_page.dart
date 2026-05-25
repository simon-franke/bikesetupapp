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
import 'package:intl/intl.dart';

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

  // ── Bike header — rounded surface card with neutral spotlight + bubbles ──
  Widget _buildBikeHeader(BuildContext context, double contentWidth, double headerHeight) {
    final p = context.palette;
    // Compute the bike image's actual rendered size inside the header.
    const double imgNativeW = 1080.0, imgNativeH = 664.0;
    final double availW = contentWidth - 24; // 12px horizontal margin each side
    final double availH = headerHeight;
    final double scale = math.min(availW / imgNativeW, availH / imgNativeH);
    final double imgRenderW = imgNativeW * scale;
    final double imgLeft = (availW - imgRenderW) / 2;

    // Anchor positions — on the bike parts (origin: bottom-left of header).
    final double rtAnchorL = imgLeft + imgRenderW / 20;
    final double rtAnchorB = availH * 0.525;
    final double ftAnchorL = imgLeft + imgRenderW / 1.10;
    final double ftAnchorB = availH * 0.525;
    final double shAnchorL = imgLeft + imgRenderW / 2.2;
    final double shAnchorB = availH * 0.437;
    final double gsAnchorL = imgLeft + imgRenderW / 2.65;
    final double gsAnchorB = availH * 0.657;
    final double fkAnchorL = imgLeft + imgRenderW / 1.45;
    final double fkAnchorB = availH * 0.657;

    // Bubble card positions — floated into clear space near each part.
    final double rtBubbleL = (rtAnchorL - 8).clamp(8.0, availW - bubbleCardW - 8);
    final double rtBubbleB = (rtAnchorB + 18).clamp(8.0, availH - bubbleCardH - 8);
    final double ftBubbleL = (ftAnchorL - bubbleCardW + 8).clamp(8.0, availW - bubbleCardW - 8);
    final double ftBubbleB = (rtBubbleB);
    final double shBubbleL = (shAnchorL - bubbleCardW / 2).clamp(8.0, availW - bubbleCardW - 8);
    final double shBubbleB = (availH - bubbleCardH - 14);
    final double gsBubbleL = (gsAnchorL - bubbleCardW - 10).clamp(8.0, availW - bubbleCardW - 8);
    final double gsBubbleB = 14;
    final double fkBubbleL = (fkAnchorL + 14).clamp(8.0, availW - bubbleCardW - 8);
    final double fkBubbleB = shBubbleB;

    final mileageText = NumberFormat('#,###').format(_currentMileageKm.round());

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      height: headerHeight,
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: p.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Neutral spotlight — lifts the bike without any chroma.
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

          // Mileage chip top-left.
          Positioned(
            top: 12,
            left: 12,
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
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: p.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 5, height: 5,
                      decoration: BoxDecoration(
                        color: p.accent,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: p.accent, blurRadius: 8),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      mileageText,
                      style: AppTextStyles.mono(size: 11, weight: FontWeight.w700, color: AppColors.darkInk, letterSpacing: 0.5),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'KM',
                      style: AppTextStyles.inter(size: 9, weight: FontWeight.w700, color: AppColors.darkInkDim, letterSpacing: 0.8),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bike silhouette — paper-white inverted on dark, dark on light.
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 40, 24, 28),
            child: Center(
              child: ColorFiltered(
                colorFilter: Theme.of(context).brightness == Brightness.dark
                    ? const ColorFilter.matrix(<double>[
                        -1, 0, 0, 0, 255,
                        0, -1, 0, 0, 255,
                        0, 0, -1, 0, 255,
                        0, 0, 0, 0.92, 0,
                      ])
                    : const ColorFilter.matrix(<double>[
                        0.18, 0, 0, 0, 0,
                        0, 0.18, 0, 0, 0,
                        0, 0, 0.18, 0, 0,
                        0, 0, 0, 0.85, 0,
                      ]),
                child: Image.asset(_bikeType.path, fit: BoxFit.contain),
              ),
            ),
          ),

          // Schematic bubbles.
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
          child: _IconBtn(
            icon: Icons.menu_rounded,
            onTap: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
      ),
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

    // FAB only on the Services view — Setup uses the inline AddFieldCard.
    final Widget? fab = _activeView == ActiveView.services
        ? FloatingActionButton(
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
        : null;

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
        child: Icon(icon, size: 20, color: p.ink),
      ),
    );
  }
}
