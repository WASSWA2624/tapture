import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tapture/app/route_paths.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/core/ai/ai_service.dart';
import 'package:tapture/core/ai/provider_registry.dart';
import 'package:tapture/core/backend/backend_config.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/security/secure_storage.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/feedback/app_banner.dart';
import 'package:tapture/core/widgets/fields/app_choice_field.dart';
import 'package:tapture/features/account/presentation/account_route.dart';
import 'package:tapture/features/account/presentation/account_session.dart';
import 'package:tapture/features/account/presentation/backend_settings_screen.dart';
import 'package:tapture/features/account/presentation/server_address_form.dart';
import 'package:tapture/features/settings/presentation/ai_provider_settings_screen.dart';
import 'package:tapture/features/settings/settings.dart';

void main() {
  for (final bool configured in <bool>[false, true]) {
    testWidgets(
      'Server and account opens ${configured ? 'cached account' : 'server setup'} without saving AI settings',
      (WidgetTester tester) async {
        final SettingsStore settings = SettingsStore.fake();
        final Map<SecretKey, String> secrets = <SecretKey, String>{};
        final GoRouter router = GoRouter(
          initialLocation: RoutePaths.settingsAi,
          routes: <RouteBase>[
            GoRoute(
              path: RoutePaths.settingsAi,
              builder: (BuildContext _, GoRouterState _) =>
                  const AiProviderSettingsScreen(),
            ),
            GoRoute(
              path: RoutePaths.settingsAccount,
              builder: (BuildContext _, GoRouterState _) =>
                  const AccountRoute(),
            ),
          ],
        );
        addTearDown(router.dispose);
        await tester.pumpWidget(
          ProviderScope(
            overrides: <Override>[
              ...aiProviderSettingsOverrides(
                registry: _registry(
                  _SuccessfulAiService(),
                  _SuccessfulAiService(),
                ),
                settings: settings,
                storage: SecureStorage.fake(backing: secrets),
              ),
              backendConfigProvider.overrideWith(
                (Ref _) => Stream<BackendConfig>.value(
                  BackendConfig(
                    baseUrl: configured ? 'https://organisation.test' : '',
                  ),
                ),
              ),
            ],
            child: MaterialApp.router(
              theme: buildTheme(brightness: Brightness.light),
              routerConfig: router,
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text(Copy.aiServerAndAccount));
        await tester.tap(find.text(Copy.aiServerAndAccount));
        await tester.pumpAndSettle();
        expect(router.state.uri.path, RoutePaths.settingsAi);
        expect(
          find.byType(configured ? BackendSettingsScreen : ServerAddressForm),
          findsOneWidget,
        );
        expect(
          settings.read(SettingKeys.aiProvider),
          SettingKeys.aiProvider.defaultValue,
        );
        expect(secrets, isEmpty);
      },
    );
  }

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
      registry: registry,
      settings: settings,
      storage: storage,
    );

    expect(find.text('Organisation backend'), findsOneWidget);
    expect(find.text('Device provider'), findsNothing);
    expect(find.text(Copy.apiKeyLabel), findsNothing);

    await tester.tap(find.byType(AppChoiceField<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Device provider').last);
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
    expect(device.readCalls, 0);
    expect(device.extractCalls, 1);
  });

  testWidgets('a saved key is never shown and one confirmed action removes '
      'it and the selection that needed it', (WidgetTester tester) async {
    final SettingsStore settings = SettingsStore.fake();
    final Map<SecretKey, String> secrets = <SecretKey, String>{};
    final SecureStorage storage = SecureStorage.fake(backing: secrets);
    final ProviderRegistry registry = _registry(
      _SuccessfulAiService(),
      _SuccessfulAiService(),
    );
    await _pump(
      tester,
      registry: registry,
      settings: settings,
      storage: storage,
    );

    await tester.tap(find.byType(AppChoiceField<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Device provider').last);
    await tester.pumpAndSettle();
    // Nothing stored yet: nothing to remove.
    expect(find.byKey(const ValueKey<String>('ai-remove-key')), findsNothing);

    await tester.enterText(find.byType(TextField), 'device-secret');
    await tester.ensureVisible(find.text(Copy.save));
    await tester.tap(find.text(Copy.save));
    await tester.pumpAndSettle();

    expect(find.text('device-secret'), findsNothing);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      isEmpty,
    );
    expect(find.text(Copy.apiKeySaved), findsOneWidget);
    await settings.write(
      SettingKeys.aiProviderSelection,
      '{"extractFields":{"provider":"device","model":"field-model"}}',
    );
    final Finder remove = find.byKey(const ValueKey<String>('ai-remove-key'));
    expect(remove, findsOneWidget);

    await tester.ensureVisible(remove);
    await tester.tap(remove);
    await tester.pumpAndSettle();
    expect(find.text(Copy.apiKeyRemoveTitle), findsOneWidget);
    expect(secrets[SecretKey.providerCredential], 'device-secret');
    await tester.tap(find.text(Copy.apiKeyRemove).last);
    await tester.pumpAndSettle();

    expect(secrets.containsKey(SecretKey.providerCredential), isFalse);
    expect(settings.read(SettingKeys.aiProvider), ProviderRegistry.backendId);
    expect(
      settings.read(SettingKeys.aiModel),
      SettingKeys.aiModel.defaultValue,
    );
    expect(
      settings.read(SettingKeys.aiProviderSelection),
      SettingKeys.aiProviderSelection.defaultValue,
    );
    expect(find.text('Organisation backend'), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('ai-remove-key')), findsNothing);
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
      registry: _registry(_SuccessfulAiService(), _SuccessfulAiService()),
      settings: settings,
      storage: SecureStorage.fake(backing: <SecretKey, String>{}),
    );

    expect(find.text('removed-provider'), findsOneWidget);
    expect(find.text(Copy.aiSelectionInvalid), findsOneWidget);
    expect(settings.read(SettingKeys.aiProvider), 'removed-provider');
    expect(settings.read(SettingKeys.aiModel), 'removed-model');
  });

  for (final ({
        String name,
        String provider,
        String model,
        bool available,
        Set<AiOperation> operations,
      })
      selected
      in <
        ({
          String name,
          String provider,
          String model,
          bool available,
          Set<AiOperation> operations,
        })
      >[
        (
          name: 'missing provider',
          provider: 'missing',
          model: 'field-model',
          available: false,
          operations: const <AiOperation>{AiOperation.extractFields},
        ),
        (
          name: 'missing model',
          provider: 'device',
          model: 'missing',
          available: false,
          operations: const <AiOperation>{AiOperation.extractFields},
        ),
        (
          name: 'unsupported capability',
          provider: 'device',
          model: 'field-model',
          available: true,
          operations: const <AiOperation>{AiOperation.refineText},
        ),
        (
          name: 'temporary unavailability',
          provider: 'device',
          model: 'field-model',
          available: false,
          operations: const <AiOperation>{AiOperation.extractFields},
        ),
      ]) {
    testWidgets(
      '${selected.name} has one identity-aware status and preserves saved selection',
      (WidgetTester tester) async {
        final SettingsStore settings = SettingsStore.fake(
          failWrites: true,
          stored: <String, Object?>{
            SettingKeys.aiProvider.name: selected.provider,
            SettingKeys.aiModel.name: selected.model,
          },
        );
        await _pump(
          tester,
          registry: _registry(
            _SuccessfulAiService(),
            _SuccessfulAiService(),
            deviceAvailable: selected.available,
            deviceOperations: selected.operations,
          ),
          settings: settings,
          storage: SecureStorage.fake(backing: <SecretKey, String>{}),
        );
        expect(find.byType(AppBanner), findsOneWidget);
        final bool invalid = selected.name != 'temporary unavailability';
        expect(
          find.text(
            invalid ? Copy.aiSelectionInvalid : Copy.aiProviderUnavailable,
          ),
          findsOneWidget,
        );
        expect(
          find.text(
            invalid ? Copy.aiProviderUnavailable : Copy.aiSelectionInvalid,
          ),
          findsNothing,
        );
        final AppButton test = tester.widget<AppButton>(
          find.widgetWithText(AppButton, Copy.apiKeyTest),
        );
        expect(test.onPressed, isNull);
        expect(settings.read(SettingKeys.aiProvider), selected.provider);
        expect(settings.read(SettingKeys.aiModel), selected.model);
        await tester.tap(find.text(Copy.save));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey<String>('ai-current-status')),
          findsOneWidget,
        );
        expect(
          find.text(
            invalid ? Copy.aiSelectionInvalid : Copy.aiProviderUnavailable,
          ),
          findsNothing,
        );
        await tester.ensureVisible(find.text(Copy.aiConnectionDetails));
        await tester.tap(find.text(Copy.aiConnectionDetails));
        await tester.pumpAndSettle();
        expect(
          find.text(
            invalid ? Copy.aiSelectionInvalid : Copy.aiProviderUnavailable,
          ),
          findsOneWidget,
        );
        expect(find.text(Copy.tryAgain), findsOneWidget);
        expect(settings.read(SettingKeys.aiProvider), selected.provider);
        expect(settings.read(SettingKeys.aiModel), selected.model);
      },
    );
  }

  testWidgets(
    'a failed credential save keeps input and retries that write without a model call',
    (WidgetTester tester) async {
      final _ControlledStorage storage = _ControlledStorage();
      final _SuccessfulAiService device = _SuccessfulAiService();
      final SettingsStore settings = SettingsStore.fake(
        stored: <String, Object?>{
          SettingKeys.aiProvider.name: 'device',
          SettingKeys.aiModel.name: 'field-model',
        },
      );
      await _pump(
        tester,
        registry: _registry(_SuccessfulAiService(), device),
        settings: settings,
        storage: storage,
      );
      await tester.ensureVisible(find.text(Copy.apiKeyTest));
      await tester.tap(find.text(Copy.apiKeyTest));
      await tester.pumpAndSettle();
      expect(find.text(Copy.apiKeySuccess), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'retained-secret');
      await tester.tap(find.text(Copy.save));
      await tester.pumpAndSettle();
      expect(find.textContaining('The fixture write failed.'), findsOneWidget);
      expect(find.text(Copy.apiKeySuccess), findsNothing);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'retained-secret',
      );
      expect(
        tester.widget<TextField>(find.byType(TextField)).obscureText,
        isTrue,
      );
      await tester.ensureVisible(find.text(Copy.aiConnectionDetails));
      await tester.tap(find.text(Copy.aiConnectionDetails));
      await tester.pumpAndSettle();
      expect(find.text(Copy.apiKeySuccess), findsOneWidget);
      expect(find.text(Copy.aiCustody('device', true)), findsOneWidget);
      expect(device.extractCalls, 1);
      storage.failWrites = false;
      await tester.ensureVisible(find.text(Copy.tryAgain));
      await tester.tap(find.text(Copy.tryAgain));
      await tester.pumpAndSettle();
      expect(storage.writes, 2);
      expect(storage.secret, 'retained-secret');
      expect(find.textContaining('The fixture write failed.'), findsNothing);
      expect(find.text(Copy.apiKeySuccess), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        isEmpty,
      );
      expect(device.extractCalls, 1);
    },
  );
}

