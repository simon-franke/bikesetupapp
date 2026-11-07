import 'package:bikesetupapp/common/data/firestore_keys.dart';

/// Setup-list identity and display name; field values are stored separately.
class BikeSetup {
  final String id;
  final String name;

  const BikeSetup({required this.id, required this.name});

  factory BikeSetup.fromMap(String id, Map<String, dynamic> data) {
    return BikeSetup(
      id: id,
      name: data[FirestoreKeys.setupName] as String? ?? '',
    );
  }
}
