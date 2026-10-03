enum Category {
  rearTire(category: 'RearTire'),
  frontTire(category: 'FrontTire'),
  shock(category: 'Shock'),
  generalSettings(category: 'GeneralSettings'),
  fork(category: 'Fork');

  final String category;
  const Category({required this.category});
}
