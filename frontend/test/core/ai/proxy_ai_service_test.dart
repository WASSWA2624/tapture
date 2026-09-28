import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/ai/ai_service.dart';
import 'package:tapture/core/ai/provider_registry.dart';
import 'package:tapture/core/ai/proxy_ai_service.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';

void main() {
  test('a fresh install resolves the proxy and holds no key', () async {
    final ProviderRegistry registry = ProviderRegistry.keyless();
    final AiService service = registry.resolve(
      projectId: 'project-1',
      operation: AiOperation.extractFields,
    );
    expect(service, isA<ProxyAiService>());
    expect(service.isAvailable, isFalse);
    const ExtractFieldsRequest request = ExtractFieldsRequest(
      templateLabel: 'Visit',
      fieldLabels: <String>['Name'],
      ocrText: 'Ada',
      transcripts: <String>[],
      captions: <String>['caption stays'],
      imagePaths: <String>['photo.jpg'],
    );
    final Result<ExtractFieldsResult> result = await service.extractFields(
      request,
    );
    expect(result, isA<FailureResult<ExtractFieldsResult>>());
    expect(request.imagePaths, <String>['photo.jpg']);
    expect(request.captions, <String>['caption stays']);
  });

  test(
    'timeout, quota and an open breaker queue without dropping input',
    () async {
      final List<String> lines = <String>[];
      Future<Result<ReadTextResult>> call(int status) {
        final ProxyAiService proxy = ProxyAiService(
          baseUrl: 'https://org.example',
          log: lines.add,
          send:
              ({
                required String path,
                required Map<String, Object?> json,
              }) async {
                if (status == 0) {
                  throw TimeoutException('slow');
                }
                return (status: status, body: 'sk-abcdefghijklmnop');
              },
        );
        return proxy.readText(
          const ReadTextRequest(imagePaths: <String>['photo.jpg']),
        );
      }

      final Result<ReadTextResult> timeout = await call(0);
      final Result<ReadTextResult> quota = await call(429);
      final Result<ReadTextResult> open = await call(503);
      expect(timeout, isA<FailureResult<ReadTextResult>>());
      expect(quota, isA<FailureResult<ReadTextResult>>());
      expect(open, isA<FailureResult<ReadTextResult>>());
      final Failure quotaFailure =
          (quota as FailureResult<ReadTextResult>).failure;
      expect(
        (quotaFailure as ProviderFailure).kind,
        ProviderFailureKind.rateLimited,
      );
      expect(lines.join('\n').contains('sk-'), isFalse);
      expect(lines.join('\n').contains('photo.jpg'), isFalse);

      final ProxyAiService ok = ProxyAiService(
        baseUrl: 'https://org.example',
        log: lines.add,
        send:
            ({required String path, required Map<String, Object?> json}) async {
              return (status: 200, body: 'Ada sk-abcdefghijklmnop');
            },
      );
      final Result<ReadTextResult> read = await ok.readText(
        const ReadTextRequest(imagePaths: <String>['photo.jpg']),
      );
      final String text = (read as Success<ReadTextResult>).value.text;
      expect(text.contains('sk-'), isFalse);
      expect(text.contains('Ada'), isTrue);
    },
  );
}
