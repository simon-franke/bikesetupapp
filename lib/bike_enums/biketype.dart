enum BikeType {
  road(biketype: 'Road'),
  fullsuspension(biketype: 'Fullsuspension'),
  hardtail(biketype: 'Hardtail'),
  error(biketype: 'Error');

  final String biketype;
  const BikeType({required this.biketype});

  static BikeType fromString(String biketype) {
    try {
      return BikeType.values.firstWhere((e) => e.biketype == biketype);
    } catch (e) {
      return BikeType.error;
    }
  }
}