enum NewBikeMode {
  newBike,
  newSetup,
  editSetup;

  bool get isEdit => this == editSetup;
}
