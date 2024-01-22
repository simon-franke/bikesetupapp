import 'package:bikesetupapp/Pages/new_bike_select_type.dart';
import 'package:bikesetupapp/Pages/settings.dart';
import 'package:bikesetupapp/Services/enums.dart';
import 'package:bikesetupapp/Widgets/navdrawer_bike_list.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NavDrawer extends StatefulWidget {
  final String bikename;
  final BikeType biketype;
  final String chosensetup;
  final User? user;
  const NavDrawer(
      {Key? key,
      required this.bikename,
      required this.biketype,
      required this.chosensetup,
      required this.user})
      : super(key: key);

  @override
  State<NavDrawer> createState() => _NavDrawerState();
}

class _NavDrawerState extends State<NavDrawer> {
  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    return SizedBox(
        width: size.width * 0.85,
        child: Drawer(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          child: Column(
            //padding: EdgeInsets.zero,
            children: [
              SizedBox(
                  width: size.width * 0.85,
                  height: size.height * 0.20,
                  child: DrawerHeader(
                      decoration:
                          BoxDecoration(color: Theme.of(context).primaryColor),
                      child: Center(
                        child: ListTile(
                          leading: widget.user != null
                              ? Padding(
                                  padding: const EdgeInsets.all(5),
                                  child: CircleAvatar(
                                    backgroundImage: NetworkImage(
                                        '${widget.user?.photoURL}'),
                                  ),
                                )
                              : Padding(
                                  padding: const EdgeInsets.all(5),
                                  child: CircleAvatar(
                                    backgroundColor:
                                        Theme.of(context).primaryColor,
                                    backgroundImage: const AssetImage(
                                        'assets/incognito.png'),
                                  ),
                                ),
                          title: Text('Bike Setup',
                              style: Theme.of(context).textTheme.titleLarge),
                          subtitle: widget.user != null
                              ? Text(
                                  '${widget.user?.email}',
                                  style: Theme.of(context).textTheme.titleSmall,
                                )
                              : Text(
                                  'No User logged in',
                                  style:
                                      Theme.of(context).textTheme.labelMedium,
                                ),
                        ),
                      ))),
              Expanded(
                child: SizedBox(
                    height: size.height * 0.73,
                    child: BikeList(user: widget.user, bikename: widget.bikename,)),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(5),
                    child: ElevatedButton(
                        onPressed: () {
                          if (widget.user != null) {
                            Navigator.of(context).push(MaterialPageRoute(
                                builder: (BuildContext context) =>
                                    BikeTypeSelector(
                                      user: widget.user!,
                                    )));
                          } else {
                            ScaffoldMessenger.of(context)
                                .showSnackBar(const SnackBar(
                              content: Text('No User logged in'),
                            ));
                          }
                        },
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context)
                                .floatingActionButtonTheme
                                .backgroundColor),
                        child: Text(
                          'New Bike',
                          style: Theme.of(context).textTheme.labelLarge,
                        )),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(5),
                    child: IconButton(
                        onPressed: () {
                          Navigator.of(context).push(MaterialPageRoute(
                              builder: (BuildContext context) => SettingsPage(
                                    bikename: widget.bikename,
                                    biketype: widget.biketype,
                                    chosensetup: widget.chosensetup,
                                  )));
                        },
                        icon: const Icon(Icons.settings)),
                  )
                ],
              ),
            ],
          ),
        ));
  }
}
