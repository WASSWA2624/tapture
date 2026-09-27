import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/features/merge/domain/merge_apply.dart';

void main() {
  test('a failure restores the snapshot', () {
    const MergeApply apply = MergeApply();
    const Map<String, String> before = <String, String>{'row': 'old'};
    final ApplyOutcome failed = apply.run(
      before: before,
      steps: const <String>['a', 'b'],
      failAt: 1,
    );
    expect(failed.applied, isFalse);
    expect(failed.state, before);
    final ApplyOutcome done = apply.run(
      before: before,
      steps: const <String>['a'],
    );
    expect(done.applied, isTrue);
    expect(done.mergeId, 'merge-1');
  });
}
