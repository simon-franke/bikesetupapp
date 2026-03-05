import 'package:bikesetupapp/app_pages/home_page.dart';
import 'package:bikesetupapp/app_services/app_routes.dart';
import 'package:bikesetupapp/database_service/database.dart';
import 'package:bikesetupapp/bike_enums/bike_type.dart';
import 'package:bikesetupapp/bike_enums/new_bike_mode.dart';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';

class NewBike extends StatefulWidget {
  final User user;
  final NewBikeMode newBikeMode;
  final String bikeName;
  final String uBikeID;
  final String setupName;
  final String uSetupID;
  final BikeType bikeType;
  const NewBike(
      {super.key,
      required this.user,
      required this.newBikeMode,
      required this.bikeName,
      required this.uBikeID,
      required this.setupName,
      required this.uSetupID,
      required this.bikeType});

  @override
  State<NewBike> createState() => _NewBikeState();
}

class _NewBikeState extends State<NewBike> {
  late Future<void> initData;

  String userInputFieldValue = '';
  List<String> possibleSuspensionType = ['Air', 'Coil'];
  Map<String, String> setupInformation = {
    'fork': 'Air',
    'shock': 'Air',
    'front_travel': '',
    'rear_travel': '',
    'front_wheel_size': '',
    'rear_wheel_size': '',
  };

  Future<void> getData() async {
    Map<String, dynamic> setupData = await DatabaseService(widget.user.uid)
        .getSetupInformationAsMap(widget.uBikeID, widget.uSetupID);

    setState(() {
      setupInformation['front_travel'] =
          setupData['front_travel']!.toString().replaceAll('mm', "");
      setupInformation['rear_travel'] =
          setupData['rear_travel']!.toString().replaceAll('mm', "");
      setupInformation['front_wheel_size'] =
          setupData['front_wheel_size']!.toString().replaceAll('"', "");
      setupInformation['rear_wheel_size'] =
          setupData['rear_wheel_size']!.toString().replaceAll('"', "");
      setupInformation['fork'] = setupData['fork']!.toString();
      setupInformation['shock'] = setupData['shock']!.toString();
    });
  }

