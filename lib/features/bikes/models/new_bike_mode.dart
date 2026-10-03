enum NewBikeMode {
  newBike(
      appBarTitle: 'New Bike',
      hintTextTextField: 'Label your new Bike...',
      isEdit: false),
  newSetup(
      appBarTitle: 'New Setup',
      hintTextTextField: 'Label your new Setup...',
      isEdit: false),
  editSetup(appBarTitle: 'Edit Setup', hintTextTextField: '', isEdit: true),
  ;

  final String appBarTitle;
  final String hintTextTextField;
  final bool isEdit;
  const NewBikeMode(
      {required this.appBarTitle,
      required this.hintTextTextField,
      required this.isEdit});
}
