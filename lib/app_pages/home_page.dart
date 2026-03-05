import 'package:bikesetupapp/alert_dialogs/settings_alert_dialogs.dart';
import 'package:bikesetupapp/app_pages/google_sign_in.dart';
import 'package:bikesetupapp/app_pages/drawer.dart';
import 'package:bikesetupapp/app_services/app_routes.dart';
import 'package:bikesetupapp/app_services/responsive_layout.dart';
import 'package:bikesetupapp/alert_dialogs/bike_alert_dialogs.dart';
import 'package:bikesetupapp/widgets/homepage_list_view.dart';
import 'package:bikesetupapp/widgets/home_page_bubbles.dart';
import 'package:bikesetupapp/widgets/sidebar_content.dart';
import 'package:bikesetupapp/bike_enums/bike_type.dart';
import 'package:bikesetupapp/bike_enums/category.dart';

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
  }

  Widget _buildMainContent(BuildContext context, double contentWidth) {
    final Size size = MediaQuery.of(context).size;
    final double boxHeight = size.height / 3.5;
    final bool wide = ResponsiveLayout.isWide(context);
    final double offset = wide ? 0 : 40;
    final double topPadding = wide ? 0 : 45;

    return Stack(
      children: [
        Column(children: [
          SizedBox(height: boxHeight - offset),
          Expanded(
              child: HomePageListView(
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
            Center(
              child: Hero(
                tag: 'bike-image-${widget.bikeType.path}',
                child: Image.asset(widget.bikeType.path),
              ),
            ),
            Bubble(
              user: widget.user!,
              left: contentWidth / 40,
              bottom: size.height / 6.66,
              bikeName: widget.uBikeID,
              category: Category.rearTire,
              chosenCategory: chosenCategory,
              setup: widget.uSetupID,
              onPressed: () {
                setState(() {
                  chosenCategory = Category.rearTire;
                });
              },
              onValueChange: (value) {
                chosenCategory = Category.rearTire;
                SettingsAlerts.editValue(context, widget.user!, 'Pressure',
                    value, widget.uBikeID, chosenCategory.category, widget.uSetupID);
              },
              show: true,
            ),
            Bubble(
              user: widget.user!,
              left: contentWidth / 1.20,
              bottom: size.height / 6.66,
              bikeName: widget.uBikeID,
              category: Category.frontTire,
              chosenCategory: chosenCategory,
              setup: widget.uSetupID,
              onPressed: () {
                setState(() {
                  chosenCategory = Category.frontTire;
                });
              },
              onValueChange: (value) {
                chosenCategory = Category.frontTire;
                SettingsAlerts.editValue(context, widget.user!, 'Pressure',
                    value, widget.uBikeID, chosenCategory.category, widget.uSetupID);
              },
              show: true,
            ),
            Bubble(
                user: widget.user!,
                left: contentWidth / 2.2,
                bottom: size.height / 8,
                bikeName: widget.uBikeID,
                category: Category.shock,
                chosenCategory: chosenCategory,
                setup: widget.uSetupID,
                onPressed: () {
                  setState(() {
                    chosenCategory = Category.shock;
                  });
                },
                onValueChange: (value) {
                  chosenCategory = Category.shock;
                  SettingsAlerts.editValue(
                      context,
                      widget.user!,
                      'Pressure',
                      value,
                      widget.uBikeID,
                      chosenCategory.category,
                      widget.uSetupID);
                },
                show: widget.bikeType.hasShock),
            Bubble(
              user: widget.user!,
              left: contentWidth / 2.65,
              bottom: size.height / 5.33,
              bikeName: widget.uBikeID,
              category: Category.generalSettings,
              chosenCategory: chosenCategory,
              setup: widget.uSetupID,
              onPressed: () {
                setState(() {
                  chosenCategory = Category.generalSettings;
                });
              },
              onValueChange: (value) {},
              show: true,
            ),
            Bubble(
                user: widget.user!,
                left: contentWidth / 1.5,
                bottom: size.height / 5.33,
                bikeName: widget.uBikeID,
                category: Category.fork,
                chosenCategory: chosenCategory,
                setup: widget.uSetupID,
                onPressed: () {
                  setState(() {
                    chosenCategory = Category.fork;
                  });
                },
                onValueChange: (value) {
                  chosenCategory = Category.fork;
                  SettingsAlerts.editValue(
                      context,
                      widget.user!,
                      'Pressure',
                      value,
                      widget.uBikeID,
                      chosenCategory.category,
                      widget.uSetupID);
                },
                show: widget.bikeType.hasFork),
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
    if (widget.user == null ||
        widget.uBikeID.isEmpty ||
        widget.uSetupID.isEmpty) {
      Navigator.of(context)
          .push(AppRoutes.fadeSlide(const LoginPage()));
    }

    final Size size = MediaQuery.of(context).size;
    final bool wide = ResponsiveLayout.isWide(context);
    final double cWidth = ResponsiveLayout.contentWidth(context);

    final fab = FloatingActionButton(
      onPressed: () {
        SettingsAlerts.newKey(context, widget.user!, widget.uBikeID,
            chosenCategory.category, widget.uSetupID);
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
