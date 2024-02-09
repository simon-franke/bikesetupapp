import 'package:bikesetupapp/app_pages/home_page.dart';
import 'package:bikesetupapp/database_service/database.dart';
import 'package:bikesetupapp/bike_enums/biketype.dart';
import 'package:bikesetupapp/bike_enums/new_bike_mode.dart';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';

class NewBike extends StatefulWidget {
  final User user;
  final NewBikeMode newbikemode;
  final bool isdefaultbike;
  final String bikename;
  final String ubid;
  final String setupname;
  final String usid;
  final BikeType biketype;
  const NewBike(
      {Key? key,
      required this.user,
      required this.newbikemode,
      required this.isdefaultbike,
      required this.bikename,
      required this.ubid,
      required this.setupname,
      required this.usid,
      required this.biketype})
      : super(key: key);

  @override
  State<NewBike> createState() => _NewBikeState();
}

class _NewBikeState extends State<NewBike> {
  late Future<void> initData;

  Map<String, String> setupinformation = {
    'fork': 'Air',
    'shock': 'Air',
    'fronttravel': '',
    'reartravel': '',
    'frontwheelsize': '',
    'rearwheelsize': '',
  };

  String userinputname = '';
  List<String> possiblesuspensiontype = ['Air', 'Coil'];

  Future<void> getData() async {
    Map<String, dynamic> setupdata = await DatabaseService(widget.user.uid)
        .getSetupInformationAsMap(widget.ubid, widget.usid);

    setState(() {
      setupinformation['fronttravel'] =
          setupdata['fronttravel']!.toString().replaceAll('mm', "");
      setupinformation['reartravel'] =
          setupdata['reartravel']!.toString().replaceAll('mm', "");
      setupinformation['frontwheelsize'] =
          setupdata['frontwheelsize']!.toString().replaceAll('"', "");
      setupinformation['rearwheelsize'] =
          setupdata['rearwheelsize']!.toString().replaceAll('"', "");
      setupinformation['fork'] = setupdata['fork']!.toString();
      setupinformation['shock'] = setupdata['shock']!.toString();
    });
  }

