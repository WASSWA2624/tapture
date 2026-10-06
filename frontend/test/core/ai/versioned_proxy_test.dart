import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/ai/ai_service.dart';
import 'package:tapture/core/ai/proxy_ai_service.dart';
import 'package:tapture/core/concurrency/cancellation_token.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';

void main() {
  test(
    'versioned payload binds exact bytes, source links, billing and usage',
    () async {
      Map<String, Object?>? sent;
      final ProxyAiService service = ProxyAiService(
        baseUrl: 'https://organisation.test',
        projectId: 'project',
        readBytes: (String _) async =>
            Success<Uint8List>(Uint8List.fromList(<int>[1, 2, 3])),
        send: ({required String path, required Map<String, Object?> json}) async {
          sent = json;
          return (
            status: 200,
            body: jsonEncode(<String, Object?>{
              'text':
                  '{"fields":{"serial":{"value":"0007","confidence":0.8,"evidence":["caption:c"]}}}',
              'model': 'enabled-cheap',
              'provider': 'gemini',
              'billingKind': 'personal',
              'usage': <String, Object?>{
                'inputTokens': 11,
                'outputTokens': 5,
                'totalTokens': 16,
                'reservedCost': 0.1,
                'currency': 'configured',
              },
            }),
          );
        },
      ).forBilling(kind: 'personal', provider: 'gemini', approvedCost: 0.2);
      final Result<ExtractFieldsResult> result = await service.extractFields(
        _request(
          sources: <Map<String, Object?>>[
            <String, Object?>{
              'id': 'photo:p',
              'kind': 'photo',
              'photoId': 'p',
              'imageIndex': 0,
            },
            <String, Object?>{
              'id': 'caption:c',
              'kind': 'caption',
              'photoId': 'p',
              'text': 'Serial 0007',
              'sourceWeight': 1.0,
            },
          ],
          images: <String>['private/original-derived.jpg'],
        ),
      );
      final Map<String, Object?> processing =
          sent!['processing']! as Map<String, Object?>;
      final List<int> bytes = base64Decode(sent!['payload']! as String);
      expect(processing['requestHash'], sha256.convert(bytes).toString());
      expect(processing['projectRevision'], 'a' * 64);
      expect(processing['recordId'], 'record');
      expect(sent!['billing'], <String, Object?>{
        'kind': 'personal',
        'provider': 'gemini',
      });
      expect(sent!['maxCost'], 0.2);
      final Map<String, Object?> envelope =
          jsonDecode(utf8.decode(bytes)) as Map<String, Object?>;
      expect(
        (envelope['data']! as Map<String, Object?>)['sources'],
        hasLength(2),
      );
      expect(utf8.decode(bytes), isNot(contains('private/')));
      final ExtractFieldsResult extracted =
          (result as Success<ExtractFieldsResult>).value;
      expect(extracted.fields['serial'], '0007');
      expect(extracted.provider, 'gemini');
      expect(extracted.billingKind, 'personal');
      expect(extracted.usage!.totalTokens, 16);
      expect(extracted.usage!.reservedCost, 0.1);
    },
  );

  test('cancellation during media read prevents provider dispatch', () async {
    final CancellationToken cancel = CancellationToken();
    final Completer<Result<Uint8List>> media = Completer<Result<Uint8List>>();
    var calls = 0;
    final ProxyAiService service = ProxyAiService(
      baseUrl: 'https://organisation.test',
      readBytes: (String _) => media.future,
      send: ({required String path, required Map<String, Object?> json}) async {
        calls++;
        return (status: 200, body: '{}');
      },
    );
    final Future<Result<ExtractFieldsResult>> pending = service.extractFields(
      _request(cancel: cancel, images: <String>['derived.jpg']),
    );
    cancel.cancel();
    media.complete(Success<Uint8List>(Uint8List(1)));
    final Result<ExtractFieldsResult> result = await pending;
    expect(
      (result as FailureResult<ExtractFieldsResult>).failure,
      isA<CancelledFailure>(),
    );
    expect(calls, 0);
    expect(cancel.debugListenerCount, 0);
  });

  test(
    'a received versioned reply survives cancellation before local storage',
    () async {
      final CancellationToken cancel = CancellationToken();
      final Completer<void> dispatched = Completer<void>();
      final Completer<({int status, String body})> reply =
          Completer<({int status, String body})>();
      final ProxyAiService service = ProxyAiService(
        baseUrl: 'https://organisation.test',
        log: (String _) => cancel.cancel(),
        send: ({required String path, required Map<String, Object?> json}) {
          dispatched.complete();
          return reply.future;
        },
      );
      final Future<Result<ExtractFieldsResult>> pending = service.extractFields(
        _request(cancel: cancel),
      );
      await dispatched.future;
      reply.complete((
        status: 200,
        body:
            '{"text":"{\\"fields\\":{}}","model":"cheap","usage":{"totalTokens":12,"reservedCost":0.002,"currency":"configured"}}',
      ));
      final ExtractFieldsResult result =
          (await pending as Success<ExtractFieldsResult>).value;
      expect(cancel.isCancelled, isTrue);
      expect(result.rawResponse, '{"fields":{}}');
      expect(result.usage!.totalTokens, 12);
      expect(cancel.debugListenerCount, 0);
    },
  );

  test(
    'auxiliary calls carry versioned identities and attributable usage',
    () async {
      final List<Map<String, Object?>> calls = <Map<String, Object?>>[];
      final ProxyAiService service = ProxyAiService(
        baseUrl: 'https://organisation.test',
        projectId: 'project',
        readBytes: (String _) async => Success<Uint8List>(Uint8List(2)),
        send:
            ({required String path, required Map<String, Object?> json}) async {
              calls.add(json);
              return (
                status: 200,
                body: jsonEncode(<String, Object?>{
                  'text': 'Serial 0007',
                  'provider': 'gemini',
                  'model': 'cheap',
                  'billingKind': 'managed',
                  'usage': <String, Object?>{
                    'totalTokens': 12,
                    'reservedCost': 0.02,
                    'currency': 'configured',
                  },
                }),
              );
            },
      );
      final TranscribeResult transcript =
          (await service.transcribe(
                    TranscribeRequest(
                      clipPath: 'local-note.m4a',
                      languageCode: 'en',
                      projectRevision: 'a' * 64,
                      recordId: 'record',
                      idempotencyKey: 'b' * 64,
                    ),
                  )
                  as Success<TranscribeResult>)
              .value;
      final RefineTextResult refined =
          (await service.refineText(
                    RefineTextRequest(
                      raw: 'Serial 0007',
                      style: RefineStyle.caption,
                      projectRevision: 'c' * 64,
                      recordId: 'record',
                      idempotencyKey: 'd' * 64,
                    ),
                  )
                  as Success<RefineTextResult>)
              .value;
      expect(transcript.provider, 'gemini');
      expect(transcript.usage!.totalTokens, 12);
      expect(refined.billingKind, 'managed');
      expect(refined.usage!.reservedCost, 0.02);
      expect(calls, hasLength(2));
      for (final Map<String, Object?> call in calls) {
        final Map<String, Object?> identity =
            call['processing']! as Map<String, Object?>;
        expect(identity['recordId'], 'record');
        expect(
          identity['requestHash'],
          sha256.convert(base64Decode(call['payload']! as String)).toString(),
        );
      }
    },
  );

  test(
    'uncertain receipt stops automatic retries and keeps explicit account',
    () async {
      final List<Map<String, Object?>> sent = <Map<String, Object?>>[];
      final ProxyAiService service = ProxyAiService(
        baseUrl: 'https://organisation.test',
        send:
            ({required String path, required Map<String, Object?> json}) async {
              sent.add(json);
              return (
                status: 409,
                body: '{"error":{"code":"ai_request_uncertain"}}',
              );
            },
      ).forBilling(kind: 'personal', provider: 'openai');
      final Result<ExtractFieldsResult> result = await service.extractFields(
        _request(),
      );
      final ProviderFailure failure =
          (result as FailureResult<ExtractFieldsResult>).failure
              as ProviderFailure;
      expect(failure.kind, ProviderFailureKind.malformed);
      expect(failure.message, contains('charged'));
      expect(sent, hasLength(1));
      expect(sent.single['billing'], <String, Object?>{
        'kind': 'personal',
        'provider': 'openai',
      });
    },
  );

  test('processing approval stays frozen while media is prepared', () async {
    for (final double approved in <double>[0, 0.2]) {
      Map<String, Object?>? sent;
      var approvalReads = 0;
      final ProxyAiService service = ProxyAiService(
        baseUrl: 'https://organisation.test',
        readMaxCost: () {
          approvalReads++;
          return 100;
        },
        readBytes: (String _) async => Success<Uint8List>(Uint8List(1)),
        send:
            ({required String path, required Map<String, Object?> json}) async {
              sent = json;
              return (
                status: 200,
                body: '{"text":"{\\"fields\\":{}}","model":"cheap"}',
              );
            },
      );
      await service.extractFields(
        _request(images: <String>['derived.jpg'], approvedCost: approved),
      );
      expect(approvalReads, 0);
      expect(sent!['maxCost'], approved == 0 ? isNull : approved);
    }
  });

  test(
    'versioned malformed replies retain raw content and usage for repair',
    () async {
      for (final String raw in <String>[
        'unfinished {',
        '{"unexpected":true}',
      ]) {
        final ProxyAiService service = ProxyAiService(
          baseUrl: 'https://organisation.test',
          send:
              ({
                required String path,
                required Map<String, Object?> json,
              }) async => (
                status: 200,
                body: jsonEncode(<String, Object?>{
                  'text': raw,
                  'model': 'cheap',
                  'provider': 'gemini',
                  'usage': <String, Object?>{
                    'totalTokens': 12,
                    'reservedCost': 0.002,
                    'currency': 'configured',
                  },
                }),
              ),
        );
        final ExtractFieldsResult result =
            (await service.extractFields(_request())
                    as Success<ExtractFieldsResult>)
                .value;
        expect(result.rawResponse, raw);
        expect(result.fields, isEmpty);
        expect(result.usage!.totalTokens, 12);
        expect(
          await service.extractFields(_request(versioned: false)),
          isA<FailureResult<ExtractFieldsResult>>(),
        );
      }
    },
  );
}

ExtractFieldsRequest _request({
  List<Map<String, Object?>> sources = const <Map<String, Object?>>[],
  List<String> images = const <String>[],
  CancellationToken? cancel,
  double? approvedCost,
  bool versioned = true,
}) => ExtractFieldsRequest(
  templateLabel: 'Asset',
  fieldLabels: const <String>['serial'],
  ocrText: '',
  transcripts: const <String>[],
  captions: const <String>[],
  imagePaths: images,
  sources: sources,
  projectRevision: versioned ? 'a' * 64 : '',
  recordId: 'record',
  idempotencyKey: 'b' * 64,
  cancellationToken: cancel,
  approvedMaxCost: approvedCost,
);
