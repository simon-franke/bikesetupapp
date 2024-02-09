import 'package:bikesetupapp/bike_enums/biketype.dart';
import 'package:bikesetupapp/database_service/database.dart';
import 'package:bikesetupapp/widgets/setup_information_list_element.dart';
import 'package:flutter/material.dart';

class SetupInformation extends StatelessWidget {
  final String userID;
  final String ubid;
  final String usid;
  final BikeType biketype;
  const SetupInformation({
    super.key,
    required this.userID,
    required this.ubid,
    required this.usid,
    required this.biketype,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: DatabaseService(userID).getSetupInformation(ubid, usid),
        builder: ((context, snapshot) {
          if (ConnectionState.waiting == snapshot.connectionState) {
            return const SizedBox(
              height: 100.0,
              width: 100.0,
            );
          } else if (snapshot.hasError) {
            return const Center(child: Text('Error'));
          } else if (snapshot.data == null) {
            return const SizedBox(
              height: 100.0,
              width: 100.0,
              child: Text('Error'),
            );
          } else {
            var data = snapshot.data.data() as Map<String, dynamic>;
            return SizedBox(
                child: IntrinsicHeight(
                    child: Column(
              children: [
                SetupInformationListElement(
                    name: 'Fork Type',
                    value: data['fork'] ?? '',
                    visible: biketype.hasFork),
                SetupInformationListElement(
                    name: 'Shock Type',
                    value: data['shock'] ?? '',
                    visible: biketype.hasShock),
                SetupInformationListElement(
                    name: 'Front Travel',
                    value: '${data['fronttravel']} mm',
                    visible: biketype.hasFork),
                SetupInformationListElement(
                    name: 'Rear Travel',
                    value: '${data['reartravel']} mm',
                    visible: biketype.hasShock),
                SetupInformationListElement(
                    name: 'Front Wheel Size',
                    value: '${data['frontwheelsize']}"',
                    visible: true),
                SetupInformationListElement(
                    name: 'Rear Wheel Size',
                    value: '${data['rearwheelsize']}"',
                    visible: true),
              ],
            )));
          }
        }));
  }
}
