import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/core/ai/provider_registry.dart';
import 'package:tapture/core/ai/proxy_ai_service.dart';
import 'package:tapture/core/ai/server_provider_registry.dart';
import 'package:tapture/core/backend/server_ai_catalogue.dart';
import 'package:tapture/core/backend/server_credential_client.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/security/secure_storage.dart';
import 'package:tapture/core/widgets/fields/app_choice_field.dart';
import 'package:tapture/features/settings/presentation/ai_provider_settings_screen.dart';
import 'package:tapture/features/settings/settings.dart';

import '../../../support/ai_catalogue_fixture.dart';

void main() {
  for (final String provider in <String>['gemini', 'xai']) {
    testWidgets(
      '$provider personal key is saved on server and removal keeps the explicit account',
      (WidgetTester tester) async {
        final Map<SecretKey, String> secrets = <SecretKey, String>{};
        final SettingsStore settings = SettingsStore.fake();
        final List<({String method, Map<String, Object?>? body})> requests =
            <({String method, Map<String, Object?>? body})>[];
        var configured = false;
        final ServerCredentialClient client = ServerCredentialClient(
          send:
              ({
                required String method,
                required String path,
                Map<String, Object?>? body,
                String? token,
              }) async {
                expect(path, '/api/v1/ai/credentials/$provider');
                requests.add((method: method, body: body));
                if (method == 'PUT') configured = true;
                if (method == 'DELETE') configured = false;
                return (
                  status: 200,
                  body: <String, Object?>{
                    'provider': provider,
                    'configured': configured,
                  },
                );
              },
        );
        final ServerAiCatalogue catalogue = ServerAiCatalogue(
          readSnapshot: () => <Object?>[xaiProviderMetadata()],
          send:
              ({
                required String method,
                required String path,
                Map<String, Object?>? body,
                String? token,
              }) async => (
                status: 200,
                body: <String, Object?>{
                  'providers': <Object?>[xaiProviderMetadata()],
                },
              ),
        );
        addTearDown(catalogue.dispose);
        final ProviderRegistry registry = serverProviderRegistry(
          catalogue: provider == 'xai' ? catalogue : null,
          proxy: ProxyAiService(
            baseUrl: 'https://organisation.test',
            send:
                ({
                  required String path,
                  required Map<String, Object?> json,
                }) async => (status: 503, body: '{}'),
          ),
        );
        await tester.pumpWidget(
          ProviderScope(
            overrides: <Override>[
              ...aiProviderSettingsOverrides(
                registry: registry,
                settings: settings,
                storage: SecureStorage.fake(backing: secrets),
              ),
              serverCredentialClientProvider.overrideWithValue(client),
              serverAiCatalogueProvider.overrideWithValue(catalogue),
            ],
            child: MaterialApp(
              theme: buildTheme(brightness: Brightness.light),
              home: const AiProviderSettingsScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byType(AppChoiceField<String>).first);
        await tester.pumpAndSettle();
        await tester.tap(
          find
              .text('Your ${provider == 'xai' ? 'xAI' : provider} account')
              .last,
        );
        await tester.pumpAndSettle();
        expect(find.text(Copy.serverApiKeyCustody), findsNothing);
        await tester.ensureVisible(find.text(Copy.aiConnectionDetails));
        await tester.tap(find.text(Copy.aiConnectionDetails));
        await tester.pumpAndSettle();
        expect(find.text(Copy.serverApiKeyCustody), findsOneWidget);
        await tester.enterText(find.byType(TextField), 'server-only-fixture');
        await tester.ensureVisible(find.text(Copy.save));
        await tester.tap(find.text(Copy.save));
        await tester.pumpAndSettle();
        expect(
          requests.where((request) => request.method == 'PUT').single.body,
          <String, Object?>{'apiKey': 'server-only-fixture'},
        );
        expect(secrets, isEmpty);
        expect(settings.read(SettingKeys.aiProvider), 'personal-$provider');
        expect(
          tester.widget<TextField>(find.byType(TextField)).controller!.text,
          isEmpty,
        );
        expect(find.text(Copy.serverApiKeySaved), findsOneWidget);
        await tester.ensureVisible(
          find.byKey(const ValueKey<String>('ai-remove-key')),
        );
        await tester.tap(find.byKey(const ValueKey<String>('ai-remove-key')));
        await tester.pumpAndSettle();
        await tester.tap(find.text(Copy.apiKeyRemove).last);
        await tester.pumpAndSettle();
        expect(
          requests.where((request) => request.method == 'DELETE'),
          hasLength(1),
        );
        expect(settings.read(SettingKeys.aiProvider), 'personal-$provider');
        expect(secrets, isEmpty);
      },
    );
  }
}
