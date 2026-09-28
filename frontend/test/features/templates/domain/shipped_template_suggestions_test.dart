import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/ai/ai_service.dart';
import 'package:tapture/core/ai/provider_registry.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/network/offline_now.dart';
import 'package:tapture/features/projects/projects.dart';
import 'package:tapture/features/settings/settings.dart';
import 'package:tapture/features/templates/domain/shipped_template_entry.dart';
import 'package:tapture/features/templates/domain/shipped_template_suggestions.dart';
import 'package:tapture/features/templates/presentation/shipped_suggestions_controller.dart';

import '../../../support/factories.dart';

void main() {
  test(
    'model order is a proposal and egress contains only description and catalogue labels',
    () async {
      final _RankingService service = _RankingService();
      final Result<List<String>> result = await ShippedTemplateSuggestions(
        service,
      ).suggest('count laptops', _candidates);
      expect((result as Success<List<String>>).value, <String>[
        'second',
        'first',
      ]);
      final ExtractFieldsRequest request = service.request!;
      expect(request.captions, <String>['count laptops']);
      expect(request.ocrText, isEmpty);
      expect(request.transcripts, isEmpty);
      expect(request.context, isEmpty);
      expect(request.imagePaths, isEmpty);
      expect(request.predefinedRows, isEmpty);
      expect(request.fieldSchema.first['options'], <String>[
        'CAT-1: General inventory (Register)',
        'CAT-2: Computer inventory (Register)',
      ]);
      expect(
        _candidates.map((ShippedTemplateEntry row) => row.templateKey),
        <String>['first', 'second'],
      );
    },
  );

  test('duplicates or choices outside the shortlist are rejected', () async {
    final Result<List<String>> result = await ShippedTemplateSuggestions(
      _RankingService(duplicate: true),
    ).suggest('count laptops', _candidates);
    expect(result, isA<FailureResult<List<String>>>());
  });

  for (final ({bool offline, bool ai, bool available}) scenario
      in <({bool offline, bool ai, bool available})>[
        (offline: true, ai: true, available: true),
        (offline: false, ai: false, available: true),
        (offline: false, ai: true, available: false),
        (offline: false, ai: true, available: true),
      ]) {
    test('suggestion availability follows $scenario', () {
      final _RankingService service = _RankingService(
        available: scenario.available,
      );
      final ProviderContainer container = ProviderContainer(
        overrides: <Override>[
          offlineNowProvider.overrideWithValue(scenario.offline),
          currentProjectDetailsProvider.overrideWithValue(
            aProject().copyWith(
              settings: ProjectSettings(aiEnabled: scenario.ai),
            ),
          ),
          projectSettingsStoreProvider.overrideWithValue(SettingsStore.fake()),
          providerRegistryProvider.overrideWithValue(
            ProviderRegistry.keyless(proxy: service),
          ),
        ],
      );
      addTearDown(container.dispose);
      expect(
        container.read(shippedSuggestionServiceProvider),
        scenario.offline || !scenario.ai || !scenario.available
            ? isNull
            : same(service),
      );
      expect(service.request, isNull);
    });
  }
}

const ShippedCatalogueCategory _category = ShippedCatalogueCategory(
  code: 'CAT',
  title: 'Catalogue',
  supergroupCode: '1',
  supergroupTitle: 'Catalogue',
);
const ShippedRecordType _recordType = ShippedRecordType(
  code: 'REG',
  title: 'Register',
  kind: 'register',
);
const List<ShippedTemplateEntry> _candidates = <ShippedTemplateEntry>[
  ShippedTemplateEntry(
    templateKey: 'first',
    kind: 'register',
    fieldCount: 2,
    title: 'General inventory',
    code: 'CAT-1',
    category: _category,
    recordType: _recordType,
  ),
  ShippedTemplateEntry(
    templateKey: 'second',
    kind: 'register',
    fieldCount: 2,
    title: 'Computer inventory',
    code: 'CAT-2',
    category: _category,
    recordType: _recordType,
  ),
];

final class _RankingService implements AiService {
  _RankingService({this.duplicate = false, this.available = true});
  final bool duplicate;
  final bool available;
  ExtractFieldsRequest? request;
  @override
  bool get isAvailable => available;
  @override
  Future<Result<ExtractFieldsResult>> extractFields(
    ExtractFieldsRequest value,
  ) async {
    request = value;
    return Success<ExtractFieldsResult>(
      ExtractFieldsResult(
        fields: <String, String?>{
          'rank_1': 'CAT-2: Computer inventory (Register)',
          'rank_2': duplicate
              ? 'CAT-2: Computer inventory (Register)'
              : 'CAT-1: General inventory (Register)',
        },
      ),
    );
  }

  @override
  Future<Result<ReadTextResult>> readText(ReadTextRequest request) =>
      const AiService.unavailable().readText(request);
  @override
  Future<Result<RefineTextResult>> refineText(RefineTextRequest request) =>
      const AiService.unavailable().refineText(request);
  @override
  Future<Result<TranscribeResult>> transcribe(TranscribeRequest request) =>
      const AiService.unavailable().transcribe(request);
}
