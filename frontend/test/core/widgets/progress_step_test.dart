import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/widgets/app_progress_steps.dart';

void main() {
  test('ProgressStep carries label, state and optional detail', () {
    const ProgressStep plain = ProgressStep(
      label: 'Read text',
      state: StepState.waiting,
    );
    const ProgressStep detailed = ProgressStep(
      label: 'Write values',
      state: StepState.failed,
      detail: 'The file could not be read.',
    );

    expect(plain.label, 'Read text');
    expect(plain.state, StepState.waiting);
    expect(plain.detail, isNull);
    expect(detailed.detail, 'The file could not be read.');
    expect(plain, isNot(detailed));
    expect(
      plain,
      const ProgressStep(label: 'Read text', state: StepState.waiting),
    );
  });
}
