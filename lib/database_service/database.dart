import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bikesetupapp/bike_enums/category.dart';
import 'package:bikesetupapp/database_service/firestore_keys.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:uuid/uuid.dart';

class DatabaseService {
  DatabaseService(this.userID);
  String userID;

  /// Collection reference for the 'UserBikeSetup' collection in the Firestore database.
  final CollectionReference userBikeSetup =
      FirebaseFirestore.instance.collection(FirestoreKeys.userBikeSetup);

  /// Creates a new bike in the database.
  ///
  /// The [bikeName] parameter specifies the name of the bike.
  /// The [setupInformation] parameter is a map that contains the setup information for the bike.
  /// The [bikeType] parameter specifies the type of the bike.
  ///
  /// Returns the unique identifier of the created bike.
  Future<String> createBike(String bikeName,
      Map<String, String> setupInformation, String bikeType) async {
    final String uBikeID = const Uuid().v4();
    final String uSetupID = const Uuid().v4();

    await createSetup(uBikeID, uSetupID, 'Default', setupInformation);

    if (await getDefaultBike() == "") {
      await setDefaultBike(uBikeID);
    }

    await setDefaultSetup(uBikeID, uSetupID);

    await setTodo(uBikeID, 'MyFirstTask', 'This is my first task', 'Breaks');

    await userBikeSetup.doc(userID).collection(FirestoreKeys.bikes).doc(uBikeID).set({
      FirestoreKeys.bikeName: bikeName,
      FirestoreKeys.bikeType: bikeType,
    }, SetOptions(merge: true));

    return uBikeID;
  }

  /// Creates a new setup in the database.
  ///
  /// The [uBikeID] parameter represents the user ID.
  /// The [uSetupID] parameter represents the setup ID.
  /// The [setupName] parameter represents the name of the setup.
  /// The [setupInformation] parameter is a map containing additional setup information.
  ///
  /// This method creates a fork, shock, front tire, rear tire, general settings,
  /// and adds the setup to the setup list in the database.
  Future createSetup(
    String uBikeID,
    String uSetupID,
    String setupName,
    Map<String, String> setupInformation,
  ) async {
    await createFork(uBikeID, uSetupID);
    await createShock(uBikeID, uSetupID, shockType: setupInformation['shock'] ?? 'Air');
    await createFrontTire(uBikeID, uSetupID);
    await createRearTire(uBikeID, uSetupID);
    await createGeneralSettings(uBikeID, uSetupID);
    await createSetupList(uBikeID, uSetupID, setupName, setupInformation);
  }

  /// Creates fork category with default values for the specified [uBikeID] and [uSetupID] in the database.
  ///
  /// The [uBikeID] parameter represents the user's unique identifier.
  /// The [uSetupID] parameter represents the user's session identifier.
  Future createFork(String uBikeID, String uSetupID) async {
    await setSetting('Pressure',    '90', uBikeID, Category.fork.category, uSetupID);
    await setSetting('Rebound',     '5',  uBikeID, Category.fork.category, uSetupID);
    await setSetting('Compression', '8',  uBikeID, Category.fork.category, uSetupID);
    await setSetting('Tokens',      '2',  uBikeID, Category.fork.category, uSetupID);
  }

  /// Creates shock category with default values for the specified [uBikeID] and [uSetupID] in the database.
  ///
  /// The [uBikeID] parameter represents the user's unique identifier.
  /// The [uSetupID] parameter represents the user's session identifier.
  Future createShock(String uBikeID, String uSetupID, {String shockType = 'Air'}) async {
    if (shockType == 'Coil') {
      await setSetting('Preload',      '0',   uBikeID, Category.shock.category, uSetupID);
      await setSetting('Spring Rate',  '450', uBikeID, Category.shock.category, uSetupID);
    } else {
      await setSetting('Pressure',    '180', uBikeID, Category.shock.category, uSetupID);
      await setSetting('Tokens',      '0',   uBikeID, Category.shock.category, uSetupID);
    }
    await setSetting('Rebound',     '5',   uBikeID, Category.shock.category, uSetupID);
    await setSetting('Compression', '8',   uBikeID, Category.shock.category, uSetupID);
  }

