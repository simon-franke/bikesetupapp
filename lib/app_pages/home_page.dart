import 'package:bikesetupapp/alert_dialogs/settings_alert_dialogs.dart';
import 'package:bikesetupapp/widgets/add_field_bottom_sheet.dart';
import 'package:bikesetupapp/widgets/add_component_bottom_sheet.dart';
import 'package:bikesetupapp/app_pages/google_sign_in.dart';
import 'package:bikesetupapp/app_pages/drawer.dart';
import 'package:bikesetupapp/app_services/app_routes.dart';
import 'package:bikesetupapp/app_services/responsive_layout.dart';
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

const double borderRadius = 35;

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
    chosenCategory = Category.rearTire;
    if (widget.user == null ||
        _uBikeID.isEmpty ||
        _uSetupID.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).push(AppRoutes.fadeSlide(const LoginPage()));
      });
    }
    _loadMileage();
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
      chosenCategory = Category.rearTire;
    });
    _loadMileage();
  }

  Widget _buildMainContent(BuildContext context, double contentWidth) {
    final Size size = MediaQuery.of(context).size;
    final bool wide = ResponsiveLayout.isWide(context);
    final double boxHeight = wide
        ? (size.height * 0.48).clamp(180.0, 340.0)
        : size.height / 3.5;
    final double offset = wide ? 0 : 40;
    final double topPadding = wide ? 0 : 45;

    // Compute the bike image's actual rendered size (BoxFit.contain of 1080×664).
    // Bubbles are positioned relative to the image, not the full container width.
    const double imgNativeW = 1080.0, imgNativeH = 664.0;
    final double scale = math.min(contentWidth / imgNativeW, boxHeight / imgNativeH);
    final double imgRenderW = imgNativeW * scale;
    final double imgLeft = (contentWidth - imgRenderW) / 2;

    // Anchor positions — on the bike parts.
    final double rtAnchorL = imgLeft + imgRenderW / 20;
    final double rtAnchorB = boxHeight * 0.525;
    final double ftAnchorL = imgLeft + imgRenderW / 1.10;
    final double ftAnchorB = boxHeight * 0.525;
    final double shAnchorL = imgLeft + imgRenderW / 2.2;
    final double shAnchorB = boxHeight * 0.437;
    final double gsAnchorL = imgLeft + imgRenderW / 2.65;
    final double gsAnchorB = boxHeight * 0.657;
    final double fkAnchorL = imgLeft + imgRenderW / 1.45;
    final double fkAnchorB = boxHeight * 0.657;

    // Bubble card positions — floated into clear space near each part.
    // Cards are bubbleCardW × bubbleCardH (76 × 44 px).
    final double rtBubbleL = rtAnchorL - 8;
    final double rtBubbleB = rtAnchorB - 68;
    final double ftBubbleL = ftAnchorL - bubbleCardW + 8;
    final double ftBubbleB = ftAnchorB - 68;
    final double shBubbleL = shAnchorL - bubbleCardW / 2;
    final double shBubbleB = shAnchorB - 70;
    final double gsBubbleL = gsAnchorL - bubbleCardW - 10;
    final double gsBubbleB = gsAnchorB - 6;
    final double fkBubbleL = fkAnchorL + 14;
    final double fkBubbleB = fkAnchorB - 6;

    return Stack(
      children: [
        Column(children: [
          SizedBox(height: boxHeight - offset),
          Expanded(
              child: ControlPanelGrid(
                  user: widget.user!,
                  uBikeID: _uBikeID,
                  category: chosenCategory.category,
                  uSetupID: _uSetupID,
                  topPadding: topPadding))
        ]),
        Container(
          width: contentWidth,
          height: boxHeight,
          decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    spreadRadius: 5,
                    blurRadius: 7,
                    offset: const Offset(0, 3))
              ],
              borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(borderRadius),
                  bottomRight: Radius.circular(borderRadius))),
          child: Stack(children: [
            // Bike silhouette — dimmed to act as a background reference.
            Center(
              child: Opacity(
                opacity: 0.22,
                child: Image.asset(_bikeType.path),
              ),
            ),
            SchematicBubble(
              user: widget.user!,
              anchorLeft: rtAnchorL,
              anchorBottom: rtAnchorB,
              bubbleLeft: rtBubbleL,
              bubbleBottom: rtBubbleB,
              containerHeight: boxHeight,
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
              containerHeight: boxHeight,
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
              containerHeight: boxHeight,
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
              containerHeight: boxHeight,
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
              containerHeight: boxHeight,
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
          ]),
        ),
      ],
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
        scrolledUnderElevation: 0,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
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
              child: Text(
                _bikeName,
                style: Theme.of(context).textTheme.titleLarge,
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
          ],
        ));
  }

  Widget _buildBody(BuildContext context, double contentWidth) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: _activeView == ActiveView.setup
          ? _buildMainContent(context, contentWidth)
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

    final fab = FloatingActionButton(
      onPressed: () {
        if (_activeView == ActiveView.services) {
          showAddComponentSheet(
            context,
            user: widget.user!,
            uBikeID: _uBikeID,
            currentMileageKm: _currentMileageKm,
          );
        } else {
          showAddFieldSheet(context,
              user: widget.user!,
              uBikeID: _uBikeID,
              category: chosenCategory.category,
              uSetupID: _uSetupID);
        }
      },
      tooltip: _activeView == ActiveView.services ? 'Add Component' : 'Add Setting',
      child: const Icon(Icons.add),
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
