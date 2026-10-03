enum BikeType {
  dh(
      bikeType: 'Downhill Bike',
      path: "assets/DH.png",
      hasShock: true,
      hasFork: true),
  enduro(
      bikeType: 'Enduro Bike',
      path: "assets/Enduro.png",
      hasShock: true,
      hasFork: true),
  dirtjump(
      bikeType: 'Dirt Bike',
      path: "assets/Dirt.png",
      hasShock: false,
      hasFork: true),
  xc(
      bikeType: 'Cross Country Bike',
      path: "assets/XC.png",
      hasShock: false,
      hasFork: true),
  singlespeed(
      bikeType: 'Singlespeed Bike',
      path: "assets/Singlespeed.png",
      hasShock: false,
      hasFork: false),
  road(
      bikeType: 'Road Bike',
      path: "assets/Road.png",
      hasShock: false,
      hasFork: false),
  error(
      bikeType: 'Error',
      path: "No Bike Found",
      hasShock: false,
      hasFork: false);

  final String bikeType;
  final String path;
  final bool hasShock;
  final bool hasFork;
  const BikeType(
      {required this.bikeType,
      required this.path,
      required this.hasShock,
      required this.hasFork});

  static BikeType fromString(String bikeType) {
    try {
      return BikeType.values.firstWhere((e) => e.bikeType == bikeType);
    } catch (e) {
      return BikeType.error;
    }
  }
}