  /// Creates front tire category with default values for the specified [uBikeID] and [uSetupID] in the database.
  ///
  /// The [uBikeID] parameter represents the user's unique identifier.
  /// The [uSetupID] parameter represents the user's session identifier.
  Future createFrontTire(String uBikeID, String uSetupID) async {
    await setSetting('Pressure', '26', uBikeID, Category.frontTire.category, uSetupID);
  }

  /// Creates rear tire category with default values for the specified [uBIkeID] and [uSetupID] in the database.
  ///
  /// The [uBIkeID] parameter represents the user's unique identifier.
  /// The [uSetupID] parameter represents the user's session identifier.
  Future createRearTire(String uBIkeID, String uSetupID) async {
    await setSetting('Pressure', '26', uBIkeID, Category.rearTire.category, uSetupID);
  }

  /// Creates general settings category with default values for the specified [uBikeID] and [uSetupID] in the database.
  ///
  /// The [uBikeID] parameter represents the user's unique identifier.
  /// The [uSetupID] parameter represents the user's session identifier.
  Future createGeneralSettings(String uBikeID, String uSetupID) async {
    await setSetting(
        'Reach', '450mm', uBikeID, Category.generalSettings.category, uSetupID);
    await setSetting(
        'Stack Height', '20mm', uBikeID, Category.generalSettings.category, uSetupID);
    await setSetting(
        'Seat Height', '35mm', uBikeID, Category.generalSettings.category, uSetupID);
  }

  /// Creates a setup list in the database.
  ///
  /// Parameters:
  /// - [uBikeID]: The unique identifier of the user's bike.
  /// - [uSetupID]: The unique identifier of the setup list.
  /// - [setupName]: The name of the setup list.
  /// - [setupInformation]: A map containing the setup information.
  ///
  /// Returns:
  /// - A [Future] that completes when the setup list is created in the database.
  Future createSetupList(String uBikeID, String uSetupID, String setupName,
      Map<String, dynamic> setupInformation) {
    final Map<String, dynamic> setupListDocument = <String, dynamic>{};
    setupListDocument.addAll(setupInformation);
    setupListDocument[FirestoreKeys.setupName] = setupName;

    return userBikeSetup
        .doc(userID)
        .collection(FirestoreKeys.bikes)
        .doc(uBikeID)
        .collection(FirestoreKeys.setupList)
        .doc(uSetupID)
        .set(setupListDocument, SetOptions(merge: true));
  }

  /// Sets the default bike for the user.
  ///
  /// The [uBikeID] parameter is the ID of the bike to set as the default.
  ///
  /// Returns a [Future] that completes when the operation is done.
  ///
  /// Throws:
  /// - [FirebaseException]: If an error occurs while accessing the database.
  Future setDefaultBike(String uBikeID) {
    return userBikeSetup
        .doc(userID)
        .set({FirestoreKeys.defaultBike: uBikeID}, SetOptions(merge: true));
  }

  /// Sets the default setup for a bike in the database.
  ///
  /// Parameters:
  /// - [uBikeID]: The unique identifier of the bike.
  /// - [uSetupID]: The unique identifier of the setup.
  ///
  /// Throws:
  /// - [FirebaseException]: If an error occurs while accessing the database.
  ///
  /// Returns a [Future] that completes when the default setup is successfully set in the database.
  Future setDefaultSetup(String uBikeID, String uSetupID) {
    return userBikeSetup
        .doc(userID)
        .collection(FirestoreKeys.bikes)
        .doc(uBikeID)
        .set({FirestoreKeys.defaultSetup: uSetupID}, SetOptions(merge: true));
  }

  /// Sets a setting in the database for specific bike and setup.
  ///
  /// The [key] parameter specifies the key of the setting.
  /// The [value] parameter specifies the value of the setting.
  /// The [uBikeID] parameter specifies the unique bike ID.
  /// The [category] parameter specifies the category of the setting.
  /// The [uSetupID] parameter specifies the unique user ID.
  ///
  /// Throws:
  /// - [FirebaseException]: If an error occurs while accessing the database.
  ///
  /// Returns a [Future] that completes when the setting is successfully set in the database.
  Future setSetting(
      String key, String value, String uBikeID, String category, String uSetupID) {
    return userBikeSetup
        .doc(userID)
        .collection(FirestoreKeys.bikes)
        .doc(uBikeID)
        .collection(uSetupID)
        .doc(category)
        .set({key: value}, SetOptions(merge: true));
  }

