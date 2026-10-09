import 'dart:convert';
import 'dart:ui' show Rect;

import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/ai/ocr_block.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/normalise/choices.dart';
import 'package:tapture/features/processing/data/stage_support.dart';

import '../../../support/processing_fixture.dart';

void main() {
  test(
    'stored source flags and malformed metadata cannot become targets',
    () async {
      final ProcessingFixture fixture = await ProcessingFixture.open();
      final List<TemplateField> protected = <TemplateField>[
        await fixture.addField('automatic', inputMode: 'AUTO'),
        await fixture.addField('manual', inputMode: 'MANUAL_ONLY'),
        await fixture.addField('legacy_flag', autoFill: true),
        await fixture.addField(
          'unknown_source',
          validation: '{"_tapture":{"autoFill":"FUTURE_SOURCE"}}',
        ),
        await fixture.addField(
          'invalid_source',
          validation: '{"_tapture":{"autoFill":{"bad":true}}}',
        ),
        await fixture.addField(
          'hidden',
          validation: '{"_tapture":{"hidden":true}}',
        ),
        await fixture.addField('hierarchy', contextLevel: 1),
        await fixture.addField('computed', type: 'computed'),
        await fixture.addField('consent', type: 'consent'),
        (await fixture.addField('malformed')).copyWith(validation: '{'),
      ];
      for (final TemplateField field in protected) {
        expect(StageSupport.canExtract(field), isFalse, reason: field.fieldKey);
      }
      final TemplateField ordinary = await fixture.addField(
        'ordinary',
        inputMode: 'AI_ALLOWED',
        stickable: true,
      );
      expect(StageSupport.canExtract(ordinary), isTrue);
      expect(
        StageSupport.schema(<TemplateField>[
          ...protected,
          ordinary,
        ]).map((field) => field.key),
        <String>['ordinary'],
      );
    },
  );

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
