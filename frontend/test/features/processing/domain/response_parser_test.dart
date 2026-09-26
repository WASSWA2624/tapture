import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/features/processing/domain/response_parser.dart';

void main() {
  const List<FieldSchema> schema = <FieldSchema>[
    (
      key: 'serial',
      type: 'identifier',
      requiredField: true,
      pattern: null,
      options: <String>[],
    ),
    (
      key: 'count',
      type: 'number',
      requiredField: false,
      pattern: null,
      options: <String>[],
    ),
    (
      key: 'working',
      type: 'boolean',
      requiredField: false,
      pattern: null,
      options: <String>[],
    ),
  ];

  test('a valid response keeps values, scores and evidence', () {
    final ParseOutcome outcome = ResponseParser.parse(
      '{"fields":{"serial":{"value":"0042","confidence":0.9,'
      '"evidence":["photo-1"]},"count":{"value":"3","confidence":0.7}},'
      '"matched_row":"Water pump"}',
      schema: schema,
    );
    expect(outcome.ok, isTrue);
    expect(
      outcome.fields['serial']?.value,
      '0042',
      reason: 'an identifier keeps its leading zeros',
    );
    expect(outcome.fields['serial']?.evidence, <String>['photo-1']);
    expect(outcome.fields['count']?.value, '3');
    expect(outcome.matchedRow, 'Water pump');
  });

  test('a partial response keeps what it has and leaves the rest', () {
    final ParseOutcome outcome = ResponseParser.parse(
      '{"fields":{"serial":{"value":null,"confidence":0}}}',
      schema: schema,
    );
    expect(outcome.ok, isTrue);
    expect(outcome.fields['serial']?.value, isNull);
    expect(outcome.fields.containsKey('count'), isFalse);
  });

  test('unknown keys are dropped', () {
    final ParseOutcome outcome = ResponseParser.parse(
      '{"fields":{"serial":{"value":"SN1","confidence":0.9},'
      '"__proto__":{"value":"x"},"price":{"value":"9"}}}',
      schema: schema,
    );
    expect(outcome.fields.keys, <String>['serial']);
  });

  test('a bare value is never trusted above review', () {
    final ParseOutcome outcome = ResponseParser.parse(
      '{"fields":{"serial":"SN1"}}',
      schema: schema,
    );
    expect(outcome.fields['serial']?.value, 'SN1');
    expect(outcome.fields['serial']?.confidence, 0);
    expect(outcome.fields['serial']?.evidence, isEmpty);
  });

  test('types are coerced only when that is safe', () {
    final ParseOutcome ok = ResponseParser.parse(
      '{"fields":{"count":{"value":4,"confidence":0.8},'
      '"working":{"value":"TRUE","confidence":0.8}}}',
      schema: schema,
    );
    expect(ok.fields['count']?.value, '4');
    expect(ok.fields['working']?.value, 'true');

    for (final String hostile in <String>[
      '{"fields":{"count":{"value":"four","confidence":0.8}}}',
      '{"fields":{"count":{"value":2.5,"confidence":0.8}}}',
      '{"fields":{"working":{"value":"maybe","confidence":0.8}}}',
    ]) {
      expect(
        ResponseParser.parse(hostile, schema: schema).ok,
        isFalse,
        reason: hostile,
      );
    }
  });

  test('hostile shapes are rejected rather than guessed at', () {
    for (final String hostile in <String>[
      '{"fields":{"serial":{"value":{"nested":1},"confidence":0.9}}}',
      '{"fields":{"serial":{"value":"SN1","confidence":7}}}',
      '{"fields":{"serial":{"value":"SN1","confidence":"high"}}}',
      '{"fields":{"serial":{"value":"SN1","evidence":"photo-1"}}}',
      '{"fields":{"serial":{"confidence":0.9}}}',
      '{"fields":{"serial":["SN1"]}}',
      '{"fields":[]}',
      '[]',
    ]) {
      expect(
        ResponseParser.parse(hostile, schema: schema).ok,
        isFalse,
        reason: hostile,
      );
    }
  });

  test('text that is not JSON does not parse', () {
    final ParseOutcome outcome = ResponseParser.parse(
      'Sure! Here is the data: serial SN1',
      schema: schema,
    );
    expect(outcome.ok, isFalse);
    expect(outcome.error, isNotNull);
    expect(outcome.fields, isEmpty);
  });
}
