import 'package:bikesetupapp/features/maintenance/models/component_type.dart';
import 'package:bikesetupapp/features/maintenance/ui/service_component_form_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late ServiceComponentFormState form;
  setUp(() =>
      form = ServiceComponentFormState()..selectType(ComponentType.chain));
  tearDown(() => form.dispose());

  test('rejects nonfinite, nonpositive and fractional distance intervals', () {
    for (final value in ['', 'NaN', 'Infinity', '-10', '0', '10.5']) {
      form.intervalController.text = value;
      expect(form.validate(), isFalse, reason: value);
      expect(form.intervalError, isNotNull);
    }
    form.intervalController.text = '1000';
    expect(form.validate(), isTrue);
    expect(form.interval, 1000);
  });

  test('usage accepts blank and decimal comma but rejects invalid values', () {
    form.changeUnit(true);
    form.intervalController.text = '50.5';
    for (final value in ['-1', 'NaN', 'Infinity', 'no']) {
      form.initialHours.text = value;
      expect(form.validate(), isFalse, reason: value);
      expect(form.usageError, isNotNull);
    }
    form.initialHours.text = '1,5';
    expect(form.validate(), isTrue);
    expect(form.initialUsage, 1.5);
    form.initialHours.clear();
    expect(form.validate(), isTrue);
    expect(form.initialUsage, 0);
  });

  test('switching units revalidates the active draft after submission', () {
    form.intervalController.text = '1000';
    expect(form.validate(), isTrue);
    form.changeUnit(true);
    expect(form.intervalError, isNotNull);
    form.intervalController.text = '50.5';
    form.initialHours.text = '4';
    expect(form.validate(), isTrue);
    form.changeUnit(false);
    expect(form.intervalController.text, '1000');
    expect(form.intervalError, isNull);
    expect(form.initialUsage, 0);
    form.changeUnit(true);
    expect(form.interval, 50.5);
    expect(form.initialUsage, 4);
  });
}
