import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/ai/provider_registry.dart';
import 'package:tapture/core/ai/proxy_ai_service.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/features/processing/data/record_bundle.dart';
import 'package:tapture/features/processing/data/record_bundle_loader.dart';
import 'package:tapture/features/processing/data/stage_settings.dart';
import 'package:tapture/features/projects/projects.dart'
    show ProjectSettingsResolved;
import 'package:tapture/features/settings/settings.dart';

import '../../../support/factories.dart';

void main() {
  test(
    'a stage reads late registry refresh and changes its egress preview identity',
    () async {
      final AppDatabase db = await seededDatabase(records: 1);
      addTearDown(db.close);
      final RecordRow record = await db.select(db.records).getSingle();
      final RecordBundle bundle = await RecordBundleLoader(
        db: db,
      ).load(record.id);
      ProviderRegistry current = ProviderRegistry.keyless();
      final StageSettings settings = StageSettings(
        settings: SettingsStore.fake(),
        providers: current,
        providersLookup: () => current,
      );
      final String before = settings.egressScope(bundle);
      expect(
        settings
            .selection(bundle, AiOperation.extractFields)
            .provider
            .available,
        isFalse,
      );
      current = ProviderRegistry.keyless(
        proxy: ProxyAiService(
          baseUrl: 'https://organisation.test',
          send:
              ({
                required String path,
                required Map<String, Object?> json,
              }) async => (status: 503, body: '{}'),
        ),
      );
      expect(
        settings
            .selection(bundle, AiOperation.extractFields)
            .provider
            .available,
        isTrue,
      );
      expect(settings.egressScope(bundle), isNot(before));
      expect(
        settings.selection(bundle, AiOperation.extractFields).provider.id,
        ProviderRegistry.backendId,
      );
    },
  );
  test('a project override wins over the app store it inherits', () async {
    final AppDatabase db = await seededDatabase(records: 1);
    addTearDown(db.close);
    await db
        .update(db.projects)
        .write(
          const ProjectsCompanion(
            settings: Value<String>('{"confidenceHigh":0.95}'),
          ),
        );
    final RecordRow record = await db.select(db.records).getSingle();
    final RecordBundle bundle = await RecordBundleLoader(
      db: db,
    ).load(record.id);
    final StageSettings settings = StageSettings(
      settings: SettingsStore.fake(
        stored: <String, Object?>{
          SettingKeys.confidenceMedium.name: 0.55,
          SettingKeys.aiDailyRequestCap.name: 9,
        },
      ),
      providers: ProviderRegistry.keyless(),
    );

    final ProjectSettingsResolved resolved = settings.project(bundle);

    expect(resolved.confidenceHigh, 0.95);
    expect(resolved.confidenceMedium, 0.55);
    expect(resolved.dailyRequestCap, 9);
    expect(settings.read(SettingKeys.aiDailyRequestCap), 9);
  });

  test('the selection falls back to the keyless backend', () async {
    final AppDatabase db = await seededDatabase(records: 1);
    addTearDown(db.close);
    final RecordRow record = await db.select(db.records).getSingle();
    final RecordBundle bundle = await RecordBundleLoader(
      db: db,
    ).load(record.id);
    final StageSettings settings = StageSettings(
      settings: SettingsStore.fake(),
      providers: ProviderRegistry.keyless(),
    );

    expect(
      settings.selection(bundle, AiOperation.extractFields).provider.id,
      ProviderRegistry.backendId,
    );
  });
}