  /// Edits a setting in the database for a specific bike and setup.
  /// Parameters:
  /// [key] - The key of the setting to be edited.
  /// [value] - The new value for the setting.
  /// [uBikeID] - The unique identifier of the bike.
  /// [category] - The category of the setting.
  /// [uSetupID] - The unique identifier of the user.
  ///
  /// Returns a [Future] that completes when the setting is successfully edited.
  Future editSetting(
      String key, String value, String uBikeID, String category, String uSetupID) {
    return userBikeSetup
        .doc(userID)
        .collection(FirestoreKeys.bikes)
        .doc(uBikeID)
        .collection(uSetupID)
        .doc(category)
        .update({key: value});
  }

  /// Sets a new To-Do item in the database.
  ///
  /// Parameters:
  /// - The [uBikeID] parameter specifies the unique identifier for the To-Do item.
  /// - The [taskName] parameter specifies the name of the task.
  /// - The [taskDescription] parameter specifies the description of the task.
  /// - The [part] parameter specifies the part associated with the task.
  ///
  /// Returns a [Future] that completes when the To-Do item is successfully set in the database.
  Future setTodo(
      String uBikeID, String taskName, String taskDescription, String part) {
    return userBikeSetup
        .doc(userID)
        .collection(FirestoreKeys.todoList)
        .doc(uBikeID)
        .collection(FirestoreKeys.myList)
        .doc()
        .set({
      FirestoreKeys.taskName: taskName,
      FirestoreKeys.taskDescription: taskDescription,
      FirestoreKeys.part: part,
      FirestoreKeys.done: false,
      FirestoreKeys.created: DateTime.now().toUtc(),
    }, SetOptions(merge: true));
  }

  /// Renames a bike in the database.
  ///
  /// Parameters:
  /// - The [uBikeID] parameter is the unique identifier of the bike.
  /// - The [bikeName] parameter is the new name for the bike.
  ///
  /// Throws:
  /// - [FirebaseException]: If there is an error accessing the database.
  ///
  /// Returns a [Future] that completes when the bike is successfully renamed.
  Future renameBike(String uBikeID, String bikeName) {
    return userBikeSetup
        .doc(userID)
        .collection(FirestoreKeys.bikes)
        .doc(uBikeID)
        .update({FirestoreKeys.bikeName: bikeName});
  }

  /// Edits a To-Do item in the database.
  ///
  /// Parameters:
  /// - [uBikeID]: The unique identifier of the user bike setup.
  /// - [docID]: The unique identifier of the To-Do item.
  /// - [taskName]: The name of the task.
  /// - [taskDescription]: The description of the task.
  /// - [part]: The part associated with the task.
  /// - [isDone]: Indicates whether the task is done or not.
  ///
  /// Throws:
  /// - [FirebaseException]: If there is an error accessing the database.
  ///
  /// Returns A [Future] that completes when the To-Do item is successfully edited.
  Future editTodo(String uBikeID, String docID, String taskName,
      String taskDescription, String part, bool isDone) {
    return userBikeSetup
        .doc(userID)
        .collection(FirestoreKeys.todoList)
        .doc(uBikeID)
        .collection(FirestoreKeys.myList)
        .doc(docID)
        .set({
      FirestoreKeys.taskName: taskName,
      FirestoreKeys.taskDescription: taskDescription,
      FirestoreKeys.part: part,
      FirestoreKeys.done: isDone,
    }, SetOptions(merge: true));
  }

  /// Deletes a To-Do item for a bike from the database.
  ///
  /// Parameters:
  /// - [uBikeID]: The unique identifier of the user bike setup.
  /// - [toDoID]: The unique identifier of the To-Do item.
  ///
  /// Throws:
  ///   [FirebaseException]: If there is an error accessing the database.
  ///
  /// Returns: A [Future] that completes when the To-Do item is successfully deleted.
  Future deleteTodo(String uBikeID, String toDoID) async {
    await userBikeSetup
        .doc(userID)
        .collection(FirestoreKeys.todoList)
        .doc(uBikeID)
        .collection(FirestoreKeys.myList)
        .doc(toDoID)
        .delete();
  }

