import 'package:bikesetupapp/app_pages/new_bike_page.dart';
import 'package:bikesetupapp/widgets/bike_selector_widget.dart';
import 'package:bikesetupapp/bike_enums/biketype.dart';
import 'package:bikesetupapp/bike_enums/new_bike_mode.dart';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';

class BikeTypeSelector extends StatefulWidget {
  final User user;
  const BikeTypeSelector({super.key, required this.user});

  @override
  State<BikeTypeSelector> createState() => _BikeTypeSelectorState();
}

class _BikeTypeSelectorState extends State<BikeTypeSelector> {
  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    PageController pageController = PageController(viewportFraction: 0.8);

    return Scaffold(
        appBar: AppBar(
          title: Text(
            "Select Bike Type",
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        body: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: size.height,
              minWidth: size.width,
            ),
            child: IntrinsicHeight(
              child: Column(
                children: <Widget>[
                  Expanded(
                    child: Center(
                        child: SizedBox(
                      height: size.height / 3,
                      child: PageView(
                        controller: pageController,
                        onPageChanged: (value) {
                          HapticFeedback.mediumImpact();
                        },
                        children: const <Widget>[
                          BikeSelectorWidget(bikeType: BikeType.fullsuspension),
                          BikeSelectorWidget(bikeType: BikeType.hardtail),
                          BikeSelectorWidget(bikeType: BikeType.road),
                        ],
                      ),
                    )),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                              width: size.width / 2,
                              child: Padding(
                                padding:
                                    const EdgeInsets.only(left: 30, right: 30),
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          Theme.of(context).primaryColor),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                  child: Text(
                                    'Cancel',
                                    style:
                                        Theme.of(context).textTheme.titleLarge,
                                  ),
                                ),
                              )),
                          SizedBox(
                              width: size.width / 2,
                              child: Padding(
                                padding:
                                    const EdgeInsets.only(left: 30, right: 30),
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          Theme.of(context).primaryColor),
                                  onPressed: () {
                                    BikeType biketype =
                                        BikeType.values[pageController.page?.round() ?? 0];
                                    Navigator.of(context).push(
                                      PageRouteBuilder(
                                        transitionDuration:
                                            const Duration(milliseconds: 200),
                                        transitionsBuilder:
                                            (BuildContext context,
                                                Animation<double> animation,
                                                Animation<double>
                                                    secondaryAnimation,
                                                Widget child) {
                                          return SlideTransition(
                                            position: Tween<Offset>(
                                              begin: const Offset(1.0, 0.0),
                                              end: Offset.zero,
                                            ).animate(animation),
                                            child: child,
                                          );
                                        },
                                        pageBuilder: (BuildContext context,
                                            Animation<double> animation,
                                            Animation<double>
                                                secondaryAnimation) {
                                          return NewBike(
                                            user: widget.user,
                                            newbikemode: NewBikeMode.newBike,
                                            bikename: "",
                                            ubid: "",
                                            setupname: 'Default',
                                            usid: "",
                                            biketype: biketype,
                                          );
                                        },
                                      ),
                                    );
                                  },
                                  child: Text(
                                    'Next',
                                    style:
                                        Theme.of(context).textTheme.titleLarge,
                                  ),
                                ),
                              ))
                        ],
                      ),
                    ],
                  )
                ],
              ),
            )));
  }
}
