import 'dart:convert';

import 'package:bikesetupapp/common/data/firestore_keys.dart';

/// Required category and field selection for a setup.
class SetupConfiguration {
  /// Includes disabled categories so their field selections survive copying.
  final Map<String, List<String>> storedFields;
  final Set<String> disabledCategories;

  /// Active fields used by the workspace and experiment snapshots.
  Map<String, List<String>> get fields => Map.unmodifiable({
        for (final entry in storedFields.entries)
          if (!disabledCategories.contains(entry.key)) entry.key: entry.value,
      });

  SetupConfiguration(Map<String, List<String>> fields,
      {Set<String> disabledCategories = const {}})
      : disabledCategories = Set.unmodifiable(disabledCategories),
        storedFields = Map.unmodifiable({
          for (final entry in fields.entries)
            entry.key: List<String>.unmodifiable(entry.value),
        }) {
    if (!fields.keys.toSet().containsAll(disabledCategories) ||
        fields.entries.any((entry) =>
            !isValidCategoryName(entry.key) ||
            entry.value.any((key) => key.trim().isEmpty || key.length > 100) ||
            entry.value.toSet().length != entry.value.length)) {
      throw const FormatException('Invalid setup field configuration');
    }
  }

  static bool isValidCategoryName(String name) =>
      name.trim() == name &&
      name.isNotEmpty &&
      name.length <= 60 &&
      !name.contains('/') &&
      name != '.' &&
      name != '..' &&
      !name.startsWith('__') &&
      !name.endsWith('_meta') &&
      !name.contains(RegExp(r'[\x00-\x1F]'));

  String encode() => jsonEncode({
        'fields': storedFields,
        'disabledCategories': disabledCategories.toList(),
      });

  static SetupConfiguration fromInformation(Map<String, dynamic> information) {
    final encoded = information[FirestoreKeys.setupConfiguration];
    if (encoded is! String) {
      throw const FormatException('Invalid setup configuration');
    }

    final data = jsonDecode(encoded);
    if (data is! Map<String, dynamic> ||
        data['fields'] is! Map<String, dynamic> ||
        data['disabledCategories'] is! List ||
        (data['disabledCategories'] as List).any((key) => key is! String)) {
      throw const FormatException('Invalid setup configuration');
    }

    final fields = <String, List<String>>{};

    for (final entry in (data['fields'] as Map<String, dynamic>).entries) {
      if (entry.value is! List ||
          (entry.value as List).any((field) => field is! String)) {
        throw const FormatException('Invalid setup fields');
      }
      fields[entry.key] = List<String>.from(entry.value as List);
    }

    return SetupConfiguration(fields,
        disabledCategories:
            Set<String>.from(data['disabledCategories'] as List));
  }
}
