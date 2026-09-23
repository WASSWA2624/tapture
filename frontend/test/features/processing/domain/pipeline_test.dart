import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/ai/ai_service.dart';
import 'package:tapture/core/ai/provider_registry.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/network/connectivity_service.dart';
import 'package:tapture/core/normalise/choices.dart';
import 'package:tapture/core/normalise/dates.dart';
import 'package:tapture/core/normalise/units.dart';
import 'package:tapture/features/processing/domain/auto_process.dart';
import 'package:tapture/features/processing/domain/background_ocr.dart';
import 'package:tapture/features/processing/domain/caption_refinement.dart';
import 'package:tapture/features/processing/domain/confidence.dart';
import 'package:tapture/features/processing/domain/cost_guard.dart';
import 'package:tapture/features/processing/domain/evidence_linking.dart';
import 'package:tapture/features/processing/domain/extraction_request.dart';
import 'package:tapture/features/processing/domain/identifier_extraction.dart';
import 'package:tapture/features/processing/domain/no_invention_guard.dart';
import 'package:tapture/features/processing/domain/online_skip_rule.dart';
import 'package:tapture/features/processing/domain/proposal_application.dart';
import 'package:tapture/features/processing/domain/provenance.dart';
import 'package:tapture/features/processing/domain/request_batching.dart';
import 'package:tapture/features/processing/domain/response_parser.dart';
import 'package:tapture/features/processing/domain/response_repair.dart';
import 'package:tapture/features/processing/domain/row_matching.dart';
import 'package:tapture/features/processing/domain/template_detection.dart';
import 'package:tapture/features/processing/domain/template_detection_ai.dart';

