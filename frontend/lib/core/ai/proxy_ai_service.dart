import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import 'package:tapture/core/ai/ai_service.dart';
import 'package:tapture/core/ai/ai_usage.dart';
import 'package:tapture/core/concurrency/cancellation_token.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';

part 'proxy_ai_policy.dart';
part 'proxy_ai_media.dart';

/// Sends the device's structured request through the keyless backend contract.
final class ProxyAiService with _ProxyMedia implements AiService {
  /// The injected reader supplies bytes without sending local file names.
  const ProxyAiService({
    required this.baseUrl,
    required this.send,
    this.projectId = '',
    this.modelId = 'default',
    this.readBytes,
    this.available,
    this.projectAllowed,
    this.log,
    this.sendCancellable,
    this.billingKind = 'managed',
    this.billingProvider,
    this.maxCost,
    this.readMaxCost,
  });

  /// Unconfigured devices keep evidence queued locally.
  ProxyAiService.unconfigured()
    : baseUrl = '',
      send = _unconfiguredSend,
      projectId = '',
      modelId = 'default',
      readBytes = null,
      available = null,
      projectAllowed = null,
      log = null,
      sendCancellable = null,
      billingKind = 'managed',
      billingProvider = null,
      maxCost = null,
      readMaxCost = null;

  /// Configured organisation server. The transport owns its current address.
  final String baseUrl;

  /// Transport returns the server's JSON response envelope.
  final ProxySend send;

  /// Production transport aborts the HTTP request when the job is cancelled.
  final CancellableProxySend? sendCancellable;

  /// Explicit account selection; never changed after a provider refusal.
  final String billingKind;

  /// Configured adapter selected for a personal account, absent for managed.
  final String? billingProvider;

  /// Operator-approved per-request ceiling for an escalated model.
  final double? maxCost;

  /// Reads current explicit spending approval before every dispatch.
  final double? Function()? readMaxCost;

  /// Metadata identifier for server permissions and budget attribution.
  final String projectId;

  /// Provider model selected in existing project settings.
  final String modelId;

  /// Platform file reader; absent readers refuse media rather than omit it.
  @override
  final Future<Result<Uint8List>> Function(String path)? readBytes;

  /// Dynamic authority/offline check performed again before each request.
  final bool Function()? available;

  /// Cached membership/role check for a project-scoped call.
  final bool Function(String projectId)? projectAllowed;

  /// Optional metadata-only observer. Never receives request/response content.
  final void Function(String line)? log;

  /// Binds the same implementation to the project's permission and model scope.
  ProxyAiService forProject(String id, {String model = 'default'}) =>
      ProxyAiService(
        baseUrl: baseUrl,
        send: send,
        projectId: id,
        modelId: model,
        readBytes: readBytes,
        available: available,
        projectAllowed: projectAllowed,
        log: log,
        sendCancellable: sendCancellable,
        billingKind: billingKind,
        billingProvider: billingProvider,
        maxCost: maxCost,
        readMaxCost: readMaxCost,
      );

  /// Binds this transport to an explicit server-held billing account.
  ProxyAiService forBilling({
    required String kind,
    String? provider,
    double? approvedCost,
  }) => ProxyAiService(
    baseUrl: baseUrl,
    send: send,
    projectId: projectId,
    modelId: modelId,
    readBytes: readBytes,
    available: available,
    projectAllowed: projectAllowed,
    log: log,
    sendCancellable: sendCancellable,
    billingKind: kind,
    billingProvider: provider,
    maxCost: approvedCost,
    readMaxCost: readMaxCost,
  );

  static Future<({int status, String body})> _unconfiguredSend({
    required String path,
    required Map<String, Object?> json,
  }) async => (status: 503, body: '');

  @override
  bool get isAvailable =>
      (available?.call() ?? baseUrl.isNotEmpty) &&
      (projectAllowed?.call(projectId) ?? true);

