import 'package:bikesetupapp/bike_enums/biketype.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bikesetupapp/bike_enums/category.dart';
import 'package:uuid/uuid.dart';

class DatabaseService {
  DatabaseService(this.userID);
  String userID;

  /**
   * This is the reference to the collection of the userbikesetup.
   */ ///
  final CollectionReference userbikesetup =
      FirebaseFirestore.instance.collection('UserBikeSetup');

  /**
   * This function is used to create a new bike.
   * 
   * @param bikename The name of the bike.
   * @param setupinformation information about the setup.
   * @param biketype The type of the bike.
   * @param isdefaultbike A boolean to check if the bike should be the default bike.
   */ ///
  Future<String> createBike(
      String bikename,
      Map<String, String> setupinformation,
      String biketype,
      bool isdefaultbike) async {
    String ubid = const Uuid().v4();
    String usid = const Uuid().v4();

    await createSetup(ubid, usid, 'Default', setupinformation);

    if (isdefaultbike) {
      await setDefaultBike(ubid);
      await setDefaultSetup(ubid, usid);
    }
    await createTodoList(ubid);
    await userbikesetup.doc(userID).collection('Bikes').doc(ubid).set({
      'bikename': bikename,
      'biketype': biketype,
    }, SetOptions(merge: true));

    return ubid;
  }

  /**
   * This function is used to create a new setup for a bike.
   * 
   * @param ubid The unique id of the bike.
   * @param usid The unique id of the setup.
   * @param setupname The name of the setup.
   * @param setupinformation information about the setup.
   */ ///

  Future createSetup(
    String ubid,
    String usid,
    String setupname,
    Map<String, String> setupinformation,
  ) async {
    await createFork(ubid, usid);
    await createShock(ubid, usid);
    await createFrontTire(ubid, usid);
    await createRearTire(ubid, usid);
    await createGeneralSettings(ubid, usid);
    await createSetupList(ubid, usid, setupname, setupinformation);
  }

  /**
   * This function is used to create the default settings for the fork.
   * 
   * @param ubid The unique id of the bike.
   * @param usid The unique id of the setup.
   */ ///
  Future createFork(String ubid, String usid) async {
    return await userbikesetup
        .doc(userID)
        .collection('Bikes')
        .doc(ubid)
        .collection(usid)
        .doc(Category.fork.category)
        .set({
      'Pressure': '90',
    }, SetOptions(merge: true));
  }

  /**
   * This function is used to create the default settings for the shock.
   * 
   * @param ubid The unique id of the bike.
   * @param usid The unique id of the setup.
   */ ///
  Future createShock(String ubid, String usid) async {
    return await userbikesetup
        .doc(userID)
        .collection('Bikes')
        .doc(ubid)
        .collection(usid)
        .doc(Category.shock.category)
        .set({'Pressure': '180'}, SetOptions(merge: true));
  }

  /**
   * This function is used to create the default settings for the front tire.
   * 
   * @param ubid The unique id of the bike.
   * @param usid The unique id of the setup.
   */ ///
  Future createFrontTire(String ubid, String usid) async {
    return await userbikesetup
        .doc(userID)
        .collection('Bikes')
        .doc(ubid)
        .collection(usid)
        .doc(Category.fronttire.category)
        .set({'Pressure': '24'}, SetOptions(merge: true));
  }

  /**
   * This function is used to create the default settings for the rear tire.
   * 
   * @param ubid The unique id of the bike.
   * @param usid The unique id of the setup.
   */ ///
  Future createRearTire(String ubid, String usid) async {
    return await userbikesetup
        .doc(userID)
        .collection('Bikes')
        .doc(ubid)
        .collection(usid)
        .doc(Category.reartire.category)
        .set({'Pressure': '26'}, SetOptions(merge: true));
  }

  /**
   * This function is used to create the default settings for general settings.
   * 
   * @param ubid The unique id of the bike.
   * @param usid The unique id of the setup.
   */ ///
  Future createGeneralSettings(String ubid, String usid) async {
    return await userbikesetup
        .doc(userID)
        .collection('Bikes')
        .doc(ubid)
        .collection(usid)
        .doc(Category.generalsettings.category)
        .set({'Reach': '450mm', 'Stackhight': '20mm', 'Seathight': '35mm'},
            SetOptions(merge: true));
  }

  /**
   * This function is used to create a new setup list for a bike.
   * 
   * @param ubid The unique id of the bike.
   * @param usid The unique id of the setup.
   * @param setupname The name of the setup.
   * @param setupinformation information about the setup.
   */ ///
  Future createSetupList(String ubid, String usid, String setupname,
      Map<String, dynamic> setupinformation) async {
    setupinformation['setupname'] = setupname;

    return await userbikesetup
        .doc(userID)
        .collection('Bikes')
        .doc(ubid)
        .collection('SetupList')
        .doc(usid)
        .set(setupinformation, SetOptions(merge: true));
  }

