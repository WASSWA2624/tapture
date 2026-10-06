import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/backend/server_ai_catalogue.dart';
import 'package:tapture/core/backend/server_credential_client.dart';
import 'package:tapture/core/errors/result.dart';

void main() {
  test(
    'personal key travels only to save and deletion never retrieves it',
    () async {
      final List<({String method, String path, Map<String, Object?>? body})>
      calls = <({String method, String path, Map<String, Object?>? body})>[];
      final ServerCredentialClient client = ServerCredentialClient(
        send:
            ({
              required String method,
              required String path,
              Map<String, Object?>? body,
              String? token,
            }) async {
              calls.add((method: method, path: path, body: body));
              return (
                status: method == 'DELETE' ? 204 : 200,
                body: <String, Object?>{
                  'provider': 'gemini',
                  'configured': true,
                },
              );
            },
      );
      expect(
        await client.save('gemini', 'personal-secret-fixture'),
        isA<Success<void>>(),
      );
      expect(
        (await client.configured('gemini') as Success<bool>).value,
        isTrue,
      );
      expect(await client.remove('gemini'), isA<Success<void>>());
      expect(calls.map((call) => call.method), <String>[
        'PUT',
        'GET',
        'DELETE',
      ]);
      expect(calls.first.body, <String, Object?>{
        'apiKey': 'personal-secret-fixture',
      });
      expect(calls.skip(1).every((call) => call.body == null), isTrue);
    },
  );

  test(
    'catalogue caches only allowed metadata and survives unavailable refresh',
    () async {
      var available = true;
      List<Map<String, Object?>>? saved;
      final ServerAiCatalogue catalogue = ServerAiCatalogue(
        send:
            ({
              required String method,
              required String path,
              Map<String, Object?>? body,
              String? token,
            }) async => (
              status: available ? 200 : 503,
              body: <String, Object?>{
                'providers': <Object?>[
                  <String, Object?>{
                    'provider': 'gemini',
                    'model': 'base',
                    'models': <String>['base', 'escalated'],
                    'requestCostCeiling': 0.02,
                    'modelCostCeilings': <String, Object?>{
                      'base': 0.02,
                      'escalated': 0.1,
                      'never-enabled': 100,
                    },
                    'managed': true,
                    'apiKey': 'never-cache-me',
                    'personalConfigured': true,
                  },
                ],
              },
            ),
        writeSnapshot: (List<Map<String, Object?>> rows) async {
          saved = rows;
        },
      );
      expect(await catalogue.refresh(), isA<Success<void>>());
      expect(saved.toString(), isNot(contains('never-cache-me')));
      expect(saved.toString(), isNot(contains('personalConfigured')));
      expect(catalogue.models(null).map((model) => model.id), <String>[
        'default',
        'escalated',
      ]);
      expect(catalogue.cost(null, 'default')?.amount, 0.02);
      expect(catalogue.cost('gemini', 'escalated')?.amount, 0.1);
      expect(catalogue.cost('gemini', 'never-enabled'), isNull);
      available = false;
      expect(await catalogue.refresh(), isA<FailureResult<void>>());
      expect(catalogue.models(null).last.id, 'escalated');
    },
  );
}