  /// Updates the status of a To-Do item in the database.
  ///
  /// Parameters:
  /// - The [uBikeID] parameter is the unique identifier of the user bike setup.
  /// - The [toDoListID] parameter is the unique of the To-Do list.
  /// - The [isDone] parameter indicates whether the To-Do item is done or not.
  ///
  /// Throws:
  /// - [FirebaseException]: If there is an error accessing the database.
  ///
  /// Returns a [Future] that completes when the update is successful.
  Future updateTodoList(String uBikeID, String toDoListID, bool isDone) async {
    await userBikeSetup
        .doc(userID)
        .collection(FirestoreKeys.todoList)
        .doc(uBikeID)
        .collection(FirestoreKeys.myList)
        .doc(toDoListID)
        .update({FirestoreKeys.done: isDone});
  }

  //Delete functions

  /// Deletes a bike from the database.
  ///
  /// Parameters:
  /// - [uBikeID]: The unique identifier of the bike to be deleted.
  ///
  /// Throws:
  /// - [FirebaseException]: If there is an error accessing the database.
  ///
  /// Returns: A [Future] that completes when the bike is successfully deleted.
  Future deleteBike(String uBikeID) async {
    final wasDefault = (await getDefaultBike()) == uBikeID;

    var setups = await userBikeSetup
        .doc(userID)
        .collection(FirestoreKeys.bikes)
        .doc(uBikeID)
        .collection(FirestoreKeys.setupList)
        .get();
    for (var doc in setups.docs) {
      await _deleteSetupData(uBikeID, doc.id);
    }

    await userBikeSetup.doc(userID).collection(FirestoreKeys.bikes).doc(uBikeID).delete();

    if (wasDefault) {
      final remaining =
          await userBikeSetup.doc(userID).collection(FirestoreKeys.bikes).get();
      if (remaining.docs.isNotEmpty) {
        await setDefaultBike(remaining.docs.first.id);
      } else {
        await userBikeSetup
            .doc(userID)
            .update({FirestoreKeys.defaultBike: FieldValue.delete()});
      }
    }
  }

  /// Deletes a bike setup from the database.
  ///
  /// Parameters:
  /// - [uBikeID]: The ID of the user's bike.
  /// - [uSetupID]: The ID of the setup to be deleted.
  ///
  /// Throws:
  /// - [FirebaseException]: If there is an error accessing the database.
  ///
  /// Returns: A [Future] that completes when the setup is successfully deleted.
  Future deleteSetup(String uBikeID, String uSetupID) async {
    // If deleting the default setup, auto-reassign to another setup
    final currentDefault = await getDefaultSetup(uBikeID);
    if (currentDefault == uSetupID) {
      final setupList = await userBikeSetup
          .doc(userID)
          .collection(FirestoreKeys.bikes)
          .doc(uBikeID)
          .collection(FirestoreKeys.setupList)
          .get();
      final others =
          setupList.docs.where((d) => d.id != uSetupID).toList();
      if (others.isNotEmpty) {
        await setDefaultSetup(uBikeID, others.first.id);
      }
    }

    await _deleteSetupData(uBikeID, uSetupID);
  }

  Future _deleteSetupData(String uBikeID, String uSetupID) async {
    var setups = await userBikeSetup
        .doc(userID)
        .collection(FirestoreKeys.bikes)
        .doc(uBikeID)
        .collection(uSetupID)
        .get();

    for (var doc in setups.docs) {
      await doc.reference.delete();
    }

    await userBikeSetup
        .doc(userID)
        .collection(FirestoreKeys.bikes)
        .doc(uBikeID)
        .collection(FirestoreKeys.setupList)
        .doc(uSetupID)
        .delete();
  }