  @override
  Future<Result<ReadTextResult>> readText(ReadTextRequest request) => _call(
    operation: 'ocr',
    payload: () async => <String, Object?>{
      'images': await _images(request.imagePaths),
    },
    decode: (String text, String _, Map<String, Object?> _) =>
        ReadTextResult(text: text),
  );

  @override
  Future<Result<ExtractFieldsResult>> extractFields(
    ExtractFieldsRequest request,
  ) => _call(
    operation: 'extract',
    cancel: request.cancellationToken,
    approvedMaxCost: request.approvedMaxCost,
    processing: _processingIdentity(
      request.projectRevision,
      request.recordId,
      request.idempotencyKey,
    ),
    payload: () async => <String, Object?>{
      'template': request.templateLabel,
      'fields': request.fieldLabels,
      'fieldSchema': request.fieldSchema,
      'ocrText': request.ocrText,
      'transcripts': request.transcripts,
      'captions': request.captions,
      'context': request.context,
      'predefinedRows': request.predefinedRows,
      'rules': request.rules,
      'sources': request.sources,
      'images': await _images(request.imagePaths, request.cancellationToken),
      if (request.repairError != null) 'repairError': request.repairError,
    },
    decode: (String text, String model, Map<String, Object?> metadata) {
      return ExtractFieldsResult(
        fields: _fieldValues(
          text,
          request.fieldLabels,
          preserveMalformed: request.projectRevision.isNotEmpty,
        ),
        rawResponse: text,
        provider: metadata['provider'] as String? ?? 'backend',
        model: model,
        promptVersion: 'structured-v2',
        billingKind: metadata['billingKind'] as String? ?? billingKind,
        usage: AiUsage.fromJson(metadata['usage']),
      );
    },
  );

  @override
  Future<Result<RefineTextResult>> refineText(RefineTextRequest request) =>
      _call(
        operation: 'refine',
        cancel: request.cancellationToken,
        approvedMaxCost: request.approvedMaxCost,
        processing: _processingIdentity(
          request.projectRevision,
          request.recordId,
          request.idempotencyKey,
        ),
        payload: () async => <String, Object?>{
          'raw': request.raw,
          'style': request.style.name,
        },
        decode: (String text, String model, Map<String, Object?> metadata) =>
            RefineTextResult(
              text: text,
              rawResponse: text,
              provider: metadata['provider'] as String? ?? 'backend',
              model: model,
              promptVersion: 'structured-v1',
              billingKind: metadata['billingKind'] as String? ?? billingKind,
              usage: AiUsage.fromJson(metadata['usage']),
            ),
      );

  @override
  Future<Result<TranscribeResult>> transcribe(TranscribeRequest request) =>
      _call(
        operation: 'transcribe',
        cancel: request.cancellationToken,
        approvedMaxCost: request.approvedMaxCost,
        processing: _processingIdentity(
          request.projectRevision,
          request.recordId,
          request.idempotencyKey,
        ),
        payload: () async => <String, Object?>{
          'audio': await _media(request.clipPath, request.cancellationToken),
          'language': request.languageCode,
        },
        decode: (String text, String model, Map<String, Object?> metadata) =>
            TranscribeResult(
              text: text,
              provider: metadata['provider'] as String? ?? 'backend',
              model: model,
              billingKind: metadata['billingKind'] as String? ?? billingKind,
              usage: AiUsage.fromJson(metadata['usage']),
            ),
      );

