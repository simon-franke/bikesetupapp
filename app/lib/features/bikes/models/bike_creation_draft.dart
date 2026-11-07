import '../../setups/models/setup_configuration.dart';

/// Reviewable input shared by manual creation and future spec import adapters.
/// Creating a draft never writes data or invents riding settings.
class BikeCreationDraft {
  final String name;

  final SetupConfiguration configuration;
  final Map<String, String> specifications;
  final Map<String, Map<String, String>> values;

  BikeCreationDraft({required String name, required this.configuration, Map<String, String> specifications = const {}, Map<String, Map<String, String>> values = const {}})
      : name = name.trim(), specifications = Map.unmodifiable(specifications),
        values = Map.unmodifiable(values.map((key, value) => MapEntry(key, Map<String, String>.unmodifiable(value)))) {
    for (final category in this.values.entries) {
      for (final field in category.value.keys) {
        if (!(configuration.fields[category.key]?.contains(field) ?? false)) {
          throw const FormatException('Value does not belong to a configured part');
        }
      }
    }
    if (this.name.isEmpty || this.name.length > 100) {
      throw const FormatException('Enter a bike name');
    }
    if (!configuration.fields.containsKey('FrontTire') ||
        !configuration.fields.containsKey('RearTire')) {
      throw const FormatException('Both tires must be configured');
    }
  }

  Map<String, String> toSetupInformation() => {
    ...specifications,
    SetupConfiguration.metadataKey: configuration.encode(),
  };
}
