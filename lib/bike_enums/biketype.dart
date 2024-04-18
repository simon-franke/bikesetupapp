enum BikeType {
  downhill(biketype: 'DH', hasShock: true, hasFork: true),
  fullsuspension(biketype: 'Fullsuspension', hasShock: true, hasFork: true),
  hardtail(biketype: 'Hardtail', hasShock: false, hasFork: true),
  singlespeed(biketype: 'Singlespeed', hasShock: false, hasFork: false),
  road(biketype: 'Road', hasShock: false, hasFork: false),
  error(biketype: 'Error', hasShock: false, hasFork: false);

  final String biketype;
  final bool hasShock;
  final bool hasFork;
  const BikeType(
      {required this.biketype, required this.hasShock, required this.hasFork});

  static BikeType fromString(String biketype) {
    try {
      return BikeType.values.firstWhere((e) => e.biketype == biketype);
    } catch (e) {
      return BikeType.error;
    }
  }
}
