import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:tapture/core/concurrency/cancellation_token.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/time/clock.dart';

import 'cloud_destination.dart';

/// An S3-compatible bucket. Requests are signed for the configured endpoint,
/// so a non-AWS store works. Large files go as multipart parts.
final class S3Destination implements CloudDestination {
  /// Creates the backend. [readSecret] is called on every check and send.
  S3Destination({
    required this.transport,
    required this.readSecret,
    this.clock = const SystemClock(),
    int? partBytes,
  }) : _partBytes = partBytes ?? AppConstants.cloudUpload.partBytes;

  /// Transport that carries signed requests.
  final CloudSend transport;

  /// Reads the bucket credential on every call.
  final SecretRead readSecret;

  /// Clock used for the signature timestamp.
  final Clock clock;

  final int _partBytes;

  @override
  DestinationKind get kind => DestinationKind.s3;

  @override
  Future<Result<void>> check(Destination destination) async {
    final Result<_S3Config> config = await _config(destination);
    if (config is FailureResult<_S3Config>) {
      return FailureResult<void>(config.failure);
    }
    final _S3Config ready = (config as Success<_S3Config>).value;
    final String key = _key(ready, '.tapture-check');
    final Result<CloudReply> put = await _signed(
      ready,
      method: 'PUT',
      key: key,
      body: utf8.encode('ok'),
    );
    if (put is FailureResult<CloudReply>) {
      return FailureResult<void>(put.failure);
    }
    final CloudReply created = (put as Success<CloudReply>).value;
    if (created.status < 200 || created.status >= 300) {
      return FailureResult<void>(cloudStatusFailure(created.status));
    }
    final Result<CloudReply> removed = await _signed(
      ready,
      method: 'DELETE',
      key: key,
      body: const <int>[],
    );
    if (removed is FailureResult<CloudReply>) {
      return FailureResult<void>(removed.failure);
    }
    final CloudReply deleted = (removed as Success<CloudReply>).value;
    if (deleted.status >= 300 && deleted.status != 404) {
      return FailureResult<void>(cloudStatusFailure(deleted.status));
    }
    return const Success<void>(null);
  }

  @override
  Future<Result<Uri>> send(
    Destination destination,
    CloudBytes file, {
    required String remoteName,
    int offset = 0,
    void Function(int sent, int total)? onProgress,
    CancellationToken? cancel,
  }) async {
    if (cancel?.isCancelled ?? false) {
      return const FailureResult<Uri>(CancelledFailure());
    }
    final Result<_S3Config> config = await _config(destination);
    if (config is FailureResult<_S3Config>) {
      return FailureResult<Uri>(config.failure);
    }
    final _S3Config ready = (config as Success<_S3Config>).value;
    final String key = _key(ready, remoteName);
    final Uri object = _url(ready, key);
    if (file.length <= _partBytes) {
      return _one(ready, key, object, file, offset, onProgress, cancel);
    }
    return _multipart(ready, key, object, file, offset, onProgress, cancel);
  }

  Future<Result<Uri>> _one(
    _S3Config ready,
    String key,
    Uri object,
    CloudBytes file,
    int offset,
    void Function(int sent, int total)? onProgress,
    CancellationToken? cancel,
  ) async {
    if (cancel?.isCancelled ?? false) {
      return const FailureResult<Uri>(CancelledFailure());
    }
    final int start = offset.clamp(0, file.length);
    final List<int> body = start >= file.length
        ? const <int>[]
        : await file.read(start, file.length - start);
    final Result<CloudReply> put = await _signed(
      ready,
      method: 'PUT',
      key: key,
      body: body,
    );
    if (put is FailureResult<CloudReply>) {
      return FailureResult<Uri>(put.failure);
    }
    final CloudReply reply = (put as Success<CloudReply>).value;
    if (reply.status < 200 || reply.status >= 300) {
      return FailureResult<Uri>(cloudStatusFailure(reply.status));
    }
    onProgress?.call(file.length, file.length);
    return Success<Uri>(object);
  }

