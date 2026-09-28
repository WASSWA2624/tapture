import 'dart:async';

import 'package:tapture/core/ai/ai_service.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';

/// [AiService] that calls the organisation proxy. A fresh install holds no key.
final class ProxyAiService implements AiService {
  /// Creates a proxy. An empty [baseUrl] cannot call.
  const ProxyAiService({required this.baseUrl, required this.send, this.log});

  /// A proxy with no server configured. Calls queue; they do not discard input.
  ProxyAiService.unconfigured()
    : baseUrl = '',
      send = _unconfiguredSend,
      log = null;

  /// Server address. Empty means this device is not enrolled.
  final String baseUrl;

  /// Transport.
  final ProxySend send;

  /// Optional log of status lines. Payloads are never written here.
  final void Function(String line)? log;

  static Future<({int status, String body})> _unconfiguredSend({
    required String path,
    required Map<String, Object?> json,
  }) async {
    return (status: 503, body: '');
  }

  @override
  bool get isAvailable => baseUrl.isNotEmpty;

  @override
  Future<Result<ReadTextResult>> readText(ReadTextRequest request) {
    return _call(
      path: '/api/v1/ai/ocr',
      json: <String, Object?>{'images': request.imagePaths.length},
      ok: (String text) => ReadTextResult(text: text),
    );
  }

  @override
  Future<Result<ExtractFieldsResult>> extractFields(
    ExtractFieldsRequest request,
  ) {
    return _call(
      path: '/api/v1/ai/extract',
      json: <String, Object?>{'fields': request.fieldLabels.length},
      ok: (String text) =>
          ExtractFieldsResult(fields: <String, String?>{'text': text}),
    );
  }

  @override
  Future<Result<RefineTextResult>> refineText(RefineTextRequest request) {
    return _call(
      path: '/api/v1/ai/refine',
      json: <String, Object?>{'chars': request.raw.length},
      ok: (String text) => RefineTextResult(text: text),
    );
  }

  @override
  Future<Result<TranscribeResult>> transcribe(TranscribeRequest request) {
    return _call(
      path: '/api/v1/ai/transcribe',
      json: <String, Object?>{'language': request.languageCode},
      ok: (String text) => TranscribeResult(text: text),
    );
  }

  Future<Result<T>> _call<T>({
    required String path,
    required Map<String, Object?> json,
    required T Function(String text) ok,
  }) async {
    if (!isAvailable) return FailureResult<T>(_queued);
    try {
      final ({int status, String body}) response = await send(
        path: path,
        json: json,
      ).timeout(AppConstants.backend.proxyTimeout);
      log?.call('proxy $path ${response.status}');
      if (response.status == 200) {
        return Success<T>(ok(_redact(response.body)));
      }
      return FailureResult<T>(_failure(response.status));
    } on TimeoutException {
      log?.call('proxy $path timeout');
      return FailureResult<T>(_queued);
    }
  }

  static const ProviderFailure _queued = ProviderFailure(
    message: 'Analysis can wait.',
    recoveryAction: 'Continue capturing. Analysis can wait.',
    kind: ProviderFailureKind.unavailable,
  );

  ProviderFailure _failure(int status) {
    if (status == 429) {
      return const ProviderFailure(
        message: 'The analysis quota is used up.',
        recoveryAction: 'Continue capturing. Analysis can wait.',
        kind: ProviderFailureKind.rateLimited,
      );
    }
    return _queued;
  }

  String _redact(String value) {
    return value.replaceAll(RegExp(r'sk-[A-Za-z0-9]+|AKIA[A-Z0-9]{8,}'), '');
  }
}

/// One proxy HTTP call. Nothing here is written to disk.
typedef ProxySend =
    Future<({int status, String body})> Function({
      required String path,
      required Map<String, Object?> json,
    });
