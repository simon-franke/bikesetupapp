import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseService {
  DatabaseService(this.userID);
  String userID;

  final CollectionReference userbikesetup =
      FirebaseFirestore.instance.collection('UserBikeSetup');

  Future createBike(
      String bikename,
      Map<String, String> suspension,
      String forktravel,
      String shocktravel,
      String frontwheelsize,
      String rearwheelsize,
      bool isdefaultbike) async {
    await createFork(bikename, forktravel);
    await createShock(bikename, shocktravel);
    await createFrontTire(bikename, frontwheelsize);
    await createRearTire(bikename, rearwheelsize);
    await createGeneralSettings(bikename);
    if (isdefaultbike) {
      await setDefaultBike(bikename);
    }
    await createSetupList(bikename, suspension);
    return await userbikesetup
        .doc(userID)
        .collection('UserData')
        .doc('BikeList')
        .set({bikename: 'Fork:${suspension['fork']}|Shock:${suspension['shock']}'},
            SetOptions(merge: true));
  }

  Future deleteBike(String bikename) async {
    var snapshots = await userbikesetup
        .doc(userID)
        .collection(bikename)
        .get();
    for (var doc in snapshots.docs) {
      await doc.reference.delete();
    }

    return await userbikesetup
        .doc(userID)
        .collection('UserData')
        .doc('BikeList')
        .update({bikename: FieldValue.delete()});
  }

  Future createFork(String bikename, String forktravel) async {
    return await userbikesetup
        .doc(userID)
        .collection(bikename)
        .doc('ForkStandard')
        .set({
      'Pressure': '90',
      'Front Travel': forktravel,
    }, SetOptions(merge: true));
  }

  Future createShock(String bikename, String shocktravel) async {
    return await userbikesetup
        .doc(userID)
        .collection(bikename)
        .doc('ShockStandard')
        .set({'Pressure': '180', 'Shock Travel': shocktravel},
            SetOptions(merge: true));
  }

  Future createFrontTire(String bikename, String frontwheelsize) async {
    return await userbikesetup
        .doc(userID)
        .collection(bikename)
        .doc('FrontTireStandard')
        .set({'Pressure': '24', 'Wheel Size': frontwheelsize},
            SetOptions(merge: true));
  }

  Future createRearTire(String bikename, String rearwheelsize) async {
    return await userbikesetup
        .doc(userID)
        .collection(bikename)
        .doc('RearTireStandard')
        .set({'Pressure': '26', 'Wheel Size': rearwheelsize},
            SetOptions(merge: true));
  }

  Future createGeneralSettings(String bikename) async {
    return await userbikesetup
        .doc(userID)
        .collection(bikename)
        .doc('GeneralSettingsStandard')
        .set({'Distance': '90cm'}, SetOptions(merge: true));
  }

  Future setDefaultBike(String bikename) async {
    return await userbikesetup
        .doc(userID)
        .collection('UserData')
        .doc('DefaultBike')
        .set({'default': bikename}, SetOptions(merge: true));
  }

  Future setSetting(String key, String value, String bikename, String category,String setup) async {
    return await userbikesetup
        .doc(userID)
        .collection(bikename)
        .doc(category + setup)
        .set({key: value}, SetOptions(merge: true));
  }

  Future editSetting(String key, String value, String bikename, String category, String setup) async {
    return await userbikesetup
        .doc(userID)
        .collection(bikename)
        .doc('$category$setup')
        .update({key: value});
  }

  Future deleteSetting(String key, String bikename, String category,String setup) async {
    return await userbikesetup
        .doc(userID)
        .collection(bikename)
        .doc(category + setup)
        .update({
      key: FieldValue.delete(),
    });
  }

  Future createSetupList(
      String bikename, Map<String, dynamic> suspension) async {
    return await userbikesetup
        .doc(userID)
        .collection(bikename)
        .doc('SetupList')
        .set({'Standard': suspension}, SetOptions(merge: true));
  }

  Stream getSettings(String bikename, String category, String setup) {
    return userbikesetup
        .doc(userID)
        .collection(bikename)
        .doc('$category$setup')
        .snapshots();
  }

  Stream getBikes() {
    return userbikesetup
        .doc(userID)
        .collection('UserData')
        .doc('BikeList')
        .snapshots();
  }

  Stream getDocumentElement(
      String bikename, String category, String setup) {
    return userbikesetup
        .doc(userID)
        .collection(bikename)
        .doc('$category$setup')
        .snapshots();
  }

  Future<String> getDefaultBike() async {
    try {
      DocumentSnapshot snapshot =
          await userbikesetup.doc(userID).collection('UserData').doc('DefaultBike').get();

      if (snapshot.exists) {
        dynamic value = snapshot['default'];
        if (value != null) {
          return value.toString();
        } else {
          return "";
        }
      } else {
        return "";
      }
    } catch (e) {
      return "";
    }
  }

  Future<String> getSuspensionType(String bikename) async {
    try {
      DocumentSnapshot snapshot =
          await userbikesetup.doc(userID).collection('UserData').doc('BikeList').get();

      if (snapshot.exists) {
        dynamic value = snapshot[bikename];
        if (value != null) {
          return value.toString();
        } else {
          return 'Value not found';
        }
      } else {
        return 'Document does not exist';
      }
    } catch (e) {
      return 'Error: $e';
    }
  }

  Future<String> getSetting(String bikename, String category, String setup, String key) async {
    try {
      DocumentSnapshot snapshot =
          await userbikesetup.doc(userID).collection(bikename).doc('$category$setup').get();

      if (snapshot.exists) {
        dynamic value = snapshot[key];
        if (value != null) {
          return value.toString();
        } else {
          return 'Value not found';
        }
      } else {
        return 'Document does not exist';
      }
    } catch (e) {
      return 'Error: $e';
    }
  }

  Stream getDocumentElementSnap(String bikename, String category, String setup) {
    return userbikesetup
        .doc(userID)
        .collection(bikename)
        .doc('$category$setup')
        .snapshots();
  }
}