  Future<Result<Uri>> _multipart(
    _S3Config ready,
    String key,
    Uri object,
    CloudBytes file,
    int offset,
    void Function(int sent, int total)? onProgress,
    CancellationToken? cancel,
  ) async {
    final Result<String> upload = await _begin(ready, key);
    if (upload is FailureResult<String>) {
      return FailureResult<Uri>(upload.failure);
    }
    final String uploadId = (upload as Success<String>).value;
    final List<({int number, String tag})> parts =
        <({int number, String tag})>[];
    var cursor = offset.clamp(0, file.length);
    var number = (cursor ~/ _partBytes) + 1;
    while (cursor < file.length) {
      if (cancel?.isCancelled ?? false) {
        await _abort(ready, key, uploadId);
        return const FailureResult<Uri>(CancelledFailure());
      }
      final int count = _partBytes < file.length - cursor
          ? _partBytes
          : file.length - cursor;
      final List<int> chunk = await file.read(cursor, count);
      final Result<CloudReply> part = await _signed(
        ready,
        method: 'PUT',
        key: key,
        query: <String, String>{'partNumber': '$number', 'uploadId': uploadId},
        body: chunk,
      );
      if (part is FailureResult<CloudReply>) {
        await _abort(ready, key, uploadId);
        return FailureResult<Uri>(part.failure);
      }
      final CloudReply reply = (part as Success<CloudReply>).value;
      if (reply.status < 200 || reply.status >= 300) {
        await _abort(ready, key, uploadId);
        return FailureResult<Uri>(cloudStatusFailure(reply.status));
      }
      parts.add((
        number: number,
        tag: reply.headers['etag'] ?? '"part-$number"',
      ));
      cursor += chunk.length;
      number += 1;
      onProgress?.call(cursor, file.length);
    }
    final String xml = _completeXml(parts);
    final Result<CloudReply> done = await _signed(
      ready,
      method: 'POST',
      key: key,
      query: <String, String>{'uploadId': uploadId},
      body: utf8.encode(xml),
    );
    if (done is FailureResult<CloudReply>) {
      await _abort(ready, key, uploadId);
      return FailureResult<Uri>(done.failure);
    }
    final CloudReply finished = (done as Success<CloudReply>).value;
    if (finished.status < 200 || finished.status >= 300) {
      await _abort(ready, key, uploadId);
      return FailureResult<Uri>(cloudStatusFailure(finished.status));
    }
    return Success<Uri>(object);
  }

  Future<Result<String>> _begin(_S3Config ready, String key) async {
    final Result<CloudReply> reply = await _signed(
      ready,
      method: 'POST',
      key: key,
      query: const <String, String>{'uploads': ''},
      body: const <int>[],
    );
    if (reply is FailureResult<CloudReply>) {
      return FailureResult<String>(reply.failure);
    }
    final CloudReply created = (reply as Success<CloudReply>).value;
    if (created.status < 200 || created.status >= 300) {
      return FailureResult<String>(cloudStatusFailure(created.status));
    }
    final String body = utf8.decode(created.body);
    final RegExpMatch? match = RegExp(
      r'<UploadId>([^<]+)</UploadId>',
    ).firstMatch(body);
    final String? id = match?.group(1);
    if (id == null || id.isEmpty) {
      return const FailureResult<String>(
        ValidationFailure(
          message: 'The destination did not start the upload.',
          recoveryAction: 'Try the connection again.',
        ),
      );
    }
    return Success<String>(id);
  }

  Future<void> _abort(_S3Config ready, String key, String uploadId) async {
    await _signed(
      ready,
      method: 'DELETE',
      key: key,
      query: <String, String>{'uploadId': uploadId},
      body: const <int>[],
    );
  }

