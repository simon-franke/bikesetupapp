import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bikesetupapp/Pages/home_page.dart';
import 'package:bikesetupapp/Services/database.dart';

class NewBike extends StatefulWidget {
  final User user;
  final bool isnewbike;
  final bool isdefaultbike;
  final String bike;
  final String setup;
  final String biketype;
  const NewBike(
      {Key? key,
      required this.user,
      required this.isnewbike,
      required this.isdefaultbike,
      required this.bike,
      required this.setup,
      required this.biketype})
      : super(key: key);

  @override
  State<NewBike> createState() => _NewBikeState();
}

class _NewBikeState extends State<NewBike> {
  late Future<void> initData;

  String shocktype = 'Air';
  String forktype = 'Air';
  String reartravel = '';
  String fronttravel = '';
  String frontwheelsize = '';
  String rearwheelsize = '';
  String bikename = '';

  Future<void> getData() async {
    var snapshot= await DatabaseService(widget.user.uid)
        .getSetupSettings(widget.bike, widget.setup);

    Map<String, dynamic> setupdata = snapshot[widget.setup]!;

    setState(() {
      fronttravel = setupdata['fronttravel']!.toString().replaceAll('mm', "");
      reartravel = setupdata['reartravel']!.toString().replaceAll('mm', "");
      frontwheelsize = setupdata['frontwheelsize']!.toString().replaceAll('"', "");
      rearwheelsize = setupdata['rearwheelsize']!.toString().replaceAll('"', "");
      forktype = setupdata['fork']!.toString();
      shocktype = setupdata['shock']!.toString();
    });
  }

