import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/features/quality/quality.dart';

void main() {
  test('a pair names the incoming record, the local one, why and how '
      'strongly', () {
    const PossibleDuplicate pair = PossibleDuplicate(
      incomingId: 'in',
      localId: 'here',
      signal: DuplicateSignal.caption,
      score: 0.93,
    );
    expect(pair.incomingId, 'in');
    expect(pair.localId, 'here');
    expect(pair.signal, DuplicateSignal.caption);
    expect(pair.score, closeTo(0.93, 1e-9));
  });
}