  /**
   * This function is used to create a new todo list for a bike.
   * 
   * @param ubid The unique id of the bike.
   */ ///
  Future createTodoList(String ubid) async {
    return await userbikesetup
        .doc(userID)
        .collection('ToDoList')
        .doc(ubid)
        .collection('MyList')
        .doc()
        .set({
      'taskname': 'My First Task',
      'taskdescription': 'This is my first task',
      'Part': 'Breaks',
      'done': false,
      'created': DateTime.now()
    }, SetOptions(merge: true));
  }

  //set functions

  /**
   * This function is used to set the default bike.
   * 
   * @param bikename The name of the bike.
   */ ///
  Future setDefaultBike(String ubid) async {
    return await userbikesetup
        .doc(userID)
        .set({'defaultbike': ubid}, SetOptions(merge: true));
  }

  Future setDefaultSetup(String ubid, String usid) async {
    return await userbikesetup
        .doc(userID)
        .collection('Bikes')
        .doc(ubid)
        .set({'defaultSetup': usid}, SetOptions(merge: true));
  }

  /**
   * This function is used to set a setting for a bike.
   * 
   * @param key The key of the setting.
   * @param value The value of the setting.
   * @param ubid The unique id of the bike.
   * @param category The category of the setting.
   * @param usid The unique id of the setup.
   */ ///
  Future setSetting(String key, String value, String ubid, String category,
      String usid) async {
    return await userbikesetup
        .doc(userID)
        .collection('Bikes')
        .doc(ubid)
        .collection(usid)
        .doc(category)
        .set({key: value}, SetOptions(merge: true));
  }

  /**
   * This function is used to set a setting for a bike.
   * 
   * @param key The key of the setting.
   * @param value The value of the setting.
   * @param ubid The unique id of the bike.
   * @param category The category of the setting.
   * @param usid The unique id of the setup.
   */ ///
  Future editSetting(String key, String value, String ubid, String category,
      String usid) async {
    return await userbikesetup
        .doc(userID)
        .collection('Bikes')
        .doc(ubid)
        .collection(usid)
        .doc(category)
        .update({key: value});
  }

  /**
   * This function is used to set a todo for a bike.
   * 
   * @param ubid The unique id of the bike.
   * @param taskname The name of the task.
   * @param taskdescription The description of the task.
   * @param part The part of the bike.
   */ ///
  Future setTodo(
      String ubid, String taskname, String taskdescription, String part) async {
    return await userbikesetup
        .doc(userID)
        .collection('ToDoList')
        .doc(ubid)
        .collection('MyList')
        .doc()
        .set({
      'taskname': taskname,
      'taskdescription': taskdescription,
      'Part': part,
      'done': false,
      'created': DateTime.now()
    }, SetOptions(merge: true));
  }

  Future renameBike (String ubid, String bikename) {
    return userbikesetup
        .doc(userID)
        .collection('Bikes')
        .doc(ubid)
        .update({'bikename': bikename});
  }

  /**
   * This function is used to set a todo for a bike.
   * 
   * @param ubid The unique id of the bike.
   * @param docID The unique id of the todo.
   * @param taskname The name of the task.
   * @param taskdescription The description of the task.
   * @param part The part of the bike.
   * @param isdone A boolean to check if the task is done.
   */ ///
  Future editTodo(String ubid, String docID, String taskname,
      String taskdescription, String part, bool isdone) async {
    return await userbikesetup
        .doc(userID)
        .collection('ToDoList')
        .doc(ubid)
        .collection('MyList')
        .doc(docID)
        .set({
      'taskname': taskname,
      'taskdescription': taskdescription,
      'Part': part,
      'done': isdone,
    }, SetOptions(merge: true));
  }

  /**
   * This function is used to delete a todo for a bike.
   * 
   * @param ubid The unique id of the bike.
   */ ///
  Future deleteTodo(String ubid, String todoid) async {
    return await userbikesetup
        .doc(userID)
        .collection('ToDoList')
        .doc(ubid)
        .collection('MyList')
        .doc(todoid)
        .delete();
  }

  /**
   * This function is used to change the name of a bike.
   * 
   * @param bikeNameOld The old name of the bike.
   * @param bikeNameNew The new name of the bike.
   * @param biketype The type of the bike.
   */ ///
  Future setBikeName(
      String bikeNameOld, String bikeNameNew, BikeType biketype) async {
    await userbikesetup
        .doc(userID)
        .collection('Bikes')
        .doc(bikeNameOld)
        .get()
        .then((value) {
      if (value.exists) {
        userbikesetup
            .doc(userID)
            .collection('Bikes')
            .doc(bikeNameNew)
            .set(value.data()!);
      }
    });
    await userbikesetup
        .doc(userID)
        .collection('UserData')
        .doc('BikeList')
        .update({bikeNameOld: FieldValue.delete()});
    return await userbikesetup
        .doc(userID)
        .collection('UserData')
        .doc('BikeList')
        .set({bikeNameNew: biketype.biketype}, SetOptions(merge: true));
  }

