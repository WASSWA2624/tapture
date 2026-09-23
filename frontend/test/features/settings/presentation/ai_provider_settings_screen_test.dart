import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/core/ai/ai_service.dart';
import 'package:tapture/core/ai/provider_registry.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/security/secure_storage.dart';
import 'package:tapture/features/settings/presentation/ai_provider_settings_screen.dart';
import 'package:tapture/features/settings/settings.dart';

void main() {
  testWidgets('an injected device provider saves selection and secret', (
    WidgetTester tester,
  ) async {
    final _SuccessfulAiService backend = _SuccessfulAiService();
    final _SuccessfulAiService device = _SuccessfulAiService();
    final ProviderRegistry registry = _registry(backend, device);
    final SettingsStore settings = SettingsStore.fake();
    final Map<SecretKey, String> secrets = <SecretKey, String>{};
    final Map<String, String> preferences = <String, String>{};
    final Map<String, String> database = <String, String>{};
    final SecureStorage storage = SecureStorage.fake(
      backing: secrets,
      preferences: preferences,
      database: database,
    );

    await _pump(
      tester,
      AiProviderSettingsScreen(
        registry: registry,
        settings: settings,
        storage: storage,
      ),
    );

    expect(find.text('Organisation backend'), findsOneWidget);
    expect(find.text('Device provider'), findsOneWidget);
    expect(find.text(Copy.apiKeyLabel), findsNothing);

    await tester.tap(find.text('Device provider'));
    await tester.pumpAndSettle();
    expect(find.text('Field model'), findsOneWidget);
    expect(find.text(Copy.apiKeyLabel), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'device-secret');
    await tester.ensureVisible(find.text(Copy.save));
    await tester.tap(find.text(Copy.save));
    await tester.pumpAndSettle();

    expect(settings.read(SettingKeys.aiProvider), 'device');
    expect(settings.read(SettingKeys.aiModel), 'field-model');
    expect(secrets[SecretKey.providerCredential], 'device-secret');
    expect(preferences.values, isNot(contains('device-secret')));
    expect(database.values, isNot(contains('device-secret')));

    await tester.ensureVisible(find.text(Copy.apiKeyTest));
    await tester.tap(find.text(Copy.apiKeyTest));
    await tester.pumpAndSettle();
    expect(find.text(Copy.apiKeySuccess), findsOneWidget);
    expect(device.readCalls, 1);
  });

  testWidgets('invalid saved selection visibly falls back without erasing it', (
    WidgetTester tester,
  ) async {
    final SettingsStore settings = SettingsStore.fake(
      stored: <String, Object?>{
        SettingKeys.aiProvider.name: 'removed-provider',
        SettingKeys.aiModel.name: 'removed-model',
      },
    );

    await _pump(
      tester,
      AiProviderSettingsScreen(
        registry: _registry(_SuccessfulAiService(), _SuccessfulAiService()),
        settings: settings,
        storage: SecureStorage.fake(backing: <SecretKey, String>{}),
      ),
    );

    expect(find.text('Organisation backend'), findsOneWidget);
    expect(find.text(Copy.aiSelectionFallback), findsOneWidget);
    expect(settings.read(SettingKeys.aiProvider), 'removed-provider');
    expect(settings.read(SettingKeys.aiModel), 'removed-model');
  });
}

Future<void> _pump(WidgetTester tester, Widget child) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(800, 1200);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(
    MaterialApp(
      theme: buildTheme(brightness: Brightness.light),
      home: child,
    ),
  );
  await tester.pumpAndSettle();
}

ProviderRegistry _registry(AiService backend, AiService device) {
  return ProviderRegistry(
    descriptors: <ProviderDescriptor>[
      ProviderDescriptor(
        id: ProviderRegistry.backendId,
        label: 'Organisation backend',
        operations: AiOperation.values.toSet(),
        keyCustody: ProviderKeyCustody.backend,
        deviceKeyAllowed: false,
        available: true,
        service: backend,
        models: <ModelDescriptor>[
          ModelDescriptor(
            id: 'default',
            label: 'Organisation default',
            operations: AiOperation.values.toSet(),
          ),
        ],
      ),
      ProviderDescriptor(
        id: 'device',
        label: 'Device provider',
        operations: const <AiOperation>{AiOperation.extractFields},
        keyCustody: ProviderKeyCustody.device,
        deviceKeyAllowed: true,
        available: true,
        service: device,
        models: <ModelDescriptor>[
          ModelDescriptor(
            id: 'field-model',
            label: 'Field model',
            operations: const <AiOperation>{AiOperation.extractFields},
          ),
        ],
      ),
    ],
  );
}

final class _SuccessfulAiService implements AiService {
  int readCalls = 0;

  @override
  bool get isAvailable => true;

  @override
  Future<Result<ReadTextResult>> readText(ReadTextRequest request) async {
    readCalls += 1;
    return const Success<ReadTextResult>(ReadTextResult(text: 'ok'));
  }

  @override
  Future<Result<ExtractFieldsResult>> extractFields(
    ExtractFieldsRequest request,
  ) async {
    return const Success<ExtractFieldsResult>(
      ExtractFieldsResult(fields: <String, String?>{}),
    );
  }

  @override
  Future<Result<RefineTextResult>> refineText(RefineTextRequest request) async {
    return Success<RefineTextResult>(RefineTextResult(text: request.raw));
  }

  @override
  Future<Result<TranscribeResult>> transcribe(TranscribeRequest request) async {
    return const Success<TranscribeResult>(TranscribeResult(text: 'ok'));
  }
}
