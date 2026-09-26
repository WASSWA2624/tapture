import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/features/processing/domain/caption_refinement.dart';

void main() {
  const String raw = 'pump sn458923 leaking at 240 v, fitted 12/03/2021';

  test('a rewording that keeps every fact is accepted', () {
    final CaptionOutcome outcome = CaptionRefinement.refine(
      raw: raw,
      proposed: 'Pump SN458923 is leaking at 240 V. Fitted 12/03/2021.',
    );
    expect(outcome.accepted, isTrue);
    expect(outcome.refined, startsWith('Pump SN458923'));
  });

  test('a new identifier is rejected', () {
    final CaptionOutcome outcome = CaptionRefinement.refine(
      raw: raw,
      proposed: 'Pump SN458924 is leaking at 240 V. Fitted 12/03/2021.',
    );
    expect(outcome.accepted, isFalse);
    expect(outcome.refined, isNull);
  });

  test('a new quantity in any unit is rejected', () {
    for (final String added in <String>[
      'Pump SN458923 leaking at 240 V and 5 bar.',
      'Pump SN458923 leaking at 240 V, 3 litres lost.',
      'Two of 4 pumps leaking at 240 V.',
    ]) {
      final CaptionOutcome outcome = CaptionRefinement.refine(
        raw: raw,
        proposed: added,
      );
      expect(outcome.accepted, isFalse, reason: added);
      expect(outcome.reason, contains('number'));
    }
  });

  test('a new date is rejected', () {
    final CaptionOutcome outcome = CaptionRefinement.refine(
      raw: 'pump leaking',
      proposed: 'Pump leaking since March.',
    );
    expect(outcome.accepted, isFalse);
    expect(outcome.reason, contains('date'));
  });

  test('an empty refinement is rejected', () {
    expect(
      CaptionRefinement.refine(raw: raw, proposed: '  ').accepted,
      isFalse,
    );
  });
}