  Future<Result<T>> _call<T>({
    required String operation,
    required Future<Map<String, Object?>> Function() payload,
    required T Function(
      String text,
      String model,
      Map<String, Object?> metadata,
    )
    decode,
    CancellationToken? cancel,
    Map<String, Object?>? processing,
    double? approvedMaxCost,
  }) async {
    if (!isAvailable) return FailureResult<T>(_queued);
    final String path = '/api/v1/ai/$operation';
    try {
      _checkCancelled(cancel);
      // Freeze approval before media I/O. Zero authorizes only the configured
      // base model; the server refuses escalation without a positive ceiling.
      final double? approvedCost =
          approvedMaxCost ?? readMaxCost?.call() ?? maxCost;
      if (approvedCost != null &&
          (!approvedCost.isFinite || approvedCost < 0)) {
        return FailureResult<T>(_failure(400, ''));
      }
      final Map<String, Object?> content = await payload();
      _checkCancelled(cancel);
      if (!isAvailable) return FailureResult<T>(_queued);
      final List<Object?> media = <Object?>[
        if (content['images'] case final List<Object?> images) ...images,
        if (content['audio'] != null) content['audio'],
      ];
      final Map<String, Object?> data = Map<String, Object?>.of(content)
        ..remove('images')
        ..remove('audio');
      // The envelope travels as plain JSON so media is base64-encoded once.
      final Map<String, Object?> envelope = <String, Object?>{
        'instructions': _instructions(operation),
        'data': data,
        'media': media,
        'responseMimeType': operation == 'extract'
            ? 'application/json'
            : 'text/plain',
      };
      final Map<String, Object?> json = <String, Object?>{
        'projectId': projectId,
        'model': modelId,
        // Exact serialized bytes bind the receipt across Dart/JS number encoders.
        'payload': processing == null
            ? envelope
            : base64Encode(utf8.encode(jsonEncode(envelope))),
        if (processing != null)
          'processing': <String, Object?>{
            ...processing,
            'requestHash': sha256
                .convert(utf8.encode(jsonEncode(envelope)))
                .toString(),
          },
        if (billingProvider != null)
          'billing': <String, Object?>{
            'kind': billingKind,
            'provider': billingProvider,
          },
        if (approvedCost case final double cost when cost > 0) 'maxCost': cost,
      };
      final Future<({int status, String body})> pending =
          (sendCancellable == null
                  ? send(path: path, json: json)
                  : sendCancellable!(
                      path: path,
                      json: json,
                      cancellationToken: cancel,
                    ))
              .timeout(AppConstants.backend.proxyTimeout);
      final response =
          await (cancel?.race(
                pending,
                onCancel: () => throw const CancelledFailure(),
              ) ??
              pending);
      // Versioned workers save a received reply before checking cancellation.
      // A cancellation that wins the transport race still aborts above.
      if (processing == null) _checkCancelled(cancel);
      log?.call('proxy $path ${response.status}');
      if (response.status != 200) {
        return FailureResult<T>(_failure(response.status, response.body));
      }
      final Object? decoded = jsonDecode(response.body);
      if (decoded is! Map<String, Object?> ||
          decoded['text'] is! String ||
          decoded['model'] is! String ||
          (decoded['provider'] != null && decoded['provider'] is! String) ||
          (decoded['billingKind'] != null &&
              decoded['billingKind'] is! String)) {
        throw const FormatException();
      }
      final String text = decoded['text']! as String;
      // Reject credentials in full; redaction must not silently change evidence.
      if (_leakedCredential.hasMatch(text)) {
        throw const FormatException();
      }
      return Success<T>(decode(text, decoded['model']! as String, decoded));
    } on FormatException {
      return FailureResult<T>(
        ProviderFailure(
          localizedMessage:
              Copy.messages.failureTheAnalysisResponseCouldNotBeRead,
          localizedRecovery: Copy.messages.failureKeepTheRecordAndTryAgain,
          kind: ProviderFailureKind.malformed,
        ),
      );
    } on Failure catch (failure) {
      return FailureResult<T>(failure);
    } on Object {
      log?.call('proxy $path unavailable');
      return FailureResult<T>(_queued);
    }
  }
}

/// A single proxy HTTP call. Request and response content stay out of logs.
typedef ProxySend =
    Future<({int status, String body})> Function({
      required String path,
      required Map<String, Object?> json,
    });

/// A proxy call that can close its underlying HTTP connection on cancellation.
typedef CancellableProxySend =
    Future<({int status, String body})> Function({
      required String path,
      required Map<String, Object?> json,
      CancellationToken? cancellationToken,
    });