  Future<Result<_S3Config>> _config(Destination destination) async {
    final String? raw = await readSecret(destination.credentialRef);
    if (raw == null || raw.isEmpty) {
      return const FailureResult<_S3Config>(
        PermissionFailure(
          message: 'This destination has no saved sign-in.',
          recoveryAction: 'Enter the keys and test the connection.',
        ),
      );
    }
    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return const FailureResult<_S3Config>(
          ValidationFailure(
            message: 'The saved sign-in is not usable.',
            recoveryAction: 'Enter the keys again.',
          ),
        );
      }
      final String accessKey = '${decoded['accessKey'] ?? ''}';
      final String secret = '${decoded['secret'] ?? ''}';
      final String region = '${decoded['region'] ?? ''}';
      final String bucket = '${decoded['bucket'] ?? ''}';
      if (accessKey.isEmpty ||
          secret.isEmpty ||
          region.isEmpty ||
          bucket.isEmpty) {
        return const FailureResult<_S3Config>(
          ValidationFailure(
            message: 'The bucket settings are incomplete.',
            recoveryAction: 'Enter the key, region and bucket.',
          ),
        );
      }
      final String endpoint = '${decoded['endpoint'] ?? ''}';
      final String prefix = '${decoded['prefix'] ?? destination.folder}';
      return Success<_S3Config>((
        accessKey: accessKey,
        secret: secret,
        region: region,
        bucket: bucket,
        endpoint: endpoint,
        prefix: prefix,
      ));
    } on FormatException {
      return const FailureResult<_S3Config>(
        ValidationFailure(
          message: 'The saved sign-in is not usable.',
          recoveryAction: 'Enter the keys again.',
        ),
      );
    }
  }

  Future<Result<CloudReply>> _signed(
    _S3Config ready, {
    required String method,
    required String key,
    Map<String, String> query = const <String, String>{},
    required List<int> body,
  }) async {
    final DateTime now = clock.nowUtc();
    final String amz = _amz(now);
    final String date = amz.substring(0, 8);
    final Uri url = _url(ready, key, query);
    final String payload = sha256.convert(body).toString();
    final Map<String, String> headers = <String, String>{
      'host': url.host,
      'x-amz-content-sha256': payload,
      'x-amz-date': amz,
    };
    final String signedHeaders = (headers.keys.toList()..sort()).join(';');
    final String canonicalHeaders = (headers.keys.toList()..sort())
        .map((String name) => '$name:${headers[name]}\n')
        .join();
    final String canonical = <String>[
      method,
      url.path,
      _query(url),
      canonicalHeaders,
      signedHeaders,
      payload,
    ].join('\n');
    final String scope = '$date/${ready.region}/s3/aws4_request';
    final String toSign = <String>[
      'AWS4-HMAC-SHA256',
      amz,
      scope,
      sha256.convert(utf8.encode(canonical)).toString(),
    ].join('\n');
    final String signature = _signature(
      ready.secret,
      date,
      ready.region,
      toSign,
    );
    headers['authorization'] =
        'AWS4-HMAC-SHA256 Credential=${ready.accessKey}/$scope, '
        'SignedHeaders=$signedHeaders, Signature=$signature';
    try {
      final CloudReply reply = await transport((
        method: method,
        url: url,
        headers: headers,
        body: body,
      ));
      return Success<CloudReply>((
        status: reply.status,
        headers: <String, String>{
          for (final MapEntry<String, String> entry in reply.headers.entries)
            entry.key.toLowerCase(): entry.value,
        },
        body: reply.body,
      ));
    } on Object {
      return const FailureResult<CloudReply>(
        NetworkFailure(
          message: 'The destination could not be reached.',
          recoveryAction: 'Try again when you are online.',
        ),
      );
    }
  }

  Uri _url(
    _S3Config ready,
    String key, [
    Map<String, String> query = const <String, String>{},
  ]) {
    final Uri base = ready.endpoint.isEmpty
        ? Uri.https('${ready.bucket}.s3.${ready.region}.amazonaws.com', '/$key')
        : Uri.parse(ready.endpoint).replace(path: '/${ready.bucket}/$key');
    return base.replace(queryParameters: query.isEmpty ? null : query);
  }

  String _key(_S3Config ready, String name) {
    final String prefix = ready.prefix.replaceAll(RegExp(r'^/+|/+$'), '');
    if (prefix.isEmpty) {
      return name;
    }
    return '$prefix/$name';
  }

  String _query(Uri url) {
    final List<String> pairs = <String>[];
    url.queryParameters.forEach((String key, String value) {
      pairs.add(
        '${Uri.encodeQueryComponent(key)}=${Uri.encodeQueryComponent(value)}',
      );
    });
    pairs.sort();
    return pairs.join('&');
  }

  String _amz(DateTime time) {
    final DateTime utc = time.toUtc();
    String two(int value) => value.toString().padLeft(2, '0');
    return '${utc.year}${two(utc.month)}${two(utc.day)}'
        'T${two(utc.hour)}${two(utc.minute)}${two(utc.second)}Z';
  }

  String _signature(String secret, String date, String region, String toSign) {
    List<int> hmac(List<int> key, String data) {
      return Hmac(sha256, key).convert(utf8.encode(data)).bytes;
    }

    final List<int> dateKey = hmac(utf8.encode('AWS4$secret'), date);
    final List<int> regionKey = hmac(dateKey, region);
    final List<int> serviceKey = hmac(regionKey, 's3');
    final List<int> signingKey = hmac(serviceKey, 'aws4_request');
    return Hmac(sha256, signingKey).convert(utf8.encode(toSign)).toString();
  }

  String _completeXml(List<({int number, String tag})> parts) {
    final StringBuffer buffer = StringBuffer('<CompleteMultipartUpload>');
    for (final ({int number, String tag}) part in parts) {
      buffer.write(
        '<Part><PartNumber>${part.number}</PartNumber><ETag>${part.tag}</ETag></Part>',
      );
    }
    buffer.write('</CompleteMultipartUpload>');
    return buffer.toString();
  }
}

typedef _S3Config = ({
  String accessKey,
  String secret,
  String region,
  String bucket,
  String endpoint,
  String prefix,
});
