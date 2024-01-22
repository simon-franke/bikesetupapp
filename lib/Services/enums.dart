enum NewBikeMode {
  newBike(appBarTitle: 'New Bike', hintTextTextField: 'Label your new Bike...'),
  editBike(appBarTitle: 'Edit Bike', hintTextTextField: ''),
  newSetup(appBarTitle: 'New Setup', hintTextTextField: 'Label your new Setup...'),
  editSetup(appBarTitle: 'Edit Setup', hintTextTextField: '');

  final String appBarTitle;
  final String hintTextTextField;
  const NewBikeMode({required this.appBarTitle, required this.hintTextTextField});
}

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

enum Category {
  reartire(category: 'RearTire'),
  fronttire(category: 'FrontTire'),
  shock(category: 'Shock'),
  generalsettings(category: 'GeneralSettings'),
  fork(category: 'Fork');

  final String category;
  const Category({required this.category});
}