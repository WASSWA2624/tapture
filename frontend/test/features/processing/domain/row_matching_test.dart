import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/features/processing/domain/row_matching.dart';

void main() {
  const List<MatchableRow> rows = <MatchableRow>[
    (
      id: 'bpm',
      label: 'Blood Pressure Machine',
      aliases: <String>['Sphygmomanometer', 'BP machine'],
    ),
    (id: 'pump', label: 'Water Pump', aliases: <String>[]),
    (id: 'ecg', label: 'ECG Monitor', aliases: <String>[]),
  ];

  Future<({RowMatch? match, int modelCalls})> run(
    String query, {
    RowMatch? model,
    double threshold = 0.85,
  }) async {
    var calls = 0;
    final RowMatch? match = await RowMatching.match(
      query: query,
      rows: rows,
      threshold: threshold,
      classify: (String _, List<MatchableRow> _) async {
        calls++;
        return model;
      },
    );
    return (match: match, modelCalls: calls);
  }

  test('exact comes first', () async {
    final result = await run('Water Pump');
    expect(result.match?.id, 'pump');
    expect(result.match?.strategy, 'exact');
    expect(result.match?.score, 1.0);
    expect(result.modelCalls, 0);
  });

  test('Sphygmomanometer reaches Blood Pressure Machine by alias', () async {
    final result = await run('sphygmomanometer');
    expect(result.match?.label, 'Blood Pressure Machine');
    expect(result.match?.strategy, 'alias');
    expect(result.modelCalls, 0);
  });

  test('normalised text matches before fuzzy', () async {
    final result = await run('water-pump!');
    expect(result.match?.id, 'pump');
    expect(result.match?.strategy, 'normalised');
  });

  test('a near spelling matches fuzzily with its score', () async {
    final result = await run('Watter Pump');
    expect(result.match?.id, 'pump');
    expect(result.match?.strategy, 'fuzzy');
    expect(result.match!.score, greaterThanOrEqualTo(0.85));
    expect(result.modelCalls, 0);
  });

  test('the model runs only after all four local strategies fail', () async {
    final result = await run(
      'cardiograph',
      model: (id: 'ecg', label: 'ECG Monitor', strategy: 'x', score: 0.9),
    );
    expect(result.modelCalls, 1);
    expect(result.match?.id, 'ecg');
    expect(result.match?.strategy, 'model');
  });

  test('a weak match of any strategy becomes no match', () async {
    final result = await run(
      'cardiograph',
      model: (id: 'ecg', label: 'ECG Monitor', strategy: 'x', score: 0.4),
    );
    expect(result.match, isNull);

    final noModel = await RowMatching.match(query: 'cardiograph', rows: rows);
    expect(noModel, isNull);
  });

  test('a threshold above a strategy score hands over to the next', () async {
    final result = await run('BP machine', threshold: 0.99);
    expect(result.match?.strategy, isNot('alias'));
  });

  test('an empty query or empty list matches nothing', () async {
    expect(await RowMatching.match(query: '  ', rows: rows), isNull);
    expect(
      await RowMatching.match(query: 'pump', rows: const <MatchableRow>[]),
      isNull,
    );
  });
}