Future<void> _pump(
  WidgetTester tester, {
  required ProviderRegistry registry,
  required SettingsStore settings,
  required SecureStorage storage,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(800, 1200);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(
    ProviderScope(
      overrides: aiProviderSettingsOverrides(
        registry: registry,
        settings: settings,
        storage: storage,
      ),
      child: MaterialApp(
        theme: buildTheme(brightness: Brightness.light),
        home: const AiProviderSettingsScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

ProviderRegistry _registry(
  AiService backend,
  AiService device, {
  bool deviceAvailable = true,
  Set<AiOperation> deviceOperations = const <AiOperation>{
    AiOperation.extractFields,
  },
}) {
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
        operations: deviceOperations,
        keyCustody: ProviderKeyCustody.device,
        deviceKeyAllowed: true,
        available: deviceAvailable,
        service: device,
        models: <ModelDescriptor>[
          ModelDescriptor(
            id: 'field-model',
            label: 'Field model',
            operations: deviceOperations,
          ),
        ],
      ),
    ],
  );
}

final class _ControlledStorage implements SecureStorage {
  bool failWrites = true;
  int writes = 0;
  String? secret;
  @override
  Future<Result<void>> putSecret(SecretKey key, String value) async {
    writes++;
    if (failWrites) {
      return const FailureResult<void>(
        StorageFailure(message: 'The fixture write failed.'),
      );
    }
    secret = value;
    return const Success<void>(null);
  }

  @override
  Future<Result<String?>> readSecret(SecretKey key) async =>
      Success<String?>(secret);
  @override
  Future<Result<void>> deleteSecret(SecretKey key) async {
    secret = null;
    return const Success<void>(null);
  }

  @override
  Future<void> deleteAll() async {
    secret = null;
  }
}

final class _SuccessfulAiService implements AiService {
  int readCalls = 0;
  int extractCalls = 0;

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
    extractCalls += 1;
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
