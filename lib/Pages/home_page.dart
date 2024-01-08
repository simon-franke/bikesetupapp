import 'package:bikesetupapp/Pages/nav_drawer.dart';
import 'package:bikesetupapp/Services/database.dart';
import 'package:bikesetupapp/Widgets/Bubbles.dart';
import 'package:bikesetupapp/Widgets/homepage_list_view.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../Services/alert_dialogs.dart';

const double borderrad = 35;

enum ChosenCategory {
  reartire(category: 'RearTire'),
  fronttire(category: 'FrontTire'),
  shock(category: 'Shock'),
  generalsettings(category: 'GeneralSettings'),
  fork(category: 'Fork');

  final String category;
  const ChosenCategory({required this.category});
}

class MyHomePage extends StatefulWidget {
  final User? user;
  final String bikename;
  final String biketype;
  final String chosensetup;
  const MyHomePage(
      {Key? key,
      required this.user,
      required this.biketype,
      required this.bikename,
      required this.chosensetup})
      : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late ChosenCategory chosenCategory;

  @override
  void initState() {
    super.initState();
    chosenCategory = ChosenCategory.reartire;
  }

  @override
  Widget build(BuildContext context) {
    DatabaseService(widget.user!.uid)
        .setDefaultBike(widget.bikename); //Macht das Sinn??

    final Size size = MediaQuery.of(context).size;
    final double boxHeight = size.height / 3.5;
    const double offset = 40;

    String bikeImage = 'assets/${widget.biketype}.png';

    return Scaffold(
      drawer: NavDrawer(
        user: widget.user,
        bikename: widget.bikename,
        biketype: widget.biketype,
        chosensetup: widget.chosensetup,
      ),
      appBar: AppBar(
        scrolledUnderElevation: 0,
        title: Text(
          widget.bikename,
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
      body: Stack(
        children: [
          Column(children: [
            SizedBox(height: boxHeight - offset),
            Expanded(
                child: HomePageListView(
                    user: widget.user,
                    bikename: widget.bikename,
                    category: chosenCategory.category,
                    setup: widget.chosensetup))
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
                bikename: widget.bikename,
                category: 'RearTire',
                chosencategory: chosenCategory.category,
                setup: widget.chosensetup,
                onPressed: () {
                  setState(() {
                    chosenCategory = ChosenCategory.reartire;
                  });
                  //print(chosencategory);
                },
                onValueChange: (value) {
                  chosenCategory = ChosenCategory.reartire;
                  AlertDialogs.editValue(
                      context,
                      widget.user!,
                      'Pressure',
                      value,
                      widget.bikename,
                      chosenCategory.category,
                      widget.chosensetup);
                },
                show: true,
              ),
              Bubble(
                user: widget.user,
                left: size.width / 1.20,
                bottom: size.height / 6.66,
                bikename: widget.bikename,
                category: 'FrontTire',
                chosencategory: chosenCategory.category,
                setup: widget.chosensetup,
                onPressed: () {
                  setState(() {
                    chosenCategory = ChosenCategory.fronttire;
                  });
                },
                onValueChange: (value) {
                  chosenCategory = ChosenCategory.fronttire;
                  AlertDialogs.editValue(
                      context,
                      widget.user!,
                      'Pressure',
                      value,
                      widget.bikename,
                      chosenCategory.category,
                      widget.chosensetup);
                },
                show: true,
              ),
              Bubble(
                  user: widget.user,
                  left: size.width / 2.2,
                  bottom: size.height / 8,
                  bikename: widget.bikename,
                  category: 'Shock',
                  chosencategory: chosenCategory.category,
                  setup: widget.chosensetup,
                  onPressed: () {
                    setState(() {
                      chosenCategory = ChosenCategory.shock;
                    });
                  },
                  onValueChange: (value) {
                    chosenCategory = ChosenCategory.shock;
                    AlertDialogs.editValue(
                        context,
                        widget.user!,
                        'Pressure',
                        value,
                        widget.bikename,
                        chosenCategory.category,
                        widget.chosensetup);
                  },
                  show: widget.biketype == "FullSuspension"),
              Bubble(
                user: widget.user,
                left: size.width / 2.65,
                bottom: size.height / 5.33,
                bikename: widget.bikename,
                category: 'GeneralSettings',
                chosencategory: chosenCategory.category,
                setup: widget.chosensetup,
                onPressed: () {
                  setState(() {
                    chosenCategory = ChosenCategory.generalsettings;
                  });
                },
                onValueChange: (value) {},
                show: true,
              ),
              Bubble(
                  user: widget.user,
                  left: size.width / 1.5,
                  bottom: size.height / 5.33,
                  bikename: widget.bikename,
                  category: 'Fork',
                  chosencategory: chosenCategory.category,
                  setup: widget.chosensetup,
                  onPressed: () {
                    setState(() {
                      chosenCategory = ChosenCategory.fork;
                    });
                  },
                  onValueChange: (value) {
                    chosenCategory = ChosenCategory.fork;
                    AlertDialogs.editValue(
                        context,
                        widget.user!,
                        'Pressure',
                        value,
                        widget.bikename,
                        chosenCategory.category,
                        widget.chosensetup);
                  },
                  show: widget.biketype != "Road"),
            ]),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          AlertDialogs.newKey(context, widget.user!, widget.bikename,
              chosenCategory.category, widget.chosensetup);
        },
        tooltip: 'Add Setting',
        child: const Icon(Icons.add),
      ),
    );
  }
}