  /// Deletes a setting from the database for a specific bike and setup.
  ///
  /// Parameters:
  /// - The [key] parameter specifies the key of the setting to be deleted.
  /// - The [uBikeID] parameter specifies the unique identifier of the bike.
  /// - The [category] parameter specifies the category of the setting.
  /// - The [uSetupID] parameter specifies the unique identifier of the user.
  ///
  /// Throws:
  /// - [FirebaseException]: If there is an error accessing the database.
  ///
  /// Returns: A [Future] that completes when the setting is successfully deleted.
  Future deleteSetting(
      String key, String uBikeID, String category, String uSetupID) async {
    await userBikeSetup
        .doc(userID)
        .collection(FirestoreKeys.bikes)
        .doc(uBikeID)
        .collection(uSetupID)
        .doc(category)
        .update({
      key: FieldValue.delete(),
    });
  }

  //Get functions (snapshots)

  /// Retrieves the settings for a specific bike, category, and setup ID.
  ///
  /// The [uBikeID] parameter represents the unique ID of the bike.
  /// The [category] parameter represents the category of the settings.
  /// The [uSetupID] parameter represents the unique ID of the setup.
  ///
  /// Returns a [Stream] that emits snapshots of the settings document.
  Stream getSettings(String uBikeID, String category, String uSetupID) {
    return userBikeSetup
        .doc(userID)
        .collection(FirestoreKeys.bikes)
        .doc(uBikeID)
        .collection(uSetupID)
        .doc(category)
        .snapshots();
  }

  /// Returns a [stream] of bikes from the database.
  Stream getBikes() {
    return userBikeSetup.doc(userID).collection(FirestoreKeys.bikes).snapshots();
  }

  /// Retrieves a stream of setups for a given user bike ID.
  ///
  /// The [uBikeID] parameter specifies the user bike ID for which the setups are retrieved.
  /// Returns a [Stream] that emits snapshots of the setup list collection.
  Stream getSetups(String uBikeID) {
    return userBikeSetup
        .doc(userID)
        .collection(FirestoreKeys.bikes)
        .doc(uBikeID)
        .collection(FirestoreKeys.setupList)
        .snapshots();
  }

  /// Retrieves a stream of a specific document element from the database.
  ///
  /// The [uBikeID] parameter represents the unique identifier of the user's bike setup.
  /// The [category] parameter represents the category of the document.
  /// The [uSetupID] parameter represents the unique identifier of the user.
  ///
  /// Returns a [Stream] that emits snapshots of the specified document element.
  Stream getDocumentElement(String uBikeID, String category, String uSetupID) {
    return userBikeSetup
        .doc(userID)
        .collection(FirestoreKeys.bikes)
        .doc(uBikeID)
        .collection(uSetupID)
        .doc(category)
        .snapshots();
  }

  /// Retrieves a stream of To-Do list items for a specific user bike setup.
  ///
  /// The [uBikeID] parameter is the unique identifier of the user bike setup.
  /// Returns a [Stream] that emits snapshots of the To-Do list items.
  Stream getTodoList(String uBikeID) {
    return userBikeSetup
        .doc(userID)
        .collection(FirestoreKeys.todoList)
        .doc(uBikeID)
        .collection(FirestoreKeys.myList)
        .snapshots();
  }

  //get functions (single values)

  /// Retrieves the default bike from the database for the current user.
  ///
  /// Returns the default bike as a [string], or an empty string if it doesn't exist.
  Future<String> getDefaultBike() async {
    DocumentSnapshot snapshot;
    dynamic value;
    try {
      snapshot = await userBikeSetup.doc(userID).get();
      if (!snapshot.exists) {
        return "";
      }
      value = snapshot[FirestoreKeys.defaultBike];
    } catch (e) {
      debugPrint('getDefaultBike error: $e');
      return "";
    }
    if (value == null) {
      return "";
    }
    return value.toString();
  }

  /// Retrieves the default setup for a given user bike ID.
  ///
  /// The [uBikeID] parameter is the user bike ID.
  ///
  /// Returns a [Future] that completes with a [String] representing the default setup.
  /// If the user bike ID does not exist or if the default setup is not available, an empty string is returned.
  Future<String> getDefaultSetup(String uBikeID) async {
    DocumentSnapshot snapshot;
    dynamic value;
    try {
      snapshot =
          await userBikeSetup.doc(userID).collection(FirestoreKeys.bikes).doc(uBikeID).get();
      if (!snapshot.exists) {
        return "";
      }
      value = snapshot[FirestoreKeys.defaultSetup];
    } catch (e) {
      debugPrint('getDefaultSetup error: $e');
      return "";
    }
    return value.toString();
  }

