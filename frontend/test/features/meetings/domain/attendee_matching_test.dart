import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/features/meetings/domain/attendee_matching.dart';

void main() {
  const List<StaffCandidate> staff = <StaffCandidate>[
    (id: 's1', name: 'Ada Lovelace', aliases: <String>['A. Lovelace']),
  ];

  test('an exact name is offered at the top score', () {
    final StaffSuggestion? match = AttendeeMatching.suggest(
      name: 'Ada Lovelace',
      staff: staff,
    );
    expect(match?.staffId, 's1');
    expect(match?.score, 1);
  });

  test('a near name above the threshold is offered and not linked', () {
    final StaffSuggestion? match = AttendeeMatching.suggest(
      name: 'Ada Lovlace',
      staff: staff,
    );
    expect(match?.staffId, 's1');
    expect(
      match!.score,
      greaterThanOrEqualTo(AppConstants.processing.fuzzyMatch),
    );
  });

  test('a score under the threshold offers nothing', () {
    expect(
      AttendeeMatching.suggest(
        name: 'Ada Lovlace',
        staff: staff,
        threshold: 0.99,
      ),
      isNull,
    );
    expect(
      AttendeeMatching.suggest(name: 'Grace Hopper', staff: staff),
      isNull,
    );
  });
}
