import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/app/theme/outdoor_theme.dart';
import 'package:tapture/core/ai/provider_registry.dart';
import 'package:tapture/core/ai/proxy_ai_service.dart';
import 'package:tapture/core/ai/server_provider_registry.dart';
import 'package:tapture/core/backend/backend_api_client.dart';
import 'package:tapture/core/backend/server_ai_catalogue.dart';
import 'package:tapture/core/backend/server_credential_client.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/copy/l10n/app_localizations.g.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/security/secure_storage.dart';
import 'package:tapture/core/widgets/app_list_tile.dart';
import 'package:tapture/core/widgets/fields/app_choice_field.dart';
import 'package:tapture/features/settings/presentation/ai_provider_settings_screen.dart';
import 'package:tapture/features/projects/projects.dart'
    show projectSettingsStoreProvider;
import 'package:tapture/features/settings/settings.dart';

import '../../../support/ai_catalogue_fixture.dart';
import '../../../support/screen_matrix.dart';

void main() {
  testWidgets(
    'keyless settings never read or remove credentials or invoke credential endpoints',
    (WidgetTester tester) async {
      final _ObservedStorage storage = _ObservedStorage();
      final List<String> credentialRequests = <String>[];
      final SettingsStore settings = _settings();
      await _pump(
        tester,
        settings: settings,
        storage: storage,
        credentialRequests: credentialRequests,
      );
      expect(find.text(Copy.apiKeyLabel), findsNothing);
      expect(find.byKey(const ValueKey<String>('ai-remove-key')), findsNothing);
      expect(
        find.byType(TextField),
        findsNothing,
        reason: 'spending controls start collapsed',
      );
      final ProviderContainer container = ProviderScope.containerOf(
        tester.element(find.byType(AiProviderSettingsScreen)),
      );
      await container
          .read(aiProviderSettingsProvider.notifier)
          .removeCredential();
      await container
          .read(aiProviderSettingsProvider.notifier)
          .save('unused-key');
      await tester.pumpAndSettle();
      expect(storage.calls, isEmpty);
      expect(credentialRequests, isEmpty);
      expect(settings.read(SettingKeys.aiProvider), 'keyless-local-ai');
    },
  );

  testWidgets(
    'late catalogue refresh replaces stale choices without changing saved account or model',
    (WidgetTester tester) async {
      final Completer<({int status, Map<String, Object?> body})> response =
          Completer<({int status, Map<String, Object?> body})>();
      final SettingsStore settings = _settings(model: 'accurate');
      await _pump(
        tester,
        settings: settings,
        cached: false,
        send:
            ({
              required String method,
              required String path,
              Map<String, Object?>? body,
              String? token,
            }) => response.future,
        settle: false,
      );
      await tester.pump();
      expect(find.text('keyless-local-ai'), findsOneWidget);
      response.complete((
        status: 200,
        body: <String, Object?>{'providers': _rows()},
      ));
      await tester.pumpAndSettle();
      expect(find.text('Local compatible AI'), findsOneWidget);
      expect(find.text('accurate'), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('ai-fell-back')), findsNothing);
      expect(settings.read(SettingKeys.aiProvider), 'keyless-local-ai');
      expect(settings.read(SettingKeys.aiModel), 'accurate');
    },
  );

  testWidgets(
    'provider and model sheets search without exposing endpoint or credential editors',
    (WidgetTester tester) async {
      final SettingsStore settings = _settings();
      await _pump(tester, settings: settings);
      final List<AppChoiceField<String>> controls = tester
          .widgetList<AppChoiceField<String>>(
            find.byType(AppChoiceField<String>),
          )
          .toList();
      expect(controls, hasLength(2));
      expect(controls.every((control) => control.alwaysSheet), isTrue);
      await tester.tap(find.byType(AppChoiceField<String>).first);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Field account');
      await tester.pumpAndSettle();
      expect(find.widgetWithText(AppListTile, 'Field account'), findsOneWidget);
      await tester.tap(find.widgetWithText(AppListTile, 'Field account'));
      await tester.pumpAndSettle();
      expect(find.text(Copy.apiKeyLabel), findsOneWidget);
      final ProviderContainer container = ProviderScope.containerOf(
        tester.element(find.byType(AiProviderSettingsScreen)),
      );
      expect(
        container.read(aiProviderSettingsProvider).providerId,
        'personal-field-ai',
      );
      expect(
        settings.read(SettingKeys.aiProvider),
        'keyless-local-ai',
        reason: 'choosing has not confirmed Save',
      );
      await tester.ensureVisible(find.byType(AppChoiceField<String>).last);
      await tester.tap(find.byType(AppChoiceField<String>).last);
      await tester.pumpAndSettle();
      final Finder sheetSearch = find.byType(TextField).last;
      await tester.enterText(sheetSearch, 'accurate');
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(AppListTile, 'accurate'));
      await tester.pumpAndSettle();
      expect(container.read(aiProviderSettingsProvider).modelId, 'accurate');
      expect(find.textContaining('https://'), findsNothing);
    },
  );

  testWidgets('a raised spending limit requires explicit confirmation', (
    WidgetTester tester,
  ) async {
    final SettingsStore settings = _settings();
    await _pump(tester, settings: settings);
    await tester.ensureVisible(find.text(Copy.aiCostControls));
    await tester.tap(find.text(Copy.aiCostControls));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '5');
    await tester.tap(find.byKey(const ValueKey<String>('ai-save')));
    await tester.pumpAndSettle();
    expect(settings.read(SettingKeys.aiRequestMaxCost), 0);
    await tester.tap(find.text(Copy.cancel));
    await tester.pumpAndSettle();
    expect(settings.read(SettingKeys.aiRequestMaxCost), 0);
    await tester.tap(find.byKey(const ValueKey<String>('ai-save')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(Copy.save).last);
    await tester.pumpAndSettle();
    expect(settings.read(SettingKeys.aiRequestMaxCost), 5);
  });

  testWidgets(
    'credential status failure is retryable through GET without changing a saved choice',
    (WidgetTester tester) async {
      final SettingsStore settings = SettingsStore.fake(
        stored: <String, Object?>{
          SettingKeys.aiProvider.name: 'personal-field-ai',
          SettingKeys.aiModel.name: 'accurate',
        },
      );
      final List<String> requests = <String>[];
      int status = 503;
      await _pump(
        tester,
        settings: settings,
        credentialRequests: requests,
        credentialSend:
            ({
              required String method,
              required String path,
              Map<String, Object?>? body,
              String? token,
            }) async =>
                (status: status, body: <String, Object?>{'configured': false}),
      );
      expect(find.textContaining('server could not update'), findsOneWidget);
      status = 200;
      await tester.ensureVisible(find.text(Copy.tryAgain));
      await tester.tap(find.text(Copy.tryAgain));
      await tester.pumpAndSettle();
      expect(find.textContaining('server could not update'), findsNothing);
      expect(requests, <String>[
        'GET /api/v1/ai/credentials/field-ai',
        'GET /api/v1/ai/credentials/field-ai',
      ]);
      expect(settings.read(SettingKeys.aiProvider), 'personal-field-ai');
      expect(settings.read(SettingKeys.aiModel), 'accurate');
    },
  );

  for (final ScreenMatrix cell in ScreenMatrix.cells) {
    testWidgets(
      'compact AI selections and advanced controls are reachable at ${cell.description}',
      (WidgetTester tester) async {
        await _pump(tester, cell: cell);
        expect(find.byType(AppChoiceField<String>), findsNWidgets(2));
        expect(find.byType(TextField), findsNothing);
        await tester.tap(find.byType(AppChoiceField<String>).first);
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField), 'Local compatible');
        await tester.pumpAndSettle();
        await tester.tap(
          find.widgetWithText(AppListTile, 'Local compatible AI'),
        );
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text(Copy.aiCostControls));
        await tester.tap(find.text(Copy.aiCostControls));
        await tester.pumpAndSettle();
        expect(find.byType(TextField), findsOneWidget);
        await tester.ensureVisible(find.byType(TextField));
        await tester.enterText(find.byType(TextField), '0');
        await tester.tap(find.byKey(const ValueKey<String>('ai-save')));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
      variant: TargetPlatformVariant.all(),
    );
  }

  testWidgets(
    'pseudo-locale preserves searchable choices and disclosure at text 2',
    (WidgetTester tester) async {
      await _pump(
        tester,
        locale: const Locale('en', 'XA'),
        cell: const ScreenMatrix(Size(393, 320), 2, Brightness.light, false),
      );
      final LocalizedCopy copy = Copy.of(
        tester.element(find.byType(AiProviderSettingsScreen)),
      );
      expect(find.text(copy.aiSupportedProviders), findsOneWidget);
      await tester.tap(find.byType(AppChoiceField<String>).first);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Local compatible');
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(AppListTile, 'Local compatible AI'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text(copy.aiCostControls));
      await tester.tap(find.text(copy.aiCostControls));
      await tester.pumpAndSettle();
      expect(find.text(copy.aiSpendingLimit), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}

List<Object?> _rows() => <Object?>[
  aiProviderMetadata(
    id: 'local-ai',
    label: 'Local compatible AI',
    authMode: 'none',
  ),
  aiProviderMetadata(id: 'gemini', label: 'Gemini'),
  aiProviderMetadata(label: 'Field account', managed: false),
];

SettingsStore _settings({String model = 'default'}) => SettingsStore.fake(
  stored: <String, Object?>{
    SettingKeys.aiProvider.name: 'keyless-local-ai',
    SettingKeys.aiModel.name: model,
  },
);

Future<void> _pump(
  WidgetTester tester, {
  SettingsStore? settings,
  _ObservedStorage? storage,
  List<String>? credentialRequests,
  BackendSend? send,
  BackendSend? credentialSend,
  bool cached = true,
  bool settle = true,
  Locale locale = const Locale('en'),
  ScreenMatrix cell = const ScreenMatrix(
    Size(800, 900),
    1,
    Brightness.light,
    false,
  ),
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = cell.size;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final ServerAiCatalogue catalogue = ServerAiCatalogue(
    readSnapshot: () => cached ? _rows() : null,
    send:
        send ??
        ({
          required String method,
          required String path,
          Map<String, Object?>? body,
          String? token,
        }) async =>
            (status: 200, body: <String, Object?>{'providers': _rows()}),
  );
  addTearDown(catalogue.dispose);
  final ProxyAiService proxy = ProxyAiService(
    baseUrl: 'https://organisation.test',
    send: ({required String path, required Map<String, Object?> json}) async =>
        (status: 503, body: '{}'),
  );
  final ServerCredentialClient credentials = ServerCredentialClient(
    send:
        ({
          required String method,
          required String path,
          Map<String, Object?>? body,
          String? token,
        }) async {
          credentialRequests?.add('$method $path');
          if (credentialSend != null) {
            return credentialSend(
              method: method,
              path: path,
              body: body,
              token: token,
            );
          }
          return (status: 200, body: <String, Object?>{'configured': false});
        },
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        projectSettingsStoreProvider.overrideWithValue(settings ?? _settings()),
        providerKeyStorageProvider.overrideWithValue(
          storage ?? _ObservedStorage(),
        ),
        providerRegistryProvider.overrideWith((Ref ref) {
          ref.watch(serverAiCatalogueChangesProvider);
          return serverProviderRegistry(proxy: proxy, catalogue: catalogue);
        }),
        serverAiCatalogueProvider.overrideWithValue(catalogue),
        serverCredentialClientProvider.overrideWithValue(credentials),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: cell.outdoor
            ? buildOutdoorTheme(Brightness.light)
            : buildTheme(brightness: cell.brightness),
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (BuildContext context, Widget? child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(cell.textScale)),
          child: child!,
        ),
        home: const AiProviderSettingsScreen(),
      ),
    ),
  );
  if (settle) await tester.pumpAndSettle();
}

final class _ObservedStorage implements SecureStorage {
  final List<String> calls = <String>[];
  @override
  Future<Result<String?>> readSecret(SecretKey key) async {
    calls.add('read');
    return const Success<String?>(null);
  }

  @override
  Future<Result<void>> putSecret(SecretKey key, String value) async {
    calls.add('write');
    return const Success<void>(null);
  }

  @override
  Future<Result<void>> deleteSecret(SecretKey key) async {
    calls.add('delete');
    return const Success<void>(null);
  }

  @override
  Future<void> deleteAll() async => calls.add('clear');
}
