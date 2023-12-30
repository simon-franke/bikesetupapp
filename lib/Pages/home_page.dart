import 'package:bikesetupapp/Pages/nav_drawer.dart';
import 'package:bikesetupapp/Widgets/Bubbles.dart';
import 'package:bikesetupapp/Widgets/homepagelistview.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../Services/alertdialogs.dart';

const double borderrad = 35;
const String bikeImage = 'assets/bike.png';

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
  const MyHomePage({Key? key, required this.user, required this.bikename})
      : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late String chosensetup;
  late ChosenCategory chosenCategory;

  @override
  void initState() {
    super.initState();
    chosensetup = 'Standard';
    chosenCategory = ChosenCategory.reartire;
  }
  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    final double boxHeight = size.height / 3.5;
    const double overLap = 40;

    return Scaffold(
      drawer: NavDrawer(user: widget.user, bikename: widget.bikename,),
      appBar: AppBar(
        title: Text(
          widget.bikename,
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
      body: Stack(
        children: [
          Column(children: [
            SizedBox(height: boxHeight - overLap),
            Expanded(
                child: HomePageListView(
                    user: widget.user,
                    bikename: widget.bikename,
                    category: chosenCategory.category,
                    setup: chosensetup))
          ]),
          Container(
            width: size.width,
            height: boxHeight,
            decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(borderrad),
                    bottomRight: Radius.circular(borderrad))),
            child: Stack(children: [
              Center(
                child: Image.asset(bikeImage),
              ),
              Bubble(
                user: widget.user,
                left: size.width / 39.2,
                bottom: size.height / 6.66,
                bikename: widget.bikename,
                category: 'RearTire',
                setup: chosensetup,
                onPressed: () {
                  setState(() {
                    chosenCategory = ChosenCategory.reartire;
                  });
                  //print(chosencategory);
                },
                onValueChange: (value) {
                  chosenCategory = ChosenCategory.reartire;
                  AlertDialogs.editValue(context, widget.user!, 'Pressure', value, widget.bikename, chosenCategory.category, chosensetup);
                },
              ),
              Bubble(
                user: widget.user,
                left: size.width / 1.18,
                bottom: size.height / 6.66,
                bikename: widget.bikename,
                category: 'FrontTire',
                setup: chosensetup,
                onPressed: () {
                  setState(() {
                    chosenCategory = ChosenCategory.fronttire;
                  });
                  //print(chosencategory);
                },
                onValueChange: (value) {
                  chosenCategory = ChosenCategory.fronttire;
                  AlertDialogs.editValue(context, widget.user!, 'Pressure', value, widget.bikename, chosenCategory.category, chosensetup);
                },
              ),
              Bubble(
                user: widget.user,
                left: size.width / 2.177,
                bottom: size.height / 8,
                bikename: widget.bikename,
                category: 'Shock',
                setup: chosensetup,
                onPressed: () {
                  setState(() {
                    chosenCategory = ChosenCategory.shock;
                  });
                },
                onValueChange: (value) {
                  chosenCategory = ChosenCategory.shock;
                  AlertDialogs.editValue(context, widget.user!, 'Pressure', value, widget.bikename, chosenCategory.category, chosensetup);
                },
              ),
              Bubble(
                user: widget.user,
                left: size.width / 2.6133,
                bottom: size.height / 5.33,
                bikename: widget.bikename,
                category: '',
                setup: chosensetup,
                onPressed: () {
                  setState(() {
                    chosenCategory = ChosenCategory.generalsettings;
                  });
                },
                onValueChange: (value) {
                },
              ),
              Bubble(
                user: widget.user,
                left: size.width / 1.45,
                bottom: size.height / 5.33,
                bikename: widget.bikename,
                category: 'Fork',
                setup: chosensetup,
                onPressed: () {
                  setState(() {
                    chosenCategory = ChosenCategory.fork;
                  });
                },
                onValueChange: (value) {
                  chosenCategory = ChosenCategory.fork;
                  AlertDialogs.editValue(context, widget.user!, 'Pressure', value, widget.bikename, chosenCategory.category, chosensetup);
                },
              ),
            ]),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {AlertDialogs.newKey(context, widget.user!,
                              widget.bikename, chosenCategory.category, chosensetup);},
        tooltip: 'Add Setting',
        child: const Icon(Icons.add),
      ),
    );
  }
}
