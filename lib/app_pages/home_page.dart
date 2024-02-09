import 'package:bikesetupapp/alert_dialogs/settings_alert_dialogs.dart';
import 'package:bikesetupapp/app_pages/nav_drawer.dart';
import 'package:bikesetupapp/alert_dialogs/bike_alert_dialogs.dart';
import 'package:bikesetupapp/widgets/homepage_list_view.dart';
import 'package:bikesetupapp/widgets/home_page_bubbles.dart';
import 'package:bikesetupapp/bike_enums/biketype.dart';
import 'package:bikesetupapp/bike_enums/category.dart';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

const double borderrad = 35;

class MyHomePage extends StatefulWidget {
  final User? user;
  final String bikename;
  final String ubid;
  final BikeType biketype;
  final String setupname;
  final String usid;
  const MyHomePage(
      {Key? key,
      required this.user,
      required this.biketype,
      required this.bikename,
      required this.ubid,
      required this.setupname,
      required this.usid})
      : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late Category chosenCategory;

  @override
  void initState() {
    super.initState();
    chosenCategory = Category.reartire;
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    final double boxHeight = size.height / 3.5;
    const double offset = 40;

    String bikeImage = 'assets/${widget.biketype.biketype}.png';

    return Scaffold(
      drawer: NavDrawer(
        user: widget.user,
        bikename: widget.bikename,
        biketype: widget.biketype,
        chosensetup: widget.setupname,
      ),
      appBar: AppBar(
          scrolledUnderElevation: 0,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.bikename,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              IconButton(
                  onPressed: () {
                    if (widget.user != null) {
                      BikeAlerts.showSetupInformation(
                          context,
                          size,
                          widget.user!.uid,
                          widget.ubid,
                          widget.usid,
                          widget.setupname,
                          widget.biketype);
                    }
                  },
                  icon: const Icon(Icons.info_outline_rounded)),
            ],
          )),
      body: Stack(
        children: [
          Column(children: [
            SizedBox(height: boxHeight - offset),
            Expanded(
                child: HomePageListView(
                    user: widget.user,
                    bikename: widget.bikename,
                    ubid: widget.ubid,
                    category: chosenCategory.category,
                    setup: widget.setupname,
                    usid: widget.usid))
          ]),
          Container(
            width: size.width,
            height: boxHeight,
            decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.4),
                      spreadRadius: 5,
                      blurRadius: 7,
                      offset: const Offset(0, 3))
                ],
                borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(borderrad),
                    bottomRight: Radius.circular(borderrad))),
            child: Stack(children: [
              Center(
                child: Image.asset(bikeImage),
              ),
              Bubble(
                user: widget.user,
                left: size.width / 40,
                bottom: size.height / 6.66,
                bikename: widget.ubid,
                category: Category.reartire,
                chosencategory: chosenCategory,
                setup: widget.usid,
                onPressed: () {
                  setState(() {
                    chosenCategory = Category.reartire;
                  });
                },
                onValueChange: (value) {
                  chosenCategory = Category.reartire;
                  SettingsAlerts.editValue(context, widget.user!, 'Pressure',
                      value, widget.ubid, chosenCategory.category, widget.usid);
                },
                show: true,
              ),
              Bubble(
                user: widget.user,
                left: size.width / 1.20,
                bottom: size.height / 6.66,
                bikename: widget.ubid,
                category: Category.fronttire,
                chosencategory: chosenCategory,
                setup: widget.usid,
                onPressed: () {
                  setState(() {
                    chosenCategory = Category.fronttire;
                  });
                },
                onValueChange: (value) {
                  chosenCategory = Category.fronttire;
                  SettingsAlerts.editValue(context, widget.user!, 'Pressure',
                      value, widget.ubid, chosenCategory.category, widget.usid);
                },
                show: true,
              ),
              Bubble(
                  user: widget.user,
                  left: size.width / 2.2,
                  bottom: size.height / 8,
                  bikename: widget.ubid,
                  category: Category.shock,
                  chosencategory: chosenCategory,
                  setup: widget.usid,
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
                        widget.ubid,
                        chosenCategory.category,
                        widget.usid);
                  },
                  show: widget.biketype == BikeType.fullsuspension),
              Bubble(
                user: widget.user,
                left: size.width / 2.65,
                bottom: size.height / 5.33,
                bikename: widget.ubid,
                category: Category.generalsettings,
                chosencategory: chosenCategory,
                setup: widget.usid,
                onPressed: () {
                  setState(() {
                    chosenCategory = Category.generalsettings;
                  });
                },
                onValueChange: (value) {},
                show: true,
              ),
              Bubble(
                  user: widget.user,
                  left: size.width / 1.5,
                  bottom: size.height / 5.33,
                  bikename: widget.ubid,
                  category: Category.fork,
                  chosencategory: chosenCategory,
                  setup: widget.usid,
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
                        widget.ubid,
                        chosenCategory.category,
                        widget.usid);
                  },
                  show: widget.biketype != BikeType.road),
            ]),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          SettingsAlerts.newKey(context, widget.user!, widget.ubid,
              chosenCategory.category, widget.usid);
        },
        tooltip: 'Add Setting',
        child: const Icon(Icons.add),
      ),
    );
  }
}