  @override
  void initState() {
    super.initState();
    if (!widget.isnewbike) {
      initData = getData();
      bikename = widget.bike;
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
          return const Center(
              child: CircularProgressIndicator(
            color: Colors.white,
          )); //TODO: Add theme color
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else {
          return Scaffold(
              appBar: AppBar(
                  title: (widget.isnewbike)
                      ? Text(
                          'Create New Bike',
                          style: Theme.of(context).textTheme.titleLarge,
                        )
                      : Text(
                          'Edit Bike',
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
                              readOnly: !widget.isnewbike,
                              initialValue: widget.isnewbike ? null : bikename,
                              decoration: InputDecoration(
                                  hintStyle:
                                      Theme.of(context).textTheme.titleLarge,
                                  hintText: widget.isnewbike
                                      ? 'Label your new Bike...'
                                      : null,
                                  border: InputBorder.none),
                              onChanged: (value) {
                                setState(() {
                                  bikename = value;
                                });
                              },
                            ),
                          ),
                        )),
                        Expanded(
                          child: ListView(children: [
                            ListTile(
                              leading: Icon(
                                Icons.alarm,
                                color: Theme.of(context).iconTheme.color,
                              ),
                              title: Text(
                                'Shock Type',
                                style: Theme.of(context).textTheme.labelMedium,
                              ),
                              trailing: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  dropdownColor:
                                      Theme.of(context).scaffoldBackgroundColor,
                                  value: shocktype,
                                  icon: Icon(
                                    Icons.arrow_downward_rounded,
                                    color: Theme.of(context).iconTheme.color,
                                  ),
                                  elevation: 16,
                                  style: Theme.of(context).textTheme.labelLarge,
                                  onChanged: (String? newValue) {
                                    setState(() {
                                      shocktype = newValue!;
                                      if (shocktype == 'None') {
                                        reartravel = '0';
                                      }
                                    });
                                  },
                                  items: <String>['Air', 'Coil', 'None']
                                      .map<DropdownMenuItem<String>>(
                                          (String value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(
                                        value,
                                        //style: Theme.of(context).textTheme.titleLarge,
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                            ListTile(
                              leading: Icon(
                                Icons.alarm,
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
                                  value: forktype,
                                  icon: Icon(
                                    Icons.arrow_downward_rounded,
                                    color: Theme.of(context).iconTheme.color,
                                  ),
                                  elevation: 16,
                                  style: Theme.of(context).textTheme.labelLarge,
                                  onChanged: (String? newValue) {
                                    setState(() {
                                      forktype = newValue!;
                                      if (forktype == 'None') {
                                        fronttravel = '0';
                                      }
                                    });
                                  },
                                  items: <String>['Air', 'Coil', 'None']
                                      .map<DropdownMenuItem<String>>(
                                          (String value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(
                                        value,
                                        //style: Theme.of(context).textTheme.titleLarge,
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                            ListTile(
                              leading: Icon(
                                Icons.straighten,
                                color: Theme.of(context).iconTheme.color,
                              ),
                              title: Text(
                                'Rear Travel',
                                style: Theme.of(context).textTheme.labelMedium,
                              ),
                              trailing: SizedBox(
                                width: 150.0,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: <Widget>[
                                    Expanded(
                                      flex: 3,
                                      child: TextFormField(
                                        readOnly: shocktype == 'None',
                                        initialValue: (widget.isnewbike)
                                            ? null
                                            : reartravel,
                                        keyboardType: TextInputType.number,
                                        textAlign: TextAlign.end,
                                        decoration: InputDecoration.collapsed(
                                            hintText: (reartravel == "")
                                                ? 'Rear Travel'
                                                : null,
                                            hintStyle: Theme.of(context)
                                                .textTheme
                                                .bodyLarge),
                                        onChanged: (value) {
                                          setState(() {
                                            reartravel = value;
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
                            ListTile(
                              leading: Icon(
                                Icons.straighten,
                                color: Theme.of(context).iconTheme.color,
                              ),
                              title: Text(
                                'Front Travel',
                                style: Theme.of(context).textTheme.labelMedium,
                              ),
                              trailing: SizedBox(
                                width: 150.0,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: <Widget>[
                                    Expanded(
                                      flex: 3,
                                      child: TextFormField(
                                        readOnly: forktype == 'None',
                                        initialValue: (widget.isnewbike)
                                            ? null
                                            : fronttravel,
                                        keyboardType: TextInputType.number,
                                        textAlign: TextAlign.end,
                                        decoration: InputDecoration.collapsed(
                                            hintText: (fronttravel == "")
                                                ? 'Front Travel'
                                                : null,
                                            hintStyle: Theme.of(context)
                                                .textTheme
                                                .bodyLarge),
                                        onChanged: (value) {
                                          setState(() {
                                            fronttravel = value;
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
                                        decoration: InputDecoration.collapsed(
                                            hintStyle: Theme.of(context)
                                                .textTheme
                                                .bodyLarge,
                                            hintText: (rearwheelsize == "")
                                                ? 'Size'
                                                : null),
                                        initialValue: (widget.isnewbike)
                                            ? null
                                            : rearwheelsize,
                                        keyboardType: TextInputType.number,
                                        textAlign: TextAlign.end,
                                        onChanged: (value) {
                                          setState(() {
                                            rearwheelsize = value;
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
                                        decoration: InputDecoration.collapsed(
                                            hintStyle: Theme.of(context)
                                                .textTheme
                                                .bodyLarge,
                                            hintText: (frontwheelsize == "")
                                                ? 'Size'
                                                : null),
                                        initialValue: (widget.isnewbike)
                                            ? null
                                            : frontwheelsize,
                                        keyboardType: TextInputType.number,
                                        textAlign: TextAlign.end,
                                        onChanged: (value) {
                                          setState(() {
                                            frontwheelsize = value;
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
                                      'Cancel',
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
                                      if (bikename == '') {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                                'Please enter a bike name'),
                                          ),
                                        );
                                        return;
                                      } else {
                                        DatabaseService(widget.user.uid)
                                            .createBike(
                                                bikename,
                                                {
                                                  'fork': forktype,
                                                  'shock': shocktype,
                                                  'fronttravel': '${fronttravel}mm',
                                                  'reartravel': '${reartravel}mm',
                                                  'frontwheelsize': '$frontwheelsize"',
                                                  'rearwheelsize': '$rearwheelsize"',
                                                },
                                                widget.biketype,
                                                widget.isdefaultbike);
                                        Navigator.of(context).push(
                                            MaterialPageRoute(
                                                builder:
                                                    (BuildContext context) =>
                                                        MyHomePage(
                                                          user: widget.user,
                                                          bikename: bikename,
                                                          biketype: widget.biketype,
                                                          chosensetup: "Standard",
                                                        )));
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
