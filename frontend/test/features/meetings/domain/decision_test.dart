import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/features/meetings/domain/decision.dart';

void main() {
  test('editing a decision leaves its source', () {
    const Decision decision = Decision(
      id: 'd1',
      text: 'Adopt the plan',
      source: 'Adopt the plan',
    );
    expect(decision.copyWith(text: 'Adopt it').source, decision.source);
  });
}
