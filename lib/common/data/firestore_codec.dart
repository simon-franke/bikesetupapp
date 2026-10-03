import 'package:cloud_firestore/cloud_firestore.dart';

Map<String, dynamic> decodeFirestoreMap(Map<String, dynamic> data) => {
      for (final entry in data.entries)
        entry.key: entry.value is Timestamp
            ? (entry.value as Timestamp).toDate()
            : entry.value,
    };

Map<String, dynamic> encodeFirestoreMap(Map<String, dynamic> data) => {
      for (final entry in data.entries)
        entry.key: entry.value is DateTime
            ? Timestamp.fromDate(entry.value as DateTime)
            : entry.value,
    };
