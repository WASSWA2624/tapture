import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/ai/ai_service.dart';
import 'package:tapture/core/ai/provider_registry.dart';
import 'package:tapture/core/ai/proxy_ai_service.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/features/processing/domain/job_retry.dart';

import 'ai_service_contract.dart';

void main() {
  runAiServiceContract('the organisation proxy', (ContractOutcome outcome) {
    return ProxyAiService(
      baseUrl: 'https://org.test',
      projectId: 'project',
      send: ({required String path, required Map<String, Object?> json}) async {
        return switch (outcome) {
          ContractOutcome.success => (
            status: 200,
            body: jsonEncode(<String, Object?>{
              'text': contractText,
              'model': 'default',
            }),
          ),
          ContractOutcome.timeout => throw TimeoutException('no answer'),
          ContractOutcome.unavailable => (
            status: 503,
            body: _envelope('unavailable'),
          ),
          ContractOutcome.quota => (
            status: 429,
            body: _envelope('quota_exceeded'),
          ),
          ContractOutcome.breakerOpen => (
            status: 429,
            body: _envelope('rate_limited'),
          ),
          ContractOutcome.malformed => (status: 200, body: 'not json'),
        };
      },
    );
  });

  test(
    'unconfigured backend preserves evidence and reports unavailable',
    () async {
      final AiService service = ProviderRegistry.keyless().resolve(
        projectId: 'p',
        operation: AiOperation.extractFields,
      );
      expect(service.isAvailable, isFalse);
      expect(
        await service.readText(
          const ReadTextRequest(imagePaths: <String>['private.jpg']),
        ),
        isA<FailureResult<ReadTextResult>>(),
      );
    },
  );

  test(
    'real proxy envelope contains evidence bytes, project and model, never paths',
    () async {
      Map<String, Object?>? sent;
      final ProxyAiService service = ProxyAiService(
        baseUrl: 'https://org.test',
        projectId: 'project',
        modelId: 'configured-model',
        readBytes: (String path) async =>
            Success<Uint8List>(Uint8List.fromList(<int>[1, 2, 3])),
        send:
            ({required String path, required Map<String, Object?> json}) async {
              sent = json;
              return (
                status: 200,
                body: jsonEncode(<String, Object?>{
                  'text':
                      '{"fields":{"name":{"value":"Ada","confidence":0.9}}}',
                  'model': 'configured-model',
                }),
              );
            },
      );
      final result = await service.extractFields(
        const ExtractFieldsRequest(
          templateLabel: 'Visit',
          fieldLabels: <String>['name'],
          ocrText: 'Ada',
          transcripts: <String>[],
          captions: <String>['original caption'],
          imagePaths: <String>['private/photo.jpg'],
        ),
      );
      expect(
        (result as Success<ExtractFieldsResult>).value.fields['name'],
        'Ada',
      );
      expect(sent!['projectId'], 'project');
      expect(sent!['model'], 'configured-model');
      final Map<String, Object?> payload =
          sent!['payload']! as Map<String, Object?>;
      final String raw = jsonEncode(sent);
      expect(raw, isNot(contains('private/photo.jpg')));
      expect(payload['instructions'], isA<String>());
      expect(payload['responseMimeType'], 'application/json');
      expect(payload['media'], <Object?>[
        <String, Object?>{'mimeType': 'image/jpeg', 'base64': 'AQID'},
      ]);
      final Map<String, Object?> data =
          payload['data']! as Map<String, Object?>;
      expect(data.containsKey('images'), isFalse);
      expect(data['template'], 'Visit');
      expect(data['captions'], <String>['original caption']);
      expect(data['ocrText'], 'Ada');
    },
  );

  test(
    'media is base64-encoded once, so the request stays near the encoded media size',
    () async {
      final Uint8List bytes = Uint8List(30000);
      final List<Map<String, Object?>> requests = <Map<String, Object?>>[];
      final ProxyAiService service = _service(
        text: 'Visible text',
        bytes: bytes,
        requests: requests,
      );
      final Result<ReadTextResult> result = await service.readText(
        const ReadTextRequest(imagePaths: <String>['analysis/copy.png']),
      );
      expect((result as Success<ReadTextResult>).value.text, 'Visible text');
      final Map<String, Object?> request = requests.single;
      expect(request['payload'], isA<Map<String, Object?>>());
      final Map<String, Object?> payload =
          request['payload']! as Map<String, Object?>;
      final String encodedOnce = base64Encode(bytes);
      expect(payload['media'], <Object?>[
        <String, Object?>{'mimeType': 'image/png', 'base64': encodedOnce},
      ]);
      expect(payload['responseMimeType'], 'text/plain');
      // Encoding the media twice would grow it by a third again (about 53 KB).
      final int wireBytes = utf8.encode(jsonEncode(request)).length;
      expect(wireBytes, lessThan(encodedOnce.length + 2048));
    },
  );

  test(
    'transcription sends the clip once as audio media and the language as data',
    () async {
      final List<Map<String, Object?>> requests = <Map<String, Object?>>[];
      final ProxyAiService service = _service(
        text: 'Spoken words',
        requests: requests,
      );
      final Result<TranscribeResult> result = await service.transcribe(
        const TranscribeRequest(
          clipPath: 'private/clips/note.m4a',
          languageCode: 'en',
        ),
      );
      expect((result as Success<TranscribeResult>).value.text, 'Spoken words');
      final Map<String, Object?> payload =
          requests.single['payload']! as Map<String, Object?>;
      expect(payload['data'], <String, Object?>{'language': 'en'});
      expect(payload['media'], <Object?>[
        <String, Object?>{'mimeType': 'audio/mp4', 'base64': 'AQID'},
      ]);
      expect(jsonEncode(requests.single), isNot(contains('note.m4a')));
    },
  );

  test(
    'timeout, transport errors, quota, malformed and leaked-key results never succeed',
    () async {
      final List<String> logs = <String>[];
      for (final int status in <int>[0, 429, 503, 200]) {
        final ProxyAiService service = ProxyAiService(
          baseUrl: 'https://org.test',
          log: logs.add,
          send:
              ({
                required String path,
                required Map<String, Object?> json,
              }) async {
                if (status == 0) throw TimeoutException('private content');
                return (
                  status: status,
                  body: jsonEncode(<String, Object?>{
                    'text': 'sk-proj-EXAMPLEexampleEXAMPLE0000',
                    'model': 'default',
                  }),
                );
              },
        );
        final result = await service.readText(
          const ReadTextRequest(imagePaths: <String>[]),
        );
        expect(result, isA<FailureResult<ReadTextResult>>());
        if (status == 429) {
          expect(
            ((result as FailureResult<ReadTextResult>).failure
                    as ProviderFailure)
                .kind,
            ProviderFailureKind.rateLimited,
          );
        }
      }
      expect(logs.join(), isNot(contains('sk-')));
      expect(logs.join(), isNot(contains('private content')));
    },
  );

  test('an oversize request is reported once, never retried', () async {
    final ProxyAiService service = _service(text: '', status: 413);
    final Result<ReadTextResult> result = await service.readText(
      const ReadTextRequest(imagePaths: <String>['large.jpg']),
    );
    final Failure failure = (result as FailureResult<ReadTextResult>).failure;
    expect(
      (failure as ProviderFailure).kind,
      ProviderFailureKind.unsupportedMedia,
    );
    expect(JobRetry.classify(failure, attempt: 1).permanent, isTrue);
  });

  test('ordinary hyphenated words are evidence, not leaked keys', () async {
    const String text =
        'risk-assessment, task-management-for-the-whole-district, '
        'disk-encryption-review and desk-reference-materials-list';
    final ProxyAiService reader = _service(text: text);
    final Result<ReadTextResult> read = await reader.readText(
      const ReadTextRequest(imagePaths: <String>[]),
    );
    expect((read as Success<ReadTextResult>).value.text, text);
    const String fields =
        '{"fields":{"summary":{"value":'
        '"risk-assessment-completed-for-every-site","confidence":0.9}}}';
    final ProxyAiService extractor = _service(text: fields);
    final Result<ExtractFieldsResult> result = await extractor.extractFields(
      const ExtractFieldsRequest(
        templateLabel: 'Visit',
        fieldLabels: <String>['summary'],
        ocrText: '',
        transcripts: <String>[],
        captions: <String>[],
        imagePaths: <String>[],
      ),
    );
    expect(
      (result as Success<ExtractFieldsResult>).value.fields['summary'],
      'risk-assessment-completed-for-every-site',
    );
  });

  test('provider key shapes are rejected in full as malformed', () async {
    for (final String text in <String>[
      'sk-EXAMPLEexampleEXAMPLE000000',
      'Key: sk-proj-EXAMPLEexampleEXAMPLE0000',
      'sk-ant-api03-EXAMPLEexampleEXAMPLE',
      'aws AKIAIOSFODNN7EXAMPLE here',
      'AIzaEXAMPLEexampleEXAMPLEexample000',
      '{"token":"sk-EXAMPLEexampleEXAMPLE000000"}',
    ]) {
      final ProxyAiService service = _service(text: text);
      final Result<ReadTextResult> result = await service.readText(
        const ReadTextRequest(imagePaths: <String>[]),
      );
      expect(result, isA<FailureResult<ReadTextResult>>(), reason: text);
      final Failure error = (result as FailureResult<ReadTextResult>).failure;
      expect(
        (error as ProviderFailure).kind,
        ProviderFailureKind.malformed,
        reason: text,
      );
    }
  });
}

/// The server's failure envelope for [code].
String _envelope(String code) {
  return jsonEncode(<String, Object?>{
    'error': <String, Object?>{'code': code, 'message': 'Refused.'},
  });
}

/// A configured proxy whose transport answers [status] with [text].
///
/// Each request body is appended to [requests] when it is supplied.
ProxyAiService _service({
  required String text,
  int status = 200,
  Uint8List? bytes,
  List<Map<String, Object?>>? requests,
}) {
  return ProxyAiService(
    baseUrl: 'https://org.test',
    projectId: 'project',
    readBytes: (String path) async =>
        Success<Uint8List>(bytes ?? Uint8List.fromList(<int>[1, 2, 3])),
    send: ({required String path, required Map<String, Object?> json}) async {
      requests?.add(json);
      return (
        status: status,
        body: jsonEncode(<String, Object?>{'text': text, 'model': 'default'}),
      );
    },
  );
}
