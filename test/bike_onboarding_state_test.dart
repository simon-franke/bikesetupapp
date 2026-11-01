import 'package:flutter_test/flutter_test.dart';
import 'package:bikesetupapp/features/bikes/ui/bike_onboarding_state.dart';

void main() {
  test('measurement entry accepts values outside suggested ranges', () {
    final state = BikeOnboardingState()..fork = 'Air';
    addTearDown(state.dispose);
    state.go(2);
    for (final pressure in ['0 psi', '5 psi', '400 psi', '']) {
      state.setting('FrontTire', 'Pressure').text = pressure;
      expect(state.validate(), isTrue);
    }
    state.setting('FrontTire', 'Pressure').text = 'invalid';
    expect(state.validate(), isFalse);
    state.go(state.steps
        .indexOf((kind: OnboardingStepKind.controls, category: 'Fork')));
    state.forkTravel.text = '400';
    expect(state.validate(), isTrue);
    state.forkTravel.text = 'invalid';
    expect(state.validate(), isFalse);
  });
  test('progress stays stable while parts change and reaches completion', () {
    final state = BikeOnboardingState();
    addTearDown(state.dispose);
    final nameProgress = state.progress;
    state.go(1);
    final partsProgress = state.progress;
    for (final enabled in [true, false, true]) {
      state.fork = enabled ? 'Air' : 'None';
      state.shock = enabled ? 'Air' : 'None';
      state.cockpit = enabled;
      state.saddle = enabled;
      state.frame = enabled;
      expect(state.progress, partsProgress);
      state.go(0);
      expect(state.progress, nameProgress);
      state.go(1);
      var previous = state.progress;
      for (var index = 2; index < state.steps.length; index++) {
        state.go(index);
        expect(state.progress, greaterThan(previous));
        expect(state.progress, lessThanOrEqualTo(1));
        previous = state.progress;
      }
      expect(state.progress, closeTo(1, .000001));
      state.go(1);
      expect(state.progress, partsProgress);
    }
  });
  test('rear tire starts with front values and preserves subsequent edits', () {
    final state = BikeOnboardingState();
    addTearDown(state.dispose);
    state.go(2);
    state.setting('FrontTire', 'Pressure').text = '24 psi';
    state.frontWheel = '29';
    state.go(3);
    expect(state.setting('RearTire', 'Pressure').text, '24 psi');
    expect(state.rearWheel, '29');
    state.setting('RearTire', 'Pressure').text = '26 psi';
    state.rearWheel = '27.5';
    state.go(2);
    state.setting('FrontTire', 'Pressure').text = '23 psi';
    state.go(3);
    expect(state.setting('RearTire', 'Pressure').text, '26 psi');
    expect(state.rearWheel, '27.5');
    state.setting('RearTire', 'Pressure').clear();
    state.go(2);
    state.go(3);
    expect(state.setting('RearTire', 'Pressure').text, isEmpty);
  });
  test('tires have separate steps and unknown measurements remain unset', () {
    final state = BikeOnboardingState();
    addTearDown(state.dispose);
    state.name.text = 'Trail bike';
    state.go(2);
    expect(state.currentCategory, 'FrontTire');
    expect(state.setting('FrontTire', 'Pressure').text, isEmpty);
    state.go(3);
    expect(state.currentCategory, 'RearTire');
    expect(state.setting('RearTire', 'Pressure').text, isEmpty);
    state.go(2);
    state.setting('FrontTire', 'Pressure').text = '24 psi';
    state.go(1);
    state.go(2);
    expect(state.setting('FrontTire', 'Pressure').text, '24 psi');
    expect(state.draft.values['RearTire'], isEmpty);
    expect(state.steps.last.kind, OnboardingStepKind.settings);
  });
  test('fork and shock settings stay independent and edits survive navigation',
      () {
    final state = BikeOnboardingState()
      ..fork = 'Air'
      ..shock = 'Air';
    addTearDown(state.dispose);
    void enter(String category, OnboardingStepKind kind) =>
        state.go(state.steps.indexOf((kind: kind, category: category)));
    enter('Fork', OnboardingStepKind.controls);
    expect(state.forkTravel.text, isEmpty);
    enter('Fork', OnboardingStepKind.settings);
    state.setting('Fork', 'Rebound').text = '7 clicks';
    enter('Shock', OnboardingStepKind.settings);
    expect(state.setting('Shock', 'Rebound').text, isEmpty);
    state.setting('Shock', 'Rebound').text = '4 clicks';
    enter('Fork', OnboardingStepKind.settings);
    expect(state.setting('Fork', 'Rebound').text, '7 clicks');
    enter('Shock', OnboardingStepKind.settings);
    expect(state.setting('Shock', 'Rebound').text, '4 clicks');
  });
}
