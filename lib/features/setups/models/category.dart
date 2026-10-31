enum Category {
  rearTire(category: 'RearTire'),
  frontTire(category: 'FrontTire'),
  shock(category: 'Shock'),
  generalSettings(category: 'GeneralSettings'),
  frame(category: 'Frame'),
  cockpit(category: 'Cockpit'),
  saddle(category: 'Saddle'),
  fork(category: 'Fork');

  final String category;
  const Category({required this.category});
}
