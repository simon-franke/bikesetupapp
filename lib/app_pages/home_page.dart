import 'package:bikesetupapp/alert_dialogs/settings_alert_dialogs.dart';
import 'package:bikesetupapp/widgets/add_field_bottom_sheet.dart';
import 'package:bikesetupapp/app_pages/google_sign_in.dart';
import 'package:bikesetupapp/app_pages/drawer.dart';
import 'package:bikesetupapp/app_services/app_routes.dart';
import 'package:bikesetupapp/app_services/responsive_layout.dart';
import 'package:bikesetupapp/alert_dialogs/bike_alert_dialogs.dart';
import 'package:bikesetupapp/widgets/control_panel_grid.dart';
import 'package:bikesetupapp/widgets/homepage_list_view.dart';
import 'package:bikesetupapp/widgets/home_page_bubbles.dart';
import 'package:bikesetupapp/widgets/sidebar_content.dart';
import 'package:bikesetupapp/bike_enums/bike_type.dart';
import 'package:bikesetupapp/bike_enums/category.dart';

import 'dart:math' as math;

import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    chosenCategory = Category.rearTire;
    if (widget.user == null ||
        widget.uBikeID.isEmpty ||
        widget.uSetupID.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).push(AppRoutes.fadeSlide(const LoginPage()));
      });
    }
  }

  bool _isGridCategory(Category category) =>
      category != Category.generalSettings;

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
              child: _isGridCategory(chosenCategory)
                  ? ControlPanelGrid(
                      user: widget.user!,
                      uBikeID: widget.uBikeID,
                      category: chosenCategory.category,
                      uSetupID: widget.uSetupID,
                      topPadding: topPadding)
                  : HomePageListView(
                      user: widget.user!,
                      bikeName: widget.bikeName,
                      uBikeID: widget.uBikeID,
                      category: chosenCategory.category,
                      setup: widget.setupName,
                      uSetupID: widget.uSetupID,
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
                child: Image.asset(widget.bikeType.path),
              ),
            ),
            SchematicBubble(
              user: widget.user!,
              anchorLeft: rtAnchorL,
              anchorBottom: rtAnchorB,
              bubbleLeft: rtBubbleL,
              bubbleBottom: rtBubbleB,
              containerHeight: boxHeight,
              bikeName: widget.uBikeID,
              category: Category.rearTire,
              chosenCategory: chosenCategory,
              setup: widget.uSetupID,
              onPressed: () => setState(() => chosenCategory = Category.rearTire),
              onValueChange: (value) {
                chosenCategory = Category.rearTire;
                SettingsAlerts.editValue(context, widget.user!, 'Pressure',
                    value, widget.uBikeID, chosenCategory.category, widget.uSetupID);
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
              bikeName: widget.uBikeID,
              category: Category.frontTire,
              chosenCategory: chosenCategory,
              setup: widget.uSetupID,
              onPressed: () => setState(() => chosenCategory = Category.frontTire),
              onValueChange: (value) {
                chosenCategory = Category.frontTire;
                SettingsAlerts.editValue(context, widget.user!, 'Pressure',
                    value, widget.uBikeID, chosenCategory.category, widget.uSetupID);
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
              bikeName: widget.uBikeID,
              category: Category.shock,
              chosenCategory: chosenCategory,
              setup: widget.uSetupID,
              onPressed: () => setState(() => chosenCategory = Category.shock),
              onValueChange: (value) {
                chosenCategory = Category.shock;
                SettingsAlerts.editValue(context, widget.user!, 'Pressure',
                    value, widget.uBikeID, chosenCategory.category, widget.uSetupID);
              },
              show: widget.bikeType.hasShock,
            ),
            SchematicBubble(
              user: widget.user!,
              anchorLeft: gsAnchorL,
              anchorBottom: gsAnchorB,
              bubbleLeft: gsBubbleL,
              bubbleBottom: gsBubbleB,
              containerHeight: boxHeight,
              bikeName: widget.uBikeID,
              category: Category.generalSettings,
              chosenCategory: chosenCategory,
              setup: widget.uSetupID,
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
              bikeName: widget.uBikeID,
              category: Category.fork,
              chosenCategory: chosenCategory,
              setup: widget.uSetupID,
              onPressed: () => setState(() => chosenCategory = Category.fork),
              onValueChange: (value) {
                chosenCategory = Category.fork;
                SettingsAlerts.editValue(context, widget.user!, 'Pressure',
                    value, widget.uBikeID, chosenCategory.category, widget.uSetupID);
              },
              show: widget.bikeType.hasFork,
            ),
          ]),
        ),
      ],
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    return AppBar(
        scrolledUnderElevation: 0,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              widget.bikeName,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            IconButton(
                onPressed: () {
                  BikeAlerts.showSetupInformation(
                      context,
                      size,
                      widget.user!.uid,
                      widget.uBikeID,
                      widget.uSetupID,
                      widget.setupName,
                      widget.bikeType);
                },
                icon: const Icon(Icons.info_outline_rounded)),
          ],
        ));
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    final bool wide = ResponsiveLayout.isWide(context);
    final double cWidth = ResponsiveLayout.contentWidth(context);

    final fab = FloatingActionButton(
      onPressed: () {
        showAddFieldSheet(context,
            user: widget.user!,
            uBikeID: widget.uBikeID,
            category: chosenCategory.category,
            uSetupID: widget.uSetupID);
      },
      tooltip: 'Add Setting',
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
                bikeName: widget.bikeName,
                bikeType: widget.bikeType,
                chosenSetup: widget.setupName,
              ),
            ),
            const VerticalDivider(width: 1, thickness: 1),
            Expanded(child: _buildMainContent(context, cWidth)),
          ],
        ),
        floatingActionButton: fab,
      );
    }

    return Scaffold(
      drawer: NavDrawer(
        user: widget.user,
        bikeName: widget.bikeName,
        bikeType: widget.bikeType,
        chosenSetup: widget.setupName,
      ),
      appBar: _buildAppBar(context),
      body: _buildMainContent(context, size.width),
      floatingActionButton: fab,
    );
  }
}