void main() {
  test('identifier extraction ranks one, several and none', () {
    const List<IdentityField> fields = <IdentityField>[
      (fieldKey: 'serial', pattern: r'SN[0-9A-Z]{6,}'),
      (fieldKey: 'asset', pattern: r'AST-\d{5}'),
    ];
    final List<IdentifierCandidate> one = IdentifierExtraction.extract(
      text: 'ABC MEDICAL SN458923',
      blocks: const <PlateBlock>[(text: 'SN458923', top: 10, confidence: 0.9)],
      fields: fields,
    );
    expect(one, hasLength(1));
    expect(one.first.value, 'SN458923');
    expect(one.first.blockText, 'SN458923');

    final List<IdentifierCandidate> several = IdentifierExtraction.extract(
      text: 'SN458923 AST-00123',
      blocks: const <PlateBlock>[
        (text: 'AST-00123', top: 80, confidence: 0.4),
        (text: 'SN458923', top: 4, confidence: 0.95),
      ],
      fields: fields,
    );
    expect(several.first.value, 'SN458923');
    expect(several, hasLength(2));

    expect(
      IdentifierExtraction.extract(
        text: 'no plate',
        blocks: const <PlateBlock>[],
        fields: fields,
      ),
      isEmpty,
    );
  });

  test('registry selection is per project and the proxy holds no key', () {
    final _Scripted proxy = _Scripted(
      const Success<ReadTextResult>(ReadTextResult(text: '')),
    );
    final _Scripted device = _Scripted(
      const FailureResult<ReadTextResult>(
        ProviderFailure(message: '401 authentication failed'),
      ),
    );
    final ProviderRegistry registry = ProviderRegistry(
      entries: <String, RegistryEntry>{
        ProviderRegistry.backendId: (
          id: ProviderRegistry.backendId,
          keyHeldByBackend: true,
          service: proxy,
        ),
        'device': (id: 'device', keyHeldByBackend: false, service: device),
      },
      selection: <String, Map<AiOperation, String>>{
        'project-a': <AiOperation, String>{
          AiOperation.extractFields: 'device',
          AiOperation.readText: ProviderRegistry.backendId,
        },
      },
    );
    expect(
      identical(
        registry.resolve(
          projectId: 'project-a',
          operation: AiOperation.extractFields,
        ),
        device,
      ),
      isTrue,
    );
    expect(
      identical(
        registry.resolve(
          projectId: 'project-a',
          operation: AiOperation.readText,
        ),
        proxy,
      ),
      isTrue,
    );
    expect(registry.keyHeldByBackend(ProviderRegistry.backendId), isTrue);
    expect(
      registry.resolve(projectId: 'other', operation: AiOperation.refineText),
      same(proxy),
    );
  });

  test('batching stays one call below and at the cap and splits above it', () {
    final int cap = AppConstants.processing.extractionImageCap;
    expect(RequestBatching.split(const <String>[]), <List<String>>[
      <String>[],
    ]);
    final List<String> five = <String>['a', 'b', 'c', 'd', 'e'];
    expect(RequestBatching.split(five), hasLength(1));
    expect(
      RequestBatching.split(List<String>.generate(cap, (int i) => '$i')),
      hasLength(1),
    );
    final List<List<String>> over = RequestBatching.split(
      List<String>.generate(cap + 1, (int i) => '$i'),
    );
    expect(over, hasLength(2));
    expect(over.first, hasLength(cap));
    expect(over.last, <String>['$cap']);
  });

  test('the extraction request matches the specification shape', () {
    const ExtractionRequest request = ExtractionRequest(
      template: 'Medical Equipment',
      fields: <ExtractionField>[
        (
          key: 'equipment_name',
          type: 'text',
          requiredField: true,
          pattern: null,
          options: null,
          optionsHint: null,
        ),
        (
          key: 'serial_number',
          type: 'text',
          requiredField: false,
          pattern: r'^SN[0-9A-Z]{6,}$',
          options: null,
          optionsHint: null,
        ),
      ],
      context: <String, String>{
        'district': 'Kampala',
        'facility': 'Kasubi HC IV',
      },
      predefinedRows: <String>['Autoclave'],
      caption: '13 litre autoclave',
      ocrText: 'SN458923',
      images: <String>['<image 1>'],
    );
    final Map<String, Object?> json = request.toJson();
    expect(json['template'], 'Medical Equipment');
    expect(json['rules'], ExtractionRequest.defaultRules);
    expect(json['ocr_text'], 'SN458923');
    expect(json['images'], <String>['<image 1>']);
    expect(
      (json['fields']! as List<Object?>).first,
      containsPair('key', 'equipment_name'),
    );
    expect(request.toService().imagePaths, <String>['<image 1>']);
    expect(request.toService().ocrText, 'SN458923');
    expect(request.toService().predefinedRows, <String>['Autoclave']);
    expect(request.toService().rules, ExtractionRequest.defaultRules);
    expect(
      request.toService().fieldSchema.first,
      containsPair('required', true),
    );
  });

  test('parser keeps a valid field, drops unknown keys, and repairs once', () {
    const String raw = '''
{"fields":{"serial_number":{"value":"SN458923","confidence":0.98,"evidence":["image_2:ocr"]},"injected":{"value":"no"}}}
''';
    final ParseOutcome parsed = ResponseParser.parse(
      raw,
      schema: const <FieldSchema>[
        (
          key: 'serial_number',
          type: 'text',
          requiredField: true,
          pattern: null,
          options: <String>[],
        ),
      ],
    );
    expect(parsed.ok, isTrue);
    expect(parsed.fields.keys, <String>['serial_number']);
    expect(parsed.fields['serial_number']?.value, 'SN458923');

    final ParseOutcome hostile = ResponseParser.parse(
      '{"fields":{"serial_number":{"notValue":1}}}',
      schema: const <FieldSchema>[
        (
          key: 'serial_number',
          type: 'text',
          requiredField: true,
          pattern: null,
          options: <String>[],
        ),
      ],
    );
    expect(hostile.ok, isFalse);

    expect(ResponseRepair.mayRetry(repairsUsed: 0), isTrue);
    expect(ResponseRepair.mayRetry(repairsUsed: 1), isFalse);
    expect(
      ResponseRepair.followUp(parseError: hostile.error!),
      containsPair('parse_error', hostile.error),
    );
  });

  test('verified and manual values stay, and review forces needs review', () {
    final ProvenanceStamp stamp = Provenance.stamp(
      source: 'AI_VISION',
      method: 'extract',
      provider: 'backend',
      model: 'proxy',
      promptVersion: '1',
    );
    final List<EvidenceDraft> evidence = EvidenceLinking.forValue(
      photoId: 'photo-1',
      regionJson: '{"left":1,"top":2,"right":3,"bottom":4}',
      confidence: 0.4,
    );
    expect(evidence, isNotEmpty);
    expect(Provenance.asAudit(stamp)['model'], 'proxy');

    final ApplicationPlan plan = ProposalApplication.apply(
      proposals: <ProposedValue>[
        (
          fieldKey: 'serial',
          value: 'SN1',
          confidence: 0.99,
          evidence: evidence,
          provenance: stamp,
        ),
        (
          fieldKey: 'condition',
          value: 'Faulty',
          confidence: 0.4,
          evidence: EvidenceLinking.forValue(photoId: 'photo-1'),
          provenance: stamp,
        ),
      ],
      existing: const <ExistingValue>[
        (
          fieldKey: 'serial',
          capturedValue: 'kept',
          verified: true,
          source: 'MANUAL',
        ),
      ],
      high: 0.85,
      medium: 0.6,
      requiredKeys: const <String>['serial', 'year'],
    );
    expect(plan.skips, isNotEmpty);
    expect(plan.writes.map((ProposalWrite write) => write.fieldKey), <String>[
      'condition',
    ]);
    expect(plan.needsReview, isTrue);
    expect(plan.status, ProposalApplication.needsReviewStatus);
    expect(
      Confidence.band(score: 0.4, high: 0.85, medium: 0.6),
      ConfidenceBand.reviewRequired,
    );
    expect(
      Confidence.band(score: 0.9, high: 0.85, medium: 0.6),
      ConfidenceBand.high,
    );
  });

  test('a pinned template never asks the model', () async {
    var calls = 0;
    final DetectionDecision pinned = TemplateDetection.decide((
      pinnedTemplateId: 'equipment',
      templates: const <DetectionProfile>[
        (
          templateId: 'equipment',
          keywords: <String>['serial'],
          negativeKeywords: <String>[],
          identifierPatterns: <String>[],
          weight: 1,
        ),
        (
          templateId: 'building',
          keywords: <String>['wall'],
          negativeKeywords: <String>[],
          identifierPatterns: <String>[],
          weight: 1,
        ),
      ],
      ocrText: 'wall',
      referenceTemplateId: 'building',
      confident: null,
      gap: null,
    ));
    expect(pinned.rule, DetectionRule.pinned);
    expect(pinned.callModel, isFalse);
    final String? chosen = await TemplateDetectionAi.choose(
      decision: pinned,
      model: (List<String> shortlist) async {
        calls++;
        return shortlist.first;
      },
    );
    expect(chosen, 'equipment');
    expect(calls, 0);
  });

  test('units, choices and dates follow the specification examples', () {
    expect(Units.convert('13 litre', targetUnit: 'L')?.stored, '13 L');
    expect(Units.convert('13L', targetUnit: 'L')?.stored, '13 L');
    expect(
      Units.convert('13 Litre Capacity', targetUnit: 'L')?.original,
      '13 Litre Capacity',
    );
    expect(Units.convert('220v', targetUnit: 'V')?.stored, '220 V');

    const List<ChoiceOption> options = <ChoiceOption>[
      (
        label: 'Faulty',
        code: 'F',
        aliases: <String>['damaged', 'requires repair'],
      ),
      (
        label: 'Not Working',
        code: null,
        aliases: <String>['not working', "doesn't work", 'dead'],
      ),
    ];
    final ChoiceMatch? faulty = Choices.match(
      'Gauge damaged and requires repair',
      options: options,
    );
    expect(faulty?.label, 'Faulty');
    expect(faulty?.original, 'Gauge damaged and requires repair');
    expect(Choices.match('dead', options: options)?.label, 'Not Working');
    expect(Choices.match('painted blue', options: options), isNull);

    expect(Dates.parse('08/09/26', locale: 'en')?.stored, '2026-09-08');
    expect(Dates.parse('8 Sept 2026', locale: 'en')?.stored, '2026-09-08');
    expect(Dates.parse('01/02/03', locale: 'en')?.ambiguous, isTrue);
    expect(Dates.wholeNumber('00123'), '00123');
    expect(Dates.wholeNumber('AST-00123'), isNull);
  });

  test('row matching walks the strategies and refuses a weak match', () async {
    const List<MatchableRow> rows = <MatchableRow>[
      (
        id: 'bp',
        label: 'Blood Pressure Machine',
        aliases: <String>['sphygmomanometer', 'BP machine'],
      ),
    ];
    var modelCalls = 0;
    final RowMatch? alias = await RowMatching.match(
      query: 'Sphygmomanometer',
      rows: rows,
      classify: (String query, List<MatchableRow> rows) async {
        modelCalls++;
        return null;
      },
    );
    expect(alias?.strategy, 'alias');
    expect(alias?.label, 'Blood Pressure Machine');
    expect(modelCalls, 0);

    final RowMatch? exact = await RowMatching.match(
      query: 'Blood Pressure Machine',
      rows: rows,
    );
    expect(exact?.strategy, 'exact');

    final RowMatch? none = await RowMatching.match(
      query: 'completely different object',
      rows: rows,
      threshold: 0.99,
      classify: (String query, List<MatchableRow> rows) async {
        return (
          id: 'bp',
          label: 'Blood Pressure Machine',
          strategy: 'model',
          score: 0.2,
        );
      },
    );
    expect(none, isNull);
  });

  test('refinement keeps the raw meaning and rejects a new fact', () {
    final CaptionOutcome kept = CaptionRefinement.refine(
      raw: 'the pressure gauge is broken I think',
      proposed: 'Pressure gauge appears faulty.',
    );
    expect(kept.accepted, isTrue);
    expect(kept.refined, isNot(contains('2019')));
    final CaptionOutcome rejected = CaptionRefinement.refine(
      raw: 'the pressure gauge is broken I think',
      proposed: 'Pressure gauge faulty. Purchased 2019. SN999999.',
    );
    expect(rejected.accepted, isFalse);
    expect(rejected.reason, isNotNull);
  });

  test('the guard records why a fabricated value was dropped', () {
    final GuardOutcome empty = NoInventionGuard.check(
      fieldKey: 'purchase_year',
      value: '2019',
      evidence: const <String>[],
      evidenceRequired: true,
    );
    expect(empty.value, isNull);
    expect(empty.rejection?.reason, contains('evidence'));

    final GuardOutcome pattern = NoInventionGuard.check(
      fieldKey: 'serial_number',
      value: 'not-a-serial',
      evidence: const <String>['ocr'],
      evidenceRequired: true,
      pattern: r'^SN[0-9A-Z]{6,}$',
    );
    expect(pattern.rejection?.reason, contains('pattern'));

    final GuardOutcome option = NoInventionGuard.check(
      fieldKey: 'condition',
      value: 'Painted',
      evidence: const <String>['caption'],
      evidenceRequired: false,
      options: const <String>['Good', 'Faulty'],
    );
    expect(option.rejection?.reason, contains('options'));
  });

  test(
    'a full local match skips online work and the cap blocks at the limit',
    () {
      expect(
        OnlineSkipRule.reason(const <SkipField>[
          (requiredField: true, value: 'Autoclave', band: ConfidenceBand.high),
        ]),
        isNotNull,
      );
      expect(
        OnlineSkipRule.reason(const <SkipField>[
          (requiredField: true, value: null, band: null),
        ]),
        isNull,
      );

      final DateTime now = DateTime.utc(2026, 9, 23, 15);
      final CostGuard under = CostGuard(
        requestsToday: 1,
        imagesToday: 2,
        requestCap: 2,
        now: now,
      );
      expect(under.isBlocked, isFalse);
      final CostGuard atLimit = under.record(images: 1);
      expect(atLimit.requestsToday, 2);
      expect(atLimit.isBlocked, isTrue);
      expect(atLimit.blockMessage, contains('2'));
      expect(
        atLimit.blockMessage,
        contains(atLimit.resetsAt.toIso8601String()),
      );
      final CostGuard over = CostGuard(
        requestsToday: 3,
        imagesToday: 4,
        requestCap: 2,
        now: now,
      );
      expect(over.isBlocked, isTrue);
    },
  );

  test(
    'auto process honours wifi-only and the cap, and OCR stops on resume',
    () {
      expect(
        AutoProcess.shouldStart(
          enabled: false,
          wifiOnly: true,
          previous: NetworkState.offline,
          next: NetworkState.online,
          foreground: false,
          underCap: true,
        ),
        isFalse,
      );
      expect(
        AutoProcess.shouldStart(
          enabled: true,
          wifiOnly: true,
          previous: NetworkState.offline,
          next: NetworkState.metered,
          foreground: false,
          underCap: true,
        ),
        isFalse,
      );
      expect(
        AutoProcess.shouldStart(
          enabled: true,
          wifiOnly: true,
          previous: NetworkState.offline,
          next: NetworkState.online,
          foreground: false,
          underCap: false,
        ),
        isFalse,
      );
      expect(
        AutoProcess.shouldStart(
          enabled: true,
          wifiOnly: true,
          previous: NetworkState.offline,
          next: NetworkState.online,
          foreground: false,
          underCap: true,
        ),
        isTrue,
      );
      expect(
        BackgroundOcr.shouldRun(
          enabled: true,
          charging: true,
          idle: true,
          foreground: false,
        ),
        isTrue,
      );
      expect(
        BackgroundOcr.shouldRun(
          enabled: true,
          charging: true,
          idle: true,
          foreground: true,
        ),
        isFalse,
      );
      expect(
        BackgroundOcr.shouldRun(
          enabled: false,
          charging: true,
          idle: true,
          foreground: false,
        ),
        isFalse,
      );
    },
  );
}

final class _Scripted implements AiService {
  _Scripted(this.result);

  final Result<ReadTextResult> result;

  @override
  bool get isAvailable => true;

  @override
  Future<Result<ReadTextResult>> readText(ReadTextRequest request) async {
    return result;
  }

  @override
  Future<Result<ExtractFieldsResult>> extractFields(
    ExtractFieldsRequest request,
  ) async {
    return const FailureResult<ExtractFieldsResult>(ProviderFailure());
  }

  @override
  Future<Result<RefineTextResult>> refineText(RefineTextRequest request) async {
    return const FailureResult<RefineTextResult>(ProviderFailure());
  }

  @override
  Future<Result<TranscribeResult>> transcribe(TranscribeRequest request) async {
    return const FailureResult<TranscribeResult>(ProviderFailure());
  }
}
