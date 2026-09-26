import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/ai/ai_service.dart';
import 'package:tapture/core/ai/provider_registry.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/features/processing/data/provider_selection.dart';
import 'package:tapture/features/settings/settings.dart';

import '../../../support/processing_fixture.dart';

void main() {
  final AiService working = ScriptedExtraction(const <String>['{}']);

  ProviderDescriptor descriptor(
    String id, {
    bool available = true,
    Set<AiOperation> operations = const <AiOperation>{
      AiOperation.extractFields,
      AiOperation.transcribe,
    },
  }) {
    return ProviderDescriptor(
      id: id,
      label: id,
      operations: operations,
      keyCustody: id == ProviderRegistry.backendId
          ? ProviderKeyCustody.backend
          : ProviderKeyCustody.device,
      deviceKeyAllowed: id != ProviderRegistry.backendId,
      available: available,
      service: available ? working : const AiService.unavailable(),
      models: <ModelDescriptor>[
        ModelDescriptor(id: 'fast', label: 'Fast', operations: operations),
        ModelDescriptor(
          id: 'accurate',
          label: 'Accurate',
          operations: operations,
        ),
      ],
    );
  }

  final ProviderRegistry registry = ProviderRegistry(
    descriptors: <ProviderDescriptor>[
      ProviderDescriptor(
        id: ProviderRegistry.backendId,
        label: 'Organisation backend',
        operations: AiOperation.values.toSet(),
        keyCustody: ProviderKeyCustody.backend,
        deviceKeyAllowed: false,
        available: true,
        service: working,
        models: <ModelDescriptor>[
          ModelDescriptor(
            id: 'default',
            label: 'Default',
            operations: AiOperation.values.toSet(),
          ),
        ],
      ),
      descriptor('vision'),
      descriptor('offline', available: false),
      descriptor(
        'reader',
        operations: const <AiOperation>{AiOperation.extractFields},
      ),
    ],
  );

  Future<Project> project(String settings) async {
    final ProcessingFixture fixture = await ProcessingFixture.open();
    await fixture.setProjectSettings(settings);
    return fixture.db.select(fixture.db.projects).getSingle();
  }

  ProviderSelection selection({
    String appSelection = '{}',
    String provider = 'backend',
    String model = 'default',
  }) {
    return ProviderSelection(
      settings: SettingsStore.fake(
        stored: <String, Object?>{
          SettingKeys.aiProviderSelection.name: appSelection,
          SettingKeys.aiProvider.name: provider,
          SettingKeys.aiModel.name: model,
        },
      ),
      providers: registry,
    );
  }

  test("the project's own choice wins", () async {
    final resolved =
        selection(
          appSelection:
              '{"extractFields":{"provider":"backend","model":"default"}}',
        ).resolve(
          await project(
            '{"providerSelection":{"extractFields":'
            '{"provider":"vision","model":"accurate"}}}',
          ),
          AiOperation.extractFields,
        );

    expect(resolved.provider.id, 'vision');
    expect(resolved.model.id, 'accurate');
    expect(resolved.fellBack, isFalse);
  });

  test('then the app choice for the operation', () async {
    final resolved = selection(
      appSelection: '{"transcribe":{"provider":"vision","model":"fast"}}',
    ).resolve(await project('{}'), AiOperation.transcribe);

    expect(resolved.provider.id, 'vision');
    expect(resolved.model.id, 'fast');
  });

  test('then the app-wide provider and model', () async {
    final resolved = selection(
      provider: 'vision',
      model: 'accurate',
    ).resolve(await project('{}'), AiOperation.extractFields);

    expect(resolved.provider.id, 'vision');
    expect(resolved.model.id, 'accurate');
  });

  test(
    'an unavailable or unsuitable choice falls back to the backend',
    () async {
      final Project plain = await project('{}');

      final offline = selection(
        provider: 'offline',
        model: 'fast',
      ).resolve(plain, AiOperation.extractFields);
      expect(offline.provider.id, ProviderRegistry.backendId);
      expect(offline.fellBack, isTrue);

      final unsuitable = selection(
        provider: 'reader',
        model: 'fast',
      ).resolve(plain, AiOperation.transcribe);
      expect(unsuitable.provider.id, ProviderRegistry.backendId);
      expect(unsuitable.fellBack, isTrue);
    },
  );
}
