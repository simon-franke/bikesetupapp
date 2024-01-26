enum NewBikeMode {
  newBike(appBarTitle: 'New Bike', hintTextTextField: 'Label your new Bike...'),
  editBike(appBarTitle: 'Edit Bike', hintTextTextField: ''),
  newSetup(appBarTitle: 'New Setup', hintTextTextField: 'Label your new Setup...'),
  editSetup(appBarTitle: 'Edit Setup', hintTextTextField: '');

  final String appBarTitle;
  final String hintTextTextField;
  const NewBikeMode({required this.appBarTitle, required this.hintTextTextField});
}