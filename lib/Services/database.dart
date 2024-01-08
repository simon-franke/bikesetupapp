import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseService {
  DatabaseService(this.userID);
  String userID;

  final CollectionReference userbikesetup =
      FirebaseFirestore.instance.collection('UserBikeSetup');

  Future createBike(String bikename, Map<String, String> setupinformation,
      String biketype, bool isdefaultbike) async {
    await createSetup(bikename, 'Standard', setupinformation);

    if (isdefaultbike) {
      await setDefaultBike(bikename);
    }
    return await userbikesetup
        .doc(userID)
        .collection('UserData')
        .doc('BikeList')
        .set({
      bikename: biketype,
    }, SetOptions(merge: true));
  }

  Future createSetup(
    String bikename,
    String setupname,
    Map<String, String> setupinformation,
  ) async {
    await createFork(bikename, setupname);
    await createShock(bikename, setupname);
    await createFrontTire(bikename, setupname);
    await createRearTire(bikename, setupname);
    await createGeneralSettings(bikename, setupname);
    await createSetupList(bikename, setupname, setupinformation);
  }

  Future deleteBike(String bikename) async {
    var snapshots = await userbikesetup.doc(userID).collection(bikename).get();
    for (var doc in snapshots.docs) {
      await doc.reference.delete();
    }

    return await userbikesetup
        .doc(userID)
        .collection('UserData')
        .doc('BikeList')
        .update({bikename: FieldValue.delete()});
  }

  Future createFork(String bikename, String setupname) async {
    return await userbikesetup
        .doc(userID)
        .collection(bikename)
        .doc('Fork$setupname')
        .set({
      'Pressure': '90',
    }, SetOptions(merge: true));
  }

  Future createShock(String bikename, String setupname) async {
    return await userbikesetup
        .doc(userID)
        .collection(bikename)
        .doc('Shock$setupname')
        .set({'Pressure': '180'}, SetOptions(merge: true));
  }

  Future createFrontTire(String bikename, String setupname) async {
    return await userbikesetup
        .doc(userID)
        .collection(bikename)
        .doc('FrontTire$setupname')
        .set({'Pressure': '24'}, SetOptions(merge: true));
  }

  Future createRearTire(String bikename, String setupname) async {
    return await userbikesetup
        .doc(userID)
        .collection(bikename)
        .doc('RearTire$setupname')
        .set({'Pressure': '26'}, SetOptions(merge: true));
  }

  Future createGeneralSettings(String bikename, String setupname) async {
    return await userbikesetup
        .doc(userID)
        .collection(bikename)
        .doc('General$setupname')
        .set({'Reach': '90cm'}, SetOptions(merge: true));
  }

  Future setDefaultBike(String bikename) async {
    return await userbikesetup
        .doc(userID)
        .collection('UserData')
        .doc('DefaultBike')
        .set({'default': bikename}, SetOptions(merge: true));
  }

  Future setSetting(String key, String value, String bikename, String category,
      String setup) async {
    return await userbikesetup
        .doc(userID)
        .collection(bikename)
        .doc(category + setup)
        .set({key: value}, SetOptions(merge: true));
  }

  Future editSetting(String key, String value, String bikename, String category,
      String setup) async {
    return await userbikesetup
        .doc(userID)
        .collection(bikename)
        .doc('$category$setup')
        .update({key: value});
  }

  Future deleteSetting(
      String key, String bikename, String category, String setup) async {
    return await userbikesetup
        .doc(userID)
        .collection(bikename)
        .doc(category + setup)
        .update({
      key: FieldValue.delete(),
    });
  }

  Future createSetupList(String bikename, String setupname,
      Map<String, dynamic> suspension) async {
    return await userbikesetup
        .doc(userID)
        .collection(bikename)
        .doc('SetupList')
        .set({setupname: suspension}, SetOptions(merge: true));
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

  Stream getDocumentElement(String bikename, String category, String setup) {
    return userbikesetup
        .doc(userID)
        .collection(bikename)
        .doc('$category$setup')
        .snapshots();
  }

  Future<String> getDefaultBike() async {
    try {
      DocumentSnapshot snapshot = await userbikesetup
          .doc(userID)
          .collection('UserData')
          .doc('DefaultBike')
          .get();

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

  Future<String> getBikeType(String bikename) async {
    try {
      DocumentSnapshot snapshot = await userbikesetup
          .doc(userID)
          .collection('UserData')
          .doc('BikeList')
          .get();

      if (snapshot.exists) {
        dynamic value = snapshot[bikename];
        if (value != null) {
          return value.toString();
        } else {
          return '""';
        }
      } else {
        return '""';
      }
    } catch (e) {
      return '""';
    }
  }

  Future<String> getSuspensionType(String bikename) async {
    try {
      DocumentSnapshot snapshot = await userbikesetup
          .doc(userID)
          .collection('UserData')
          .doc('BikeList')
          .get();

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

  Future getSetupSettings(String bikename, String setupname) async {
    return await userbikesetup
        .doc(userID)
        .collection(bikename)
        .doc('SetupList')
        .get();
  }

  Future<String> getSetting(
      String bikename, String category, String setup, String key) async {
    try {
      DocumentSnapshot snapshot = await userbikesetup
          .doc(userID)
          .collection(bikename)
          .doc('$category$setup')
          .get();

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

  Stream getDocumentElementSnap(
      String bikename, String category, String setup) {
    return userbikesetup
        .doc(userID)
        .collection(bikename)
        .doc('$category$setup')
        .snapshots();
  }
}