  /**
   * This function is used to update a todolistentry for a bike.
   * 
   * @param ubid The unique id of the bike.
   * @param todolistid The unique id of the todo.
   * @param isdone A boolean to check if the task is done.
   */ ///
  Future updateTodoList(String ubid, String todolistid, bool isdone) async {
    return await userbikesetup
        .doc(userID)
        .collection('ToDoList')
        .doc(ubid)
        .collection('MyList')
        .doc(todolistid)
        .update({'done': isdone});
  }

  //Delete functions
  Future deleteBike(String ubid) async {
    var setups = await userbikesetup
        .doc(userID)
        .collection('Bikes')
        .doc(ubid)
        .collection('SetupList')
        .get();
    for (var doc in setups.docs) {
      await deleteSetup(ubid, doc.id);
    }

    await userbikesetup.doc(userID).collection('Bikes').doc(ubid).delete();
  }

  Future deleteSetup(String ubid, String usid) async {
    var setups = await userbikesetup
        .doc(userID)
        .collection('Bikes')
        .doc(ubid)
        .collection(usid)
        .get();

    for (var doc in setups.docs) {
      await doc.reference.delete();
    }

    await userbikesetup
        .doc(userID)
        .collection('Bikes')
        .doc(ubid)
        .collection('SetupList')
        .doc(usid)
        .delete();
  }

  Future deleteSetting(
      String key, String bikename, String category, String setup) async {
    return await userbikesetup
        .doc(userID)
        .collection('Bikes')
        .doc(bikename)
        .collection(setup)
        .doc(category)
        .update({
      key: FieldValue.delete(),
    });
  }

  //Get functions (snapshots)
  Stream getSettings(String bikename, String category, String setup) {
    return userbikesetup
        .doc(userID)
        .collection('Bikes')
        .doc(bikename)
        .collection(setup)
        .doc(category)
        .snapshots();
  }

  Stream getBikes() {
    return userbikesetup.doc(userID).collection('Bikes').snapshots();
  }

  Stream getSetups(String ubid) {
    return userbikesetup
        .doc(userID)
        .collection('Bikes')
        .doc(ubid)
        .collection('SetupList')
        .snapshots();
  }

  Stream getDocumentElement(String bikename, String category, String setup) {
    return userbikesetup
        .doc(userID)
        .collection('Bikes')
        .doc(bikename)
        .collection(setup)
        .doc(category)
        .snapshots();
  }

  Stream getTodoList(String bikename) {
    return userbikesetup
        .doc(userID)
        .collection('ToDoList')
        .doc(bikename)
        .collection('MyList')
        .snapshots();
  }

  //get functions (single values)
  Future<String> getDefaultBike() async {
    try {
      DocumentSnapshot snapshot = await userbikesetup.doc(userID).get();
      if (snapshot.exists) {
        dynamic value = snapshot['defaultbike'];
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

  Future<String> getDefaultSetup(String ubid) async {
    try {
      DocumentSnapshot snapshot =
          await userbikesetup.doc(userID).collection('Bikes').doc(ubid).get();
      if (snapshot.exists) {
        dynamic value = snapshot['defaultSetup'];
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

  Future<String> getBikeNameFromID(String ubid) async {
    try {
      DocumentSnapshot snapshot =
          await userbikesetup.doc(userID).collection('Bikes').doc(ubid).get();

      if (snapshot.exists) {
        dynamic value = snapshot['bikename'];
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

  Future<String> getSetupNameFromID(String ubid, String usid) async {
    try {
      DocumentSnapshot snapshot = await userbikesetup
          .doc(userID)
          .collection('Bikes')
          .doc(ubid)
          .collection('SetupList')
          .doc(usid)
          .get();

      if (snapshot.exists) {
        dynamic value = snapshot['setupname'];
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

  Future<String> getFirstBike() async {
    final DocumentSnapshot documentSnapshot = await userbikesetup
        .doc(userID)
        .collection('UserData')
        .doc('BikeList')
        .get();

    final Map<String, dynamic>? data =
        documentSnapshot.data() as Map<String, dynamic>?;
    if (data == null) {
      return '';
    }
    final String firstField = data.entries.first.key.toString();
    return firstField;
  }

  Future<String> getBikeType(String ubid) async {
    try {
      DocumentSnapshot snapshot =
          await userbikesetup.doc(userID).collection('Bikes').doc(ubid).get();

      if (snapshot.exists) {
        dynamic value = snapshot['biketype'];
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

  Future getSetupInformation(String ubid, String usid) async {
    return userbikesetup
        .doc(userID)
        .collection('Bikes')
        .doc(ubid)
        .collection('SetupList')
        .doc(usid)
        .get();
  }

  Future<Map<String, dynamic>> getSetupInformationAsMap(
      String ubid, String usid) async {
    DocumentSnapshot snapshot = await userbikesetup
        .doc(userID)
        .collection('Bikes')
        .doc(ubid)
        .collection('SetupList')
        .doc(usid)
        .get();

    if (snapshot.exists) {
      return snapshot.data() as Map<String, dynamic>;
    } else {
      return {};
    }
  }
}