  @override
  void initState() {
    super.initState();
    if (widget.newBikeMode == NewBikeMode.editSetup) {
      initData = getData();
      userInputFieldValue = widget.setupName;
    } else {
      initData = Future.value();
    }
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    bool isButtonActive = true;
    return FutureBuilder<void>(
      future: initData,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
              child: CircularProgressIndicator.adaptive(
            valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).floatingActionButtonTheme.backgroundColor ??
                    Colors.white),
          ));
        }
        return Scaffold(
            appBar: AppBar(
                title: Text(
              widget.newBikeMode.appBarTitle,
              style: Theme.of(context).textTheme.titleLarge,
            )),
            body: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: size.height,
                  minWidth: size.width,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    children: <Widget>[
                      Card(
                          child: Padding(
                        padding: const EdgeInsets.only(
                            left: 15, right: 15, bottom: 2.5, top: 2.5),
                        child: Center(
                          child: TextFormField(
                            style: Theme.of(context).textTheme.labelLarge,
                            initialValue: !widget.newBikeMode.isEdit
                                ? null
                                : userInputFieldValue,
                            decoration: InputDecoration(
                                hintStyle:
                                    Theme.of(context).textTheme.titleLarge,
                                hintText: widget.newBikeMode.hintTextTextField,
                                border: InputBorder.none),
                            onChanged: (value) {
                              setState(() {
                                userInputFieldValue = value;
                              });
                            },
                          ),
                        ),
                      )),
                      Expanded(
                        child: ListView(children: [
                          Visibility(
                            visible: widget.bikeType.hasFork,
                            child: ListTile(
                              leading: Icon(
                                Icons.compress_rounded,
                                color: Theme.of(context).iconTheme.color,
                              ),
                              title: Text(
                                'Fork Type',
                                style: Theme.of(context).textTheme.labelMedium,
                              ),
                              trailing: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  dropdownColor:
                                      Theme.of(context).scaffoldBackgroundColor,
                                  value: setupInformation['fork'],
                                  icon: Icon(
                                    Icons.arrow_downward_rounded,
                                    color: Theme.of(context).iconTheme.color,
                                  ),
                                  elevation: 16,
                                  style: Theme.of(context).textTheme.labelLarge,
                                  onChanged: (String? newValue) {
                                    setState(() {
                                      if (newValue != null) {
                                        setupInformation['fork'] = newValue;
                                      }
                                    });
                                  },
                                  items: possibleSuspensionType
                                      .map<DropdownMenuItem<String>>(
                                          (String value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(
                                        value,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleLarge,
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          ),
                          Visibility(
                              visible: widget.bikeType.hasShock,
                              child: ListTile(
                                leading: Icon(
                                  Icons.compress_rounded,
                                  color: Theme.of(context).iconTheme.color,
                                ),
                                title: Text(
                                  'Shock Type',
                                  style:
                                      Theme.of(context).textTheme.labelMedium,
                                ),
                                trailing: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    dropdownColor: Theme.of(context)
                                        .scaffoldBackgroundColor,
                                    value: setupInformation['shock'],
                                    icon: Icon(
                                      Icons.arrow_downward_rounded,
                                      color: Theme.of(context).iconTheme.color,
                                    ),
                                    elevation: 16,
                                    style:
                                        Theme.of(context).textTheme.labelLarge,
                                    onChanged: (String? newValue) {
                                      setState(() {
                                        setupInformation['shock'] = newValue!;
                                      });
                                    },
                                    items: possibleSuspensionType
                                        .map<DropdownMenuItem<String>>(
                                            (String value) {
                                      return DropdownMenuItem<String>(
                                        value: value,
                                        child: Text(
                                          value,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleLarge,
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              )),
                          Visibility(
                            visible: widget.bikeType.hasFork,
                            child: ListTile(
                              leading: Icon(
                                Icons.straighten,
                                color: Theme.of(context).iconTheme.color,
                              ),
                              title: Text(
                                'Front Travel',
                                style: Theme.of(context).textTheme.labelMedium,
                              ),
                              trailing: ConstrainedBox(
                                constraints: BoxConstraints(
                                    maxWidth: size.width * 0.38),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: <Widget>[
                                    Expanded(
                                      flex: 3,
                                      child: TextFormField(
                                        cursorColor: Theme.of(context)
                                            .textTheme
                                            .labelMedium!
                                            .color,
                                        initialValue: !widget.newBikeMode.isEdit
                                            ? null
                                            : setupInformation['front_travel'],
                                        keyboardType: TextInputType.number,
                                        textAlign: TextAlign.end,
                                        decoration: InputDecoration.collapsed(
                                            hintText: !widget.newBikeMode.isEdit
                                                ? 'Front Travel'
                                                : null,
                                            hintStyle: Theme.of(context)
                                                .textTheme
                                                .bodyLarge),
                                        onChanged: (value) {
                                          setState(() {
                                            setupInformation['front_travel'] =
                                                value;
                                          });
                                        },
                                      ),
                                    ),
                                    const SizedBox(
                                      width: 10,
                                    ),
                                    Expanded(
                                        child: Text(
                                      'mm',
                                      style:
                                          Theme.of(context).textTheme.bodyLarge,
                                    ))
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Visibility(
                            visible: widget.bikeType.hasShock,
                            child: ListTile(
                              leading: Icon(
                                Icons.straighten,
                                color: Theme.of(context).iconTheme.color,
                              ),
                              title: Text(
                                'Rear Travel',
                                style: Theme.of(context).textTheme.labelMedium,
                              ),
                              trailing: ConstrainedBox(
                                constraints: BoxConstraints(
                                    maxWidth: size.width * 0.38),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: <Widget>[
                                    Expanded(
                                      flex: 3,
                                      child: TextFormField(
                                        cursorColor: Theme.of(context)
                                            .textTheme
                                            .labelMedium!
                                            .color,
                                        initialValue: !widget.newBikeMode.isEdit
                                            ? null
                                            : setupInformation['rear_travel'],
                                        keyboardType: TextInputType.number,
                                        textAlign: TextAlign.end,
                                        decoration: InputDecoration.collapsed(
                                            hintText: !widget.newBikeMode.isEdit
                                                ? 'Rear Travel'
                                                : null,
                                            hintStyle: Theme.of(context)
                                                .textTheme
                                                .bodyLarge),
                                        onChanged: (value) {
                                          setState(() {
                                            setupInformation['rear_travel'] =
                                                value;
                                          });
                                        },
                                      ),
                                    ),
                                    const SizedBox(
                                      width: 10,
                                    ),
                                    Expanded(
                                        child: Text(
                                      'mm',
                                      style:
                                          Theme.of(context).textTheme.bodyLarge,
                                    ))
                                  ],
                                ),
                              ),
                            ),
                          ),
                          ListTile(
                            leading: Icon(
                              Icons.hide_source,
                              color: Theme.of(context).iconTheme.color,
                            ),
                            title: Text(
                              'Rear Wheel Size',
                              style: Theme.of(context).textTheme.labelMedium,
                            ),
                            trailing: ConstrainedBox(
                              constraints: BoxConstraints(
                                  maxWidth: size.width * 0.30),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: <Widget>[
                                  Expanded(
                                    flex: 3,
                                    child: TextFormField(
                                      cursorColor: Theme.of(context)
                                          .textTheme
                                          .labelMedium!
                                          .color,
                                      decoration: InputDecoration.collapsed(
                                          hintStyle: Theme.of(context)
                                              .textTheme
                                              .bodyLarge,
                                          hintText: !widget.newBikeMode.isEdit
                                              ? 'Size'
                                              : null),
                                      initialValue: !widget.newBikeMode.isEdit
                                          ? null
                                          : setupInformation['rear_wheel_size'],
                                      keyboardType: TextInputType.number,
                                      textAlign: TextAlign.end,
                                      onChanged: (value) {
                                        setState(() {
                                          setupInformation['rear_wheel_size'] =
                                              value;
                                        });
                                      },
                                    ),
                                  ),
                                  Expanded(
                                      child: Text(
                                    '"',
                                    style:
                                        Theme.of(context).textTheme.bodyLarge,
                                  ))
                                ],
                              ),
                            ),
                          ),
                          ListTile(
                            leading: Icon(
                              Icons.hide_source,
                              color: Theme.of(context).iconTheme.color,
                            ),
                            title: Text(
                              'Front Wheel Size',
                              style: Theme.of(context).textTheme.labelMedium,
                            ),
                            trailing: ConstrainedBox(
                              constraints: BoxConstraints(
                                  maxWidth: size.width * 0.30),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: <Widget>[
                                  Expanded(
                                    flex: 3,
                                    child: TextFormField(
                                      cursorColor: Theme.of(context)
                                          .textTheme
                                          .labelMedium!
                                          .color,
                                      decoration: InputDecoration.collapsed(
                                          hintStyle: Theme.of(context)
                                              .textTheme
                                              .bodyLarge,
                                          hintText: !widget.newBikeMode.isEdit
                                              ? 'Size'
                                              : null),
                                      initialValue: !widget.newBikeMode.isEdit
                                          ? null
                                          : setupInformation['front_wheel_size'],
                                      keyboardType: TextInputType.number,
                                      textAlign: TextAlign.end,
                                      onChanged: (value) {
                                        setState(() {
                                          setupInformation['front_wheel_size'] =
                                              value;
                                        });
                                      },
                                    ),
                                  ),
                                  Expanded(
                                      child: Text(
                                    '"',
                                    style:
                                        Theme.of(context).textTheme.bodyLarge,
                                  ))
                                ],
                              ),
                            ),
                          ),
                        ]),
                      ),
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
                                    widget.newBikeMode == NewBikeMode.newBike
                                        ? 'Back'
                                        : 'Cancel',
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
                                  onPressed: () async {
                                    if (!isButtonActive) {
                                      return;
                                    }
                                    if (userInputFieldValue == '') {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content:
                                              Text('Please enter a bike name'),
                                        ),
                                      );
                                      setState(() {
                                        isButtonActive = true;
                                      });
                                      return;
                                    }
                                    isButtonActive = false;
                                    final String bikeName;
                                    final String setupName;
                                    final String uBikeID;
                                    final String uSetupID;
                                    if (widget.newBikeMode ==
                                        NewBikeMode.newBike) {
                                      setupName = 'Default';
                                      bikeName = userInputFieldValue;
                                      try {
                                        uBikeID = await DatabaseService(
                                                widget.user.uid)
                                            .createBike(
                                                bikeName,
                                                setupInformation,
                                                widget.bikeType.bikeType);
                                      } catch (e) {
                                        return;
                                      }
                                      uSetupID =
                                          await DatabaseService(widget.user.uid)
                                              .getDefaultSetup(uBikeID);
                                      if (uSetupID.isEmpty) {
                                        return;
                                      }
                                    } else if (widget.newBikeMode ==
                                        NewBikeMode.newSetup) {
                                      setupName = userInputFieldValue;
                                      bikeName = widget.bikeName;
                                      uBikeID = widget.uBikeID;
                                      uSetupID = const Uuid().v4();
                                      DatabaseService(widget.user.uid)
                                          .createSetup(widget.uBikeID, uSetupID,
                                              userInputFieldValue, setupInformation);
                                    } else {
                                      setupName = userInputFieldValue;
                                      bikeName = widget.bikeName;
                                      uBikeID = widget.uBikeID;
                                      uSetupID = widget.uSetupID;
                                      DatabaseService(widget.user.uid)
                                          .createSetup(widget.uBikeID, widget.uSetupID,
                                              userInputFieldValue, setupInformation);
                                    }
                                    if (context.mounted) {
                                      Navigator.of(context).push(
                                          AppRoutes.fadeSlide(MyHomePage(
                                              user: widget.user,
                                              bikeType: widget.bikeType,
                                              bikeName: bikeName,
                                              uBikeID: uBikeID,
                                              setupName: setupName,
                                              uSetupID: uSetupID)));
                                    }
                                  },
                                  child: isButtonActive
                                      ? Text(
                                          'Save',
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleLarge,
                                        )
                                      : CircularProgressIndicator(
                                          color: Theme.of(context)
                                              .textTheme
                                              .labelMedium!
                                              .color,
                                        ),
                                ),
                              ))
                        ],
                      ),
                    ],
                  ),
                )));
      },
    );
  }
}
