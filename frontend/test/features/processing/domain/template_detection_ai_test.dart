import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/features/processing/domain/template_detection.dart';
import 'package:tapture/features/processing/domain/template_detection_ai.dart';

void main() {
  test('a local decision makes no model call', () async {
    var calls = 0;
    final String? chosen = await TemplateDetectionAi.choose(
      decision: (
        templateId: 'pump',
        rule: DetectionRule.local,
        callModel: false,
        shortlist: const <String>[],
      ),
      model: (List<String> _) async {
        calls++;
        return 'bp';
      },
    );
    expect(chosen, 'pump');
    expect(calls, 0);
  });

  test('an inconclusive decision asks about the shortlist only', () async {
    final List<List<String>> asked = <List<String>>[];
    final String? chosen = await TemplateDetectionAi.choose(
      decision: (
        templateId: null,
        rule: DetectionRule.ask,
        callModel: true,
        shortlist: const <String>['pump', 'bp'],
      ),
      model: (List<String> shortlist) async {
        asked.add(shortlist);
        return 'bp';
      },
    );
    expect(chosen, 'bp');
    expect(asked, <List<String>>[
      <String>['pump', 'bp'],
    ]);
  });

  test('with nothing to shortlist the model is not asked', () async {
    var calls = 0;
    final String? chosen = await TemplateDetectionAi.choose(
      decision: (
        templateId: null,
        rule: DetectionRule.ask,
        callModel: false,
        shortlist: const <String>[],
      ),
      model: (List<String> _) async {
        calls++;
        return 'bp';
      },
    );
    expect(chosen, isNull);
    expect(calls, 0);
  });
}