  /// Retrieves the name of a bike from its unique ID.
  ///
  /// Parameters:
  /// - [uBikeID]: The unique ID of the bike.
  ///
  /// Returns the name of the bike as a [String]. If the bike does not exist or if an error occurs,
  /// an empty string is returned.
  Future<String> getBikeNameFromID(String uBikeID) async {
    DocumentSnapshot snapshot;
    dynamic value;
    try {
      snapshot =
          await userBikeSetup.doc(userID).collection(FirestoreKeys.bikes).doc(uBikeID).get();
      if (!snapshot.exists) {
        return "";
      }
      value = snapshot[FirestoreKeys.bikeName];
    } catch (e) {
      debugPrint('getBikeNameFromID error: $e');
      return "";
    }

    if (value == null) {
      return "";
    }
    return value.toString();
  }

  /// Retrieves the Setup name for a given bike ID and setup ID.
  ///
  /// Parameters:
  /// - The [uBikeID] Parameter specifies the unique bike identifier.
  /// - The [uSetupID] Parameter specifies the unique setup identifier.
  ///
  /// Returns a [Future] that completes with a [String] representing the setup name.
  /// If the user bike ID or setup ID is not found or an error occurs, an empty string is returned.
  Future<String> getSetupNameFromID(String uBikeID, String uSetupID) async {
    DocumentSnapshot snapshot;
    dynamic value;
    try {
      snapshot = await userBikeSetup
          .doc(userID)
          .collection(FirestoreKeys.bikes)
          .doc(uBikeID)
          .collection(FirestoreKeys.setupList)
          .doc(uSetupID)
          .get();
      if (!snapshot.exists) {
        return "";
      }
      value = snapshot[FirestoreKeys.setupName];
    } catch (e) {
      debugPrint('getSetupNameFromID error: $e');
      return "";
    }
    if (value == null) {
      return "";
    }
    return value.toString();
  }

  /// Retrieves the bike type for a given user bike ID.
  ///
  /// Parameters:
  /// - The [uBikeID] Parameter specifies the ub unique bike identifier.
  ///
  /// Returns a [Future] that completes with a [String] representing the bike type.
  /// If the user bike ID is not found or an error occurs, an empty string is returned.
  Future<String> getBikeType(String uBikeID) async {
    DocumentSnapshot snapshot;
    dynamic value;
    try {
      snapshot =
          await userBikeSetup.doc(userID).collection(FirestoreKeys.bikes).doc(uBikeID).get();
      if (!snapshot.exists) {
        return "";
      }
      value = snapshot[FirestoreKeys.bikeType];
    } catch (e) {
      debugPrint('getBikeType error: $e');
      return "";
    }
    if (value == null) {
      return "";
    }
    return value.toString();
  }

  /// Retrieves the setup information for a specific bike setup.
  ///
  /// The [uBikeID] parameter represents the unique identifier of the bike.
  /// The [uSetupID] parameter represents the unique identifier of the setup.
  ///
  /// Returns a [Future] that resolves to the setup information.
  Future getSetupInformation(String uBikeID, String uSetupID) {
    return userBikeSetup
        .doc(userID)
        .collection(FirestoreKeys.bikes)
        .doc(uBikeID)
        .collection(FirestoreKeys.setupList)
        .doc(uSetupID)
        .get();
  }

  /// Retrieves the setup information as a map for a given user bike ID (uBikeID) and user setup ID (uSetupID).
  ///
  /// Parameters:
  /// - The [uBikeID] specifies the unique bike identifier
  /// - The [uSetupID] specifies the unique setup identifier
  ///
  /// Returns a [Future] that resolves to a Map\<String, dynamic\> containing the setup information.
  /// If the setup information does not exist, an empty map is returned.
  Future<Map<String, dynamic>> getSetupInformationAsMap(
      String uBikeID, String uSetupID) async {
    DocumentSnapshot snapshot = await getSetupInformation(uBikeID, uSetupID);

    if (!snapshot.exists) {
      return {};
    }
    return snapshot.data() as Map<String, dynamic>? ?? {};
  }
}
