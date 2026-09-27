import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/features/quality/quality.dart';

void main() {
  test('signals list strongest first, and each reads as its own words', () {
    expect(DuplicateSignal.values, <DuplicateSignal>[
      DuplicateSignal.identity,
      DuplicateSignal.photo,
      DuplicateSignal.caption,
      DuplicateSignal.samePhoto,
      DuplicateSignal.nearPhoto,
      DuplicateSignal.predefinedRow,
      DuplicateSignal.nameContextTime,
    ]);
    expect(<String>{
      for (final DuplicateSignal signal in DuplicateSignal.values)
        Copy.duplicateSignal(signal.name),
    }, hasLength(DuplicateSignal.values.length));
  });
}
