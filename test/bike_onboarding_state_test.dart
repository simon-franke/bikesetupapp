import 'package:flutter_test/flutter_test.dart';
import 'package:bikesetupapp/features/bikes/ui/bike_onboarding_state.dart';

void main() {
  test('typed steps initialize defaults once and retain cleared fields', () {
    final state = BikeOnboardingState();
    addTearDown(state.dispose);
    state.name.text = 'Trail bike';
    state.go(2);
    expect(state.currentStep,
        (kind: OnboardingStepKind.settings, category: 'FrontTire'));
    expect(state.setting('FrontTire', 'Pressure').text, isNotEmpty);
    state.setting('FrontTire', 'Pressure').clear();
    state.go(1);
    state.go(2);
    expect(state.setting('FrontTire', 'Pressure').text, isEmpty);
    expect(state.draft.values['FrontTire'], isEmpty);
  });

  test('shock seeding copies adjusters but keeps spring pressure independent',
      () {
    final state = BikeOnboardingState();
    addTearDown(state.dispose);
    state.name.text = 'Trail bike';
    state.fork = 'Air';
    state.shock = 'Air';
    state.forkAdjusters
      ..clear()
      ..add('Rebound');
    void enter(String category, OnboardingStepKind kind) {
      state.go(state.steps.indexOf((kind: kind, category: category)));
    }

    enter('Fork', OnboardingStepKind.controls);
    expect(state.forkTravel.text, '150');
    enter('Fork', OnboardingStepKind.settings);
    state.setting('Fork', 'Rebound').text = '7 clicks';
    state.setting('Fork', 'Pressure').text = '90 psi';
    enter('Shock', OnboardingStepKind.controls);
    expect(state.shockAdjusters, {'Rebound'});
    enter('Shock', OnboardingStepKind.settings);
    expect(state.setting('Shock', 'Rebound').text, '7 clicks');
    expect(state.setting('Shock', 'Pressure').text, isNot('90 psi'));
    state.setting('Shock', 'Rebound').text = '4 clicks';
    enter('Shock', OnboardingStepKind.controls);
    enter('Shock', OnboardingStepKind.settings);
    expect(state.setting('Shock', 'Rebound').text, '4 clicks');
  });
}
