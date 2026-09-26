import 'dart:convert';
import 'dart:ui' show Rect;

import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/ai/ocr_block.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/normalise/choices.dart';
import 'package:tapture/features/processing/data/stage_support.dart';

void main() {
  test('unwrap returns a success and throws the failure otherwise', () {
    expect(StageSupport.unwrap(const Success<int>(3)), 3);
    expect(
      () => StageSupport.unwrap(
        const FailureResult<int>(StorageFailure(message: 'Disk full.')),
      ),
      throwsA(
        isA<StorageFailure>().having(
          (StorageFailure failure) => failure.message,
          'message',
          'Disk full.',
        ),
      ),
    );
  });

  test('malformed stored JSON reads as empty rather than throwing', () {
    expect(StageSupport.json('{'), isNull);
    expect(StageSupport.strings('{"a":1}'), isEmpty);
    expect(StageSupport.strings('["a", 2, "b"]'), <String>['a', 'b']);
    expect(StageSupport.stringMap('[]'), isEmpty);
    expect(StageSupport.stringMap('{"room":"A","floor":2}'), <String, String>{
      'room': 'A',
    });
  });

  test('options read as labels, and as label, code and alias values', () {
    const String raw =
        '["Working", {"label": "Faulty", "code": "F",'
        ' "aliases": ["Broken", 3]}, {"code": "X"}]';

    expect(StageSupport.optionLabels(raw), <String>['Working', 'Faulty']);
    expect(StageSupport.optionValues(raw), <String>[
      'Working',
      'Faulty',
      'F',
      'Broken',
    ]);
    final ChoiceOption faulty = StageSupport.choiceOptions(raw).last;
    expect(faulty.label, 'Faulty');
    expect(faulty.code, 'F');
    expect(faulty.aliases, <String>['Broken']);
    expect(StageSupport.optionLabels('not json'), isEmpty);
  });

  test('a request summary is read by key and tolerates any shape', () {
    const String summary = '{"provider":"backend","model":"","repair":true}';

    expect(StageSupport.summaryValue(summary, 'provider'), 'backend');
    expect(StageSupport.summaryValue(summary, 'model'), isNull);
    expect(StageSupport.summaryValue('[]', 'provider'), isNull);
    expect(StageSupport.summaryBool(summary, 'repair'), isTrue);
    expect(StageSupport.summaryBool(summary, 'provider'), isFalse);
  });

  test('a manual source, a basename and a block region are recognised', () {
    expect(StageSupport.isManual('Typed'), isTrue);
    expect(StageSupport.isManual('manual'), isTrue);
    expect(StageSupport.isManual('ocr'), isFalse);
    expect(StageSupport.isManual(null), isFalse);
    expect(StageSupport.basename(r'C:\photos\a\img-0.jpg'), 'img-0.jpg');
    expect(StageSupport.basename('photos/a/img-0.jpg'), 'img-0.jpg');
    expect(
      jsonDecode(
        StageSupport.region(
          const OcrBlock(
            text: 'SN1',
            bounds: Rect.fromLTRB(1, 2, 3, 4),
            confidence: 0.9,
          ),
        ),
      ),
      <String, double>{'left': 1, 'top': 2, 'right': 3, 'bottom': 4},
    );
  });
}
