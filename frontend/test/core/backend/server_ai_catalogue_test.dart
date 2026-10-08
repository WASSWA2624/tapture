import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/ai/provider_registry.dart';
import 'package:tapture/core/backend/server_ai_catalogue.dart';
import 'package:tapture/core/errors/result.dart';

import '../../support/ai_catalogue_fixture.dart';

void main() {
  test('every durable refresh invalidates catalogue consumers', () async {
    List<Object?> response = <Object?>[];
    final ServerAiCatalogue catalogue = ServerAiCatalogue(
      send:
          ({
            required String method,
            required String path,
            Map<String, Object?>? body,
            String? token,
          }) async =>
              (status: 200, body: <String, Object?>{'providers': response}),
    );
    final ProviderContainer container = ProviderContainer(
      overrides: [serverAiCatalogueProvider.overrideWithValue(catalogue)],
    );
    addTearDown(catalogue.dispose);
    addTearDown(container.dispose);
    final Provider<List<String>> identities = Provider<List<String>>((ref) {
      ref.watch(serverAiCatalogueChangesProvider);
      return catalogue.rows.map((row) => row['provider']! as String).toList();
    });
    final subscription = container.listen(identities, (_, _) {});
    addTearDown(subscription.close);
    for (final bool configured in [false, true, false, true]) {
      response = configured ? <Object?>[xaiProviderMetadata()] : <Object?>[];
      expect(await catalogue.refresh(), isA<Success<void>>());
      await container.pump();
      expect(container.read(identities), configured ? ['xai'] : isEmpty);
    }
  });

  test(
    'xAI photo text metadata persists only public identity and approved models',
    () async {
      List<Map<String, Object?>>? stored;
      final ServerAiCatalogue catalogue = ServerAiCatalogue(
        writeSnapshot: (rows) async => stored = rows,
        send:
            ({
              required String method,
              required String path,
              Map<String, Object?>? body,
              String? token,
            }) async => (
              status: 200,
              body: <String, Object?>{
                'providers': <Object?>[
                  <String, Object?>{
                    ...xaiProviderMetadata(),
                    'endpoint': 'https://api.x.ai/v1',
                    'apiKey': 'fixture-secret',
                  },
                ],
              },
            ),
      );
      addTearDown(catalogue.dispose);
      expect(await catalogue.refresh(), isA<Success<void>>());
      expect(stored!.single['provider'], 'xai');
      expect(stored!.single.keys, isNot(contains('apiKey')));
      expect(stored!.single.keys, isNot(contains('endpoint')));
      expect(
        catalogue.models('xai').map((model) => model.id),
        contains('grok-4.7'),
      );
      expect(catalogue.operations('xai'), <AiOperation>{
        AiOperation.readText,
        AiOperation.extractFields,
        AiOperation.refineText,
      });
      expect(catalogue.cost('xai', 'grok-4.7'), (
        amount: 1.0,
        unit: 'configured',
      ));
    },
  );
  test(
    'a valid empty refresh removes all configured adapters durably',
    () async {
      Object? cached = <Object?>[aiProviderMetadata()];
      final ServerAiCatalogue catalogue = ServerAiCatalogue(
        readSnapshot: () => cached,
        writeSnapshot: (List<Map<String, Object?>> rows) async => cached = rows,
        send:
            ({
              required String method,
              required String path,
              Map<String, Object?>? body,
              String? token,
            }) async => (
              status: 200,
              body: <String, Object?>{'providers': <Object?>[]},
            ),
      );
      addTearDown(catalogue.dispose);
      expect(catalogue.rows, hasLength(1));
      final Future<void> changed = catalogue.changes.first;
      expect(await catalogue.refresh(), isA<Success<void>>());
      await changed;
      expect(catalogue.rows, isEmpty);
      expect(cached, isEmpty);
      expect(catalogue.managedProvider, isNull);
    },
  );
  test(
    'validated allowlisted metadata becomes visible only after durable persistence',
    () async {
      final Completer<void> written = Completer<void>();
      Object? cached = <Object?>[aiProviderMetadata(label: 'Cached provider')];
      final List<String> requests = <String>[];
      final ServerAiCatalogue catalogue = ServerAiCatalogue(
        readSnapshot: () => cached,
        writeSnapshot: (List<Map<String, Object?>> rows) async {
          await written.future;
          cached = rows;
        },
        send:
            ({
              required String method,
              required String path,
              Map<String, Object?>? body,
              String? token,
            }) async {
              requests.add('$method $path');
              expect(body, isNull);
              return (
                status: 200,
                body: <String, Object?>{
                  'providers': <Object?>[
                    <String, Object?>{
                      ...aiProviderMetadata(),
                      'apiKey': 'must-not-persist',
                      'endpoint': 'https://untrusted.test',
                      'unknown': 'discard',
                    },
                  ],
                },
              );
            },
      );
      addTearDown(catalogue.dispose);
      final Future<void> changed = catalogue.changes.first;
      final Future<Result<void>> refreshing = catalogue.refresh();
      await Future<void>.value();
      expect(catalogue.rows.single['label'], 'Cached provider');
      written.complete();
      expect(await refreshing, isA<Success<void>>());
      await changed;
      expect(requests, <String>['GET /api/v1/ai/providers']);
      expect(catalogue.rows.single['label'], 'Field AI');
      expect(catalogue.rows.single.keys, isNot(contains('apiKey')));
      expect(catalogue.rows.single.keys, isNot(contains('endpoint')));
      expect(catalogue.rows.single.keys, isNot(contains('unknown')));
      expect(catalogue.operations('field-ai'), <AiOperation>{
        AiOperation.extractFields,
        AiOperation.refineText,
      });
      expect(catalogue.cost('field-ai', 'default'), (
        amount: 1.0,
        unit: 'configured',
      ));
      expect(catalogue.cost('field-ai', 'accurate'), (
        amount: 3.0,
        unit: 'configured',
      ));
      expect(catalogue.models('field-ai').map((model) => model.id), <String>[
        'default',
        'standard',
        'accurate',
      ]);
      expect(
        () => catalogue.rows.single['label'] = 'Mutated',
        throwsUnsupportedError,
      );
    },
  );

  for (final Map<String, Object?> invalid in <Map<String, Object?>>[
    <String, Object?>{'provider': '../bad'},
    <String, Object?>{'protocol': 'unconfigured-protocol'},
    <String, Object?>{'authMode': 'key-in-url'},
    <String, Object?>{
      'operations': <Object?>['extract', 'unknown'],
    },
    <String, Object?>{
      'operations': <Object?>['extract', 'extract'],
    },
    <String, Object?>{'model': 'not-enabled'},
    <String, Object?>{
      'models': <Object?>['standard', 'standard'],
    },
    <String, Object?>{
      'modelCostCeilings': <String, Object?>{'standard': -1, 'accurate': 3},
    },
    <String, Object?>{
      'modelCostCeilings': <String, Object?>{'standard': 0, 'accurate': 3},
    },
    <String, Object?>{'currency': 'unexpected'},
  ]) {
    test(
      'invalid ${invalid.keys.single} metadata preserves cached selections',
      () async {
        int writes = 0;
        final ServerAiCatalogue catalogue = ServerAiCatalogue(
          readSnapshot: () => <Object?>[aiProviderMetadata()],
          writeSnapshot: (_) async => writes++,
          send:
              ({
                required String method,
                required String path,
                Map<String, Object?>? body,
                String? token,
              }) async => (
                status: 200,
                body: <String, Object?>{
                  'providers': <Object?>[
                    <String, Object?>{...aiProviderMetadata(), ...invalid},
                  ],
                },
              ),
        );
        addTearDown(catalogue.dispose);
        expect(await catalogue.refresh(), isA<FailureResult<void>>());
        expect(writes, 0);
        expect(catalogue.row('field-ai')?['label'], 'Field AI');
      },
    );
  }

  test(
    'duplicate provider IDs and failed local cache writes never publish a new catalogue',
    () async {
      final List<Object?> response = <Object?>[
        aiProviderMetadata(),
        aiProviderMetadata(),
      ];
      final ServerAiCatalogue catalogue = ServerAiCatalogue(
        readSnapshot: () => <Object?>[
          aiProviderMetadata(label: 'Offline cached'),
        ],
        writeSnapshot: (_) async => throw StateError('disk full'),
        send:
            ({
              required String method,
              required String path,
              Map<String, Object?>? body,
              String? token,
            }) async =>
                (status: 200, body: <String, Object?>{'providers': response}),
      );
      addTearDown(catalogue.dispose);
      expect(await catalogue.refresh(), isA<FailureResult<void>>());
      response.removeLast();
      expect(await catalogue.refresh(), isA<FailureResult<void>>());
      expect(catalogue.rows.single['label'], 'Offline cached');
    },
  );

  test('metadata cannot advertise two different managed defaults', () {
    final ServerAiCatalogue catalogue = ServerAiCatalogue(
      readSnapshot: () => <Object?>[
        aiProviderMetadata(id: 'gemini'),
        aiProviderMetadata(id: 'openai'),
      ],
      send:
          ({
            required String method,
            required String path,
            Map<String, Object?>? body,
            String? token,
          }) async => (status: 503, body: <String, Object?>{}),
    );
    addTearDown(catalogue.dispose);
    expect(catalogue.rows, isEmpty);
    expect(catalogue.managedProvider, isNull);
  });
}
