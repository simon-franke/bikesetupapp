import 'component_type.dart';

/// Stable identifiers for a component's optional custom icon.
enum ServiceIcon {
  tools('Tools'),
  chain('Chain'),
  brakes('Brakes'),
  wheel('Wheel'),
  fork('Fork'),
  shock('Shock'),
  bearing('Bearing'),
  headset('Headset'),
  crank('Crank'),
  saddle('Saddle'),
  handlebar('Handlebar'),
  pedal('Pedal'),
  cassette('Cassette'),
  derailleur('Derailleur'),
  dropper('Dropper post'),
  rotor('Brake rotor'),
  bottle('Bottle'),
  bolt('Bolt');

  const ServiceIcon(this.label);
  final String label;

  static ServiceIcon forType(ComponentType type) => switch (type) {
        ComponentType.chain => ServiceIcon.chain,
        ComponentType.brakePadsFront ||
        ComponentType.brakePadsRear ||
        ComponentType.brakeBleeding =>
          ServiceIcon.brakes,
        ComponentType.tiresFront ||
        ComponentType.tiresRear ||
        ComponentType.tires =>
          ServiceIcon.wheel,
        ComponentType.forkServiceLower ||
        ComponentType.forkServiceFull =>
          ServiceIcon.fork,
        ComponentType.shockService => ServiceIcon.shock,
        ComponentType.wheelBearings => ServiceIcon.bearing,
        ComponentType.headsetBearing => ServiceIcon.headset,
        ComponentType.bottomBracket => ServiceIcon.crank,
        ComponentType.other => ServiceIcon.tools,
      };

  static ServiceIcon? fromName(String? name) {
    for (final icon in values) {
      if (icon.name == name) return icon;
    }
    return null;
  }
}
