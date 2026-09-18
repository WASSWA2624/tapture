import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/widgets/fields/dictation_phase.dart';

void main() {
  test(
    'a listen moves from idle through starting and listening to finishing',
    () {
      expect(DictationPhase.values, <DictationPhase>[
        DictationPhase.idle,
        DictationPhase.starting,
        DictationPhase.listening,
        DictationPhase.finishing,
      ]);
    },
  );
}