  @override
  void initState() {
    super.initState();
    if (widget.newbikemode == NewBikeMode.editSetup) {
      initData = getData();
      userinputname = widget.setupname;
    } else {
      initData = Future.value();
    }
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    return FutureBuilder<void>(
      future: initData,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
              child: CircularProgressIndicator(
            color: Theme.of(context).textTheme.titleLarge!.color,
          ));
        } else {
          return Scaffold(
              appBar: AppBar(
                  title: Text(
                widget.newbikemode.appBarTitle,
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
                              initialValue: !widget.newbikemode.isEdit
                                  ? null
                                  : userinputname,
                              decoration: InputDecoration(
                                  hintStyle:
                                      Theme.of(context).textTheme.titleLarge,
                                  hintText:
                                      widget.newbikemode.hintTextTextField,
                                  border: InputBorder.none),
                              onChanged: (value) {
                                setState(() {
                                  userinputname = value;
                                });
                              },
                            ),
                          ),
                        )),
                        Expanded(
                          child: ListView(children: [
                            Visibility(
                              visible: widget.biketype.hasFork,
                              child: ListTile(
                                leading: Icon(
                                  Icons.alarm,
                                  color: Theme.of(context).iconTheme.color,
                                ),
                                title: Text(
                                  'Fork Type',
                                  style:
                                      Theme.of(context).textTheme.labelMedium,
                                ),
                                trailing: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    dropdownColor: Theme.of(context)
                                        .scaffoldBackgroundColor,
                                    value: setupinformation['fork'],
                                    icon: Icon(
                                      Icons.arrow_downward_rounded,
                                      color: Theme.of(context).iconTheme.color,
                                    ),
                                    elevation: 16,
                                    style:
                                        Theme.of(context).textTheme.labelLarge,
                                    onChanged: (String? newValue) {
                                      setState(() {
                                        if (newValue != null) {
                                          setupinformation['fork'] = newValue;
                                        }
                                      });
                                    },
                                    items: possiblesuspensiontype
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
                                visible: widget.biketype.hasShock,
                                child: ListTile(
                                  leading: Icon(
                                    Icons.alarm,
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
                                      value: setupinformation['shock'],
                                      icon: Icon(
                                        Icons.arrow_downward_rounded,
                                        color:
                                            Theme.of(context).iconTheme.color,
                                      ),
                                      elevation: 16,
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelLarge,
                                      onChanged: (String? newValue) {
                                        setState(() {
                                          setupinformation['shock'] = newValue!;
                                        });
                                      },
                                      items: possiblesuspensiontype
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
                              visible: widget.biketype.hasFork,
                              child: ListTile(
                                leading: Icon(
                                  Icons.straighten,
                                  color: Theme.of(context).iconTheme.color,
                                ),
                                title: Text(
                                  'Front Travel',
                                  style:
                                      Theme.of(context).textTheme.labelMedium,
                                ),
                                trailing: SizedBox(
                                  width: 150.0,
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
                                          initialValue: !widget
                                                  .newbikemode.isEdit
                                              ? null
                                              : setupinformation['fronttravel'],
                                          keyboardType: TextInputType.number,
                                          textAlign: TextAlign.end,
                                          decoration: InputDecoration.collapsed(
                                              hintText:
                                                  !widget.newbikemode.isEdit
                                                      ? 'Front Travel'
                                                      : null,
                                              hintStyle: Theme.of(context)
                                                  .textTheme
                                                  .bodyLarge),
                                          onChanged: (value) {
                                            setState(() {
                                              setupinformation['fronttravel'] =
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
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyLarge,
                                      ))
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Visibility(
                              visible: widget.biketype.hasShock,
                              child: ListTile(
                                leading: Icon(
                                  Icons.straighten,
                                  color: Theme.of(context).iconTheme.color,
                                ),
                                title: Text(
                                  'Rear Travel',
                                  style:
                                      Theme.of(context).textTheme.labelMedium,
                                ),
                                trailing: SizedBox(
                                  width: 150.0,
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
                                          initialValue: !widget
                                                  .newbikemode.isEdit
                                              ? null
                                              : setupinformation['reartravel'],
                                          keyboardType: TextInputType.number,
                                          textAlign: TextAlign.end,
                                          decoration: InputDecoration.collapsed(
                                              hintText:
                                                  !widget.newbikemode.isEdit
                                                      ? 'Rear Travel'
                                                      : null,
                                              hintStyle: Theme.of(context)
                                                  .textTheme
                                                  .bodyLarge),
                                          onChanged: (value) {
                                            setState(() {
                                              setupinformation['reartravel'] =
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
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyLarge,
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
                              trailing: SizedBox(
                                width: 120.0,
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
                                            hintText: !widget.newbikemode.isEdit
                                                ? 'Size'
                                                : null),
                                        initialValue: !widget.newbikemode.isEdit
                                            ? null
                                            : setupinformation['rearwheelsize'],
                                        keyboardType: TextInputType.number,
                                        textAlign: TextAlign.end,
                                        onChanged: (value) {
                                          setState(() {
                                            setupinformation['rearwheelsize'] =
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
                              trailing: SizedBox(
                                width: 120.0,
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
                                            hintText: !widget.newbikemode.isEdit
                                                ? 'Size'
                                                : null),
                                        initialValue: !widget.newbikemode.isEdit
                                            ? null
                                            : setupinformation[
                                                'frontwheelsize'],
                                        keyboardType: TextInputType.number,
                                        textAlign: TextAlign.end,
                                        onChanged: (value) {
                                          setState(() {
                                            setupinformation['frontwheelsize'] =
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
                                  padding: const EdgeInsets.only(
                                      left: 30, right: 30),
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            Theme.of(context).primaryColor),
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                    child: Text(
                                      widget.newbikemode == NewBikeMode.newBike
                                          ? 'Back'
                                          : 'Cancel',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge,
                                    ),
                                  ),
                                )),
                            SizedBox(
                                width: size.width / 2,
                                child: Padding(
                                  padding: const EdgeInsets.only(
                                      left: 30, right: 30),
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            Theme.of(context).primaryColor),
                                    onPressed: () async {
                                      if (userinputname == '') {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                                'Please enter a bike name'),
                                          ),
                                        );
                                        return;
                                      } else {
                                        String bikename;
                                        String setupname;
                                        String ubid;
                                        String usid;
                                        if (widget.newbikemode ==
                                            NewBikeMode.newBike) {
                                          setupname = 'Default';
                                          bikename = userinputname;
                                          ubid = await DatabaseService(
                                                  widget.user.uid)
                                              .createBike(
                                                  bikename,
                                                  setupinformation,
                                                  widget.biketype.biketype,
                                                  widget.isdefaultbike);
                                          usid = await DatabaseService(
                                                  widget.user.uid)
                                              .getDefaultSetup(ubid);
                                          if (!mounted) return;
                                        } else if (widget.newbikemode ==
                                            NewBikeMode.newSetup) {
                                          setupname = userinputname;
                                          bikename = widget.bikename;
                                          ubid = widget.ubid;
                                          usid = const Uuid().v4();
                                          DatabaseService(widget.user.uid)
                                              .createSetup(
                                                  widget.ubid,
                                                  usid,
                                                  userinputname,
                                                  setupinformation);
                                        } else {
                                          setupname = userinputname;
                                          bikename = widget.bikename;
                                          ubid = widget.ubid;
                                          usid = widget.usid;
                                          DatabaseService(widget.user.uid)
                                              .createSetup(
                                                  widget.ubid,
                                                  widget.usid,
                                                  userinputname,
                                                  setupinformation);
                                        }
                                        Navigator.of(context).push(
                                            MaterialPageRoute(
                                                builder: (context) =>
                                                    MyHomePage(
                                                        user: widget.user,
                                                        biketype:
                                                            widget.biketype,
                                                        bikename:bikename,
                                                        ubid: ubid,
                                                        chosensetup: setupname,
                                                        usid: usid)));
                                      }
                                    },
                                    child: Text(
                                      'Save',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge,
                                    ),
                                  ),
                                ))
                          ],
                        ),
                      ],
                    ),
                  )));
        }
      },
    );
  }
}
