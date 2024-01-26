enum Category {
  reartire(category: 'RearTire'),
  fronttire(category: 'FrontTire'),
  shock(category: 'Shock'),
  generalsettings(category: 'GeneralSettings'),
  fork(category: 'Fork');

  final String category;
  const Category({required this.category});
}