import 'package:bikesetupapp/common/data/firestore_keys.dart';
import 'package:bikesetupapp/features/setups/controllers/setups_controller.dart';
import 'package:bikesetupapp/features/setups/models/setup_configuration.dart';
import 'package:bikesetupapp/features/setups/ui/field_meta.dart';
import 'package:bikesetupapp/features/setups/models/bike_setup.dart';
import 'package:flutter_test/flutter_test.dart';
import 'support/fake_repositories.dart';

void main() {
  test('configuration retains disabled selections and validates their keys',
      () {
    final configuration = SetupConfiguration({
      'Fork': ['Rebound'],
      'Luggage': ['Weight'],
    }, disabledCategories: {
      'Luggage'
    });
    final restored = SetupConfiguration.fromInformation({
      FirestoreKeys.setupConfiguration: configuration.encode(),
    });
    expect(restored.fields, {
      'Fork': ['Rebound']
    });
    expect(restored.storedFields, configuration.storedFields);
    expect(restored.disabledCategories, {'Luggage'});
    expect(() => SetupConfiguration({}, disabledCategories: {'Unknown'}),
        throwsFormatException);
    expect(() => restored.disabledCategories.clear(), throwsUnsupportedError);
    expect(() => restored.storedFields['Luggage']!.clear(),
        throwsUnsupportedError);
  });

  test('copy preserves active and disabled custom and built-in settings',
      () async {
    final repo = _CopyRepository()
      ..names['source'] = 'Original'
      ..information['source'] = {
        FirestoreKeys.setupConfiguration: SetupConfiguration({
          'Fork': ['Rebound'],
          'Luggage': ['Weight'],
          'Cockpit': ['Stem length'],
        }).encode(),
      }
      ..settings.addAll({
        'bike/source/Fork/Rebound': '5 clicks',
        'bike/source/Luggage/Weight': '3 kg',
        'bike/source/Cockpit/Stem length': '40 mm',
      })
      ..metadata['bike/source/Luggage/Weight'] = 'mass';
    final controller = SetupsController(repo);
    addTearDown(controller.dispose);
    for (final category in ['Luggage', 'Cockpit']) {
      expect(
          (await controller.setCategoryEnabled(
                  'bike', 'source', category, false,
                  addedFields: const {}))
              .isSuccess,
          isTrue);
    }
    expect(
        (await controller.copySetup('bike', 'copy', 'Copy', 'source'))
            .isSuccess,
        isTrue);
    var copied = SetupConfiguration.fromInformation(repo.information['copy']!);
    expect(copied.fields.keys, ['Fork']);
    expect(copied.disabledCategories, {'Luggage', 'Cockpit'});
    expect(repo.settings['bike/copy/Luggage/Weight'], '3 kg');
    expect(repo.settings['bike/copy/Cockpit/Stem length'], '40 mm');
    expect(repo.settings['bike/copy/Fork/Rebound'], '5 clicks');
    expect(repo.metadata['bike/copy/Luggage/Weight'], 'mass');
    expect(
        (await controller.setCategoryEnabled('bike', 'copy', 'Luggage', true,
                addedFields: {
              'Luggage': ['Different default']
            }))
            .isSuccess,
        isTrue);
    copied = SetupConfiguration.fromInformation(repo.information['copy']!);
    expect(copied.fields['Luggage'], ['Weight']);
  });

  test('setups require explicit configuration instead of inferred defaults',
      () {
    expect(() => SetupConfiguration.fromInformation({}), throwsFormatException);
    expect(() => SetupConfiguration.fromInformation({'shock': 'Air'}),
        throwsFormatException);
    expect(
        SetupConfiguration.fromInformation({
          FirestoreKeys.setupConfiguration: SetupConfiguration({}).encode(),
        }).fields,
        isEmpty);
  });
  test('custom categories start empty, retain values and reject unsafe names',
      () async {
    final repo = FakeSetupsRepository()
      ..names['setup'] = 'Default'
      ..information['setup'] = {
        FirestoreKeys.setupConfiguration: SetupConfiguration({}).encode()
      };
    final controller = SetupsController(repo);
    addTearDown(controller.dispose);
    final result = await controller.setCategoryEnabled(
        'bike', 'setup', 'Drivetrain', true,
        addedFields: kDefaultFieldKeys);
    expect(result.isSuccess, isTrue);
    expect(
        SetupConfiguration.fromInformation(repo.information['setup']!).fields,
        {'Drivetrain': <String>[]});
    await controller.addField(
        'Chain length', '112 count', 'bike', 'Drivetrain', 'setup');
    await controller.setCategoryEnabled('bike', 'setup', 'Drivetrain', false,
        addedFields: kDefaultFieldKeys);
    await controller.setCategoryEnabled('bike', 'setup', 'Drivetrain', true,
        addedFields: kDefaultFieldKeys);
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
      ..information['setup'] = {
        'note': 'Keep this',
        FirestoreKeys.setupConfiguration: testSetupConfiguration.encode()
      }
      ..settings['bike/setup/Fork/Pressure'] = '90 psi';
    final controller = SetupsController(repo);
    addTearDown(controller.dispose);
    Future<void> change(String category, bool enabled) async {
      final result = await controller.setCategoryEnabled(
          'bike', 'setup', category, enabled,
          addedFields: kDefaultFieldKeys);
      expect(result.isSuccess, isTrue);
    }

    await Future.wait([change('Fork', false), change('Shock', false)]);
    var config = SetupConfiguration.fromInformation(repo.information['setup']!);
    expect(config.fields.keys, ['FrontTire', 'RearTire', 'GeneralSettings']);
    expect(repo.information['setup']!['note'], 'Keep this');
    expect(repo.settings['bike/setup/Fork/Pressure'], '90 psi');
    await change('Fork', true);
    config = SetupConfiguration.fromInformation(repo.information['setup']!);
    expect(config.fields.containsKey('Fork'), isTrue);
    expect(repo.settings['bike/setup/Fork/Pressure'], '90 psi');
    await change('Tires', false);
    config = SetupConfiguration.fromInformation(repo.information['setup']!);
    expect(config.fields.containsKey('FrontTire'), isFalse);
    expect(config.fields.containsKey('RearTire'), isFalse);
    await change('Fork', false);
    await change('GeneralSettings', false);
    expect(
        SetupConfiguration.fromInformation(repo.information['setup']!).fields,
        isEmpty);
    await change('Tires', true);
    expect(
        SetupConfiguration.fromInformation(repo.information['setup']!)
            .fields
            .keys,
        ['FrontTire', 'RearTire']);
  });
}

class _CopyRepository extends FakeSetupsRepository {
  @override
  Stream<List<BikeSetup>> getSetups(String bike) => Stream.value([
        for (final entry in names.entries)
          BikeSetup(id: entry.key, name: entry.value),
      ]);

  @override
  Future<void> setSettingMeta(String key, String value, String bike,
      String category, String setup) async {
    metadata['$bike/$setup/$category/$key'] = value;
  }
}
