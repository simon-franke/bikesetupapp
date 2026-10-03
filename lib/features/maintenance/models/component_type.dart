enum ComponentType {
  chain(
    label: 'Chain',
    icon: 'link',
    defaultIntervalKm: 2000,
  ),
  brakePadsFront(
    label: 'Brake Pads Front',
    icon: 'brake',
    defaultIntervalKm: 1000,
  ),
  brakePadsRear(
    label: 'Brake Pads Rear',
    icon: 'brake',
    defaultIntervalKm: 1000,
  ),
  tiresFront(
    label: 'Front Tire',
    icon: 'tire',
    defaultIntervalKm: 3000,
  ),
  tiresRear(
    label: 'Rear Tire',
    icon: 'tire',
    defaultIntervalKm: 3000,
  ),
  tires(
    label: 'Tires',
    icon: 'tire',
    defaultIntervalKm: 3000,
  ),
  forkServiceLower(
    label: 'Fork Lower Leg Service',
    icon: 'fork',
    defaultIntervalKm: 2000,
  ),
  forkServiceFull(
    label: 'Fork Full Service',
    icon: 'fork',
    defaultIntervalKm: 5000,
  ),
  shockService(
    label: 'Shock Service',
    icon: 'shock',
    defaultIntervalKm: 5000,
  ),
  wheelBearings(
    label: 'Wheel Bearings',
    icon: 'bearing',
    defaultIntervalKm: 5000,
  ),
  headsetBearing(
    label: 'Headset Bearing',
    icon: 'bearing',
    defaultIntervalKm: 5000,
  ),
  bottomBracket(
    label: 'Bottom Bracket',
    icon: 'bearing',
    defaultIntervalKm: 5000,
  ),
  brakeBleeding(
    label: 'Brake Bleeding',
    icon: 'brake',
    defaultIntervalKm: 3000,
  ),
  other(
    label: 'Other',
    icon: 'other',
    defaultIntervalKm: 0,
  );

  final String label;
  final String icon;
  final int defaultIntervalKm;

  const ComponentType({
    required this.label,
    required this.icon,
    required this.defaultIntervalKm,
  });

  static ComponentType fromString(String value) {
    try {
      return ComponentType.values.firstWhere((e) => e.name == value);
    } catch (e) {
      return ComponentType.other;
    }
  }
}
