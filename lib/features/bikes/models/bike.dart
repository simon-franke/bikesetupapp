import 'package:bikesetupapp/common/data/firestore_keys.dart';

class Bike {
  final String id;
  final String name;

  const Bike({required this.id, required this.name});

  factory Bike.fromMap(String id, Map<String, dynamic> data) {
    return Bike(
      id: id,
      name: data[FirestoreKeys.bikeName] as String? ?? '',

    );
  }
}
