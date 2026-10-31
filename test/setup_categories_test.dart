import 'package:bikesetupapp/features/setups/controllers/setups_controller.dart';
import 'package:bikesetupapp/features/setups/models/setup_configuration.dart';
import 'package:bikesetupapp/features/setups/ui/field_meta.dart';
import 'package:bikesetupapp/features/setups/ui/setup_overview.dart';
import 'package:flutter_test/flutter_test.dart';
import 'support/fake_repositories.dart';

void main() {
  test('custom categories start empty, retain values and reject unsafe names',
      () async {
    final repo = FakeSetupsRepository()..names['setup'] = 'Default';
    final controller = SetupsController(repo);
    addTearDown(controller.dispose);
    final result = await controller.setCategoryEnabled(
        'bike', 'setup', 'Drivetrain', true,
        legacyFields: {}, addedFields: kDefaultFieldKeys);
    expect(result.isSuccess, isTrue);
    expect(
        SetupConfiguration.fromInformation(repo.information['setup']!)!.fields,
        {'Drivetrain': <String>[]});
    await controller.addField(
        'Chain length', '112 count', 'bike', 'Drivetrain', 'setup');
    await controller.setCategoryEnabled('bike', 'setup', 'Drivetrain', false,
        legacyFields: {}, addedFields: kDefaultFieldKeys);
    await controller.setCategoryEnabled('bike', 'setup', 'Drivetrain', true,
        legacyFields: {}, addedFields: kDefaultFieldKeys);
    expect(repo.settings['bike/setup/Drivetrain/Chain length'], '112 count');
    for (final name in ['', '../bad', 'Fork_meta', '__reserved__']) {
      expect(() => SetupConfiguration({name: []}), throwsFormatException);
    }
  });
  test(
      'category removal preserves values and metadata, readding restores category',
      () async {
    final repo = FakeSetupsRepository()
      ..names['setup'] = 'Default'
      ..information['setup'] = {'note': 'Keep this', 'activeTestId': 'test'}
      ..settings['bike/setup/Fork/Pressure'] = '90 psi';
    final controller = SetupsController(repo);
    addTearDown(controller.dispose);
    Future<void> change(String category, bool enabled) async {
      final result = await controller.setCategoryEnabled(
          'bike', 'setup', category, enabled,
          legacyFields: {
            for (final key in setupCategories()) key: kDefaultFieldKeys[key]!
          },
          addedFields: kDefaultFieldKeys);
      expect(result.isSuccess, isTrue);
    }

    await Future.wait([change('Fork', false), change('Shock', false)]);
    var config =
        SetupConfiguration.fromInformation(repo.information['setup']!)!;
    expect(config.fields.keys, ['FrontTire', 'RearTire', 'GeneralSettings']);
    expect(repo.information['setup']!['note'], 'Keep this');
    expect(repo.information['setup']!['activeTestId'], 'test');
    expect(repo.settings['bike/setup/Fork/Pressure'], '90 psi');
    await change('Fork', true);
    config = SetupConfiguration.fromInformation(repo.information['setup']!)!;
    expect(config.fields.containsKey('Fork'), isTrue);
    expect(repo.settings['bike/setup/Fork/Pressure'], '90 psi');
    await change('Tires', false);
    config = SetupConfiguration.fromInformation(repo.information['setup']!)!;
    expect(config.fields.containsKey('FrontTire'), isFalse);
    expect(config.fields.containsKey('RearTire'), isFalse);
    await change('Fork', false);
    await change('GeneralSettings', false);
    expect(
        SetupConfiguration.fromInformation(repo.information['setup']!)!.fields,
        isEmpty);
    await change('Tires', true);
    expect(
        SetupConfiguration.fromInformation(repo.information['setup']!)!
            .fields
            .keys,
        ['FrontTire', 'RearTire']);
  });
}
