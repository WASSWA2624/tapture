import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/features/processing/domain/template_detection.dart';

void main() {
  const DetectionProfile pump = (
    templateId: 'pump',
    keywords: <String>['pump', 'flow'],
    negativeKeywords: <String>['cuff'],
    identifierPatterns: <String>[r'SN\d{6}'],
    weight: 1,
  );
  const DetectionProfile bp = (
    templateId: 'bp',
    keywords: <String>['mmhg', 'cuff'],
    negativeKeywords: <String>[],
    identifierPatterns: <String>[r'BP-\d{4}'],
    weight: 1,
  );
  const DetectionProfile generic = (
    templateId: 'generic',
    keywords: <String>['asset'],
    negativeKeywords: <String>[],
    identifierPatterns: <String>[],
    weight: 1,
  );

  DetectionDecision decide({
    String? pinned,
    List<DetectionProfile> templates = const <DetectionProfile>[
      pump,
      bp,
      generic,
    ],
    String text = '',
    String? reference,
  }) {
    return TemplateDetection.decide((
      pinnedTemplateId: pinned,
      templates: templates,
      ocrText: text,
      referenceTemplateId: reference,
      confident: 0.6,
      gap: 0.2,
    ));
  }

  test('a pinned template short-circuits every other rule', () {
    final DetectionDecision decision = decide(
      pinned: 'bp',
      text: 'PUMP FLOW SN458923',
      reference: 'pump',
    );
    expect(decision.templateId, 'bp');
    expect(decision.rule, DetectionRule.pinned);
    expect(decision.callModel, isFalse);
  });

  test('a pin to a template the project no longer has is ignored', () {
    final DetectionDecision decision = decide(
      pinned: 'retired',
      text: 'PUMP FLOW SN458923',
    );
    expect(decision.rule, isNot(DetectionRule.pinned));
  });

  test('the only template is chosen without scoring', () {
    final DetectionDecision decision = decide(
      templates: const <DetectionProfile>[generic],
    );
    expect(decision.templateId, 'generic');
    expect(decision.rule, DetectionRule.onlyTemplate);
  });

  test('a reference match decides before local scoring', () {
    final DetectionDecision decision = decide(
      text: '120 mmHg cuff',
      reference: 'pump',
    );
    expect(decision.templateId, 'pump');
    expect(decision.rule, DetectionRule.reference);
  });

  test('a confident local score decides with no model call', () {
    final DetectionDecision decision = decide(text: 'PUMP FLOW SN458923');
    expect(decision.templateId, 'pump');
    expect(decision.rule, DetectionRule.local);
    expect(decision.callModel, isFalse);
  });

  test('an inconclusive score asks the model about the shortlist only', () {
    final DetectionDecision decision = decide(text: 'pump cuff');
    expect(decision.templateId, isNull);
    expect(decision.rule, DetectionRule.ask);
    expect(decision.callModel, isTrue);
    expect(decision.shortlist, contains('bp'));
    expect(decision.shortlist, isNot(contains('generic')));
  });

  test('no signal at all asks the operator, not the model', () {
    final DetectionDecision decision = decide(text: 'illegible');
    expect(decision.templateId, isNull);
    expect(decision.rule, DetectionRule.ask);
    expect(decision.callModel, isFalse);
    expect(decision.shortlist, isEmpty);
  });

  test('a project with no templates asks', () {
    final DetectionDecision decision = decide(
      templates: const <DetectionProfile>[],
      text: 'PUMP',
    );
    expect(decision.rule, DetectionRule.ask);
    expect(decision.callModel, isFalse);
  });
}
