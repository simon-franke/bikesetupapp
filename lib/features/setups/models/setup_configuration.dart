import 'dart:convert';

/// Explicit field selection for a setup. Missing metadata denotes a legacy setup.
class SetupConfiguration {
  static const metadataKey = 'setup_fields_v1';
  final Map<String, List<String>> fields;

  SetupConfiguration(Map<String, List<String>> fields)
      : fields = Map.unmodifiable({
          for (final entry in fields.entries)
            entry.key: List<String>.unmodifiable(entry.value),
        }) {
    if (fields.entries.any((entry) =>
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

  String encode() => jsonEncode(fields);

  static SetupConfiguration? fromInformation(Map<String, dynamic> information) {
    final encoded = information[metadataKey];
    if (encoded == null) return null;
    if (encoded is! String) {
      throw const FormatException('Invalid setup configuration');
    }
    final data = jsonDecode(encoded);
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Invalid setup configuration');
    }
    final fields = <String, List<String>>{};
    for (final entry in data.entries) {
      if (entry.value is! List ||
          (entry.value as List).any((field) => field is! String)) {
        throw const FormatException('Invalid setup fields');
      }
      fields[entry.key] = List<String>.from(entry.value as List);
    }
    return SetupConfiguration(fields);
  }
}
