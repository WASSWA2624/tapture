import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:tapture/core/concurrency/cancellation_token.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/time/clock.dart';

import 'cloud_destination.dart';
import 'cloud_probe_name.dart';
import 'cloud_request_scope.dart';
import 'cloud_upload_context.dart';

/// An S3-compatible bucket. Requests are signed for the configured endpoint,
/// so a non-AWS store works. Large files go as multipart parts.
///
/// A multipart upload that stops on a retryable failure stays open on the
/// bucket. A later send with an offset finds it with ListMultipartUploads,
/// asks ListParts which parts the bucket acknowledged, and sends only the
/// rest; when nothing can be resumed it starts again from byte 0. A fatal
/// failure or a cancel aborts the upload, so no partial object is left.
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
    final String key = _key(ready, CloudProbeName.create());
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
      return _one(ready, key, object, file, onProgress, cancel);
    }
    return _multipart(ready, key, object, file, offset, onProgress, cancel);
  }

  /// One PUT of the whole file. A single object cannot be appended to, so a
  /// resume sends every byte again rather than only the tail.
  Future<Result<Uri>> _one(
    _S3Config ready,
    String key,
    Uri object,
    CloudBytes file,
    void Function(int sent, int total)? onProgress,
    CancellationToken? cancel,
  ) async {
    if (cancel?.isCancelled ?? false) {
      return const FailureResult<Uri>(CancelledFailure());
    }
    final List<int> body = file.length == 0
        ? const <int>[]
        : await file.read(0, file.length);
    if (body.length != file.length) {
      return FailureResult<Uri>(cloudReadFailure);
    }
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
    final CloudUploadContext? context = CloudUploadContext.current;
    String? savedId;
    if (context != null) {
      final String? saved = await context.readSession();
      try {
        final Object? session = saved == null ? null : jsonDecode(saved);
        if (session is Map &&
            session['fingerprint'] == context.fingerprint &&
            session['target'] == object.toString() &&
            session['id'] is String) {
          savedId = session['id'] as String;
        }
      } on FormatException {
        // An invalid checkpoint must never authorize reuse of remote parts.
      }
    }
    final _Upload? resumed = (context == null ? offset > 0 : savedId != null)
        ? await _resumable(ready, key, file.length, requiredId: savedId)
        : null;
    final String uploadId;
    final List<_Part> parts;
    if (resumed == null) {
      final Result<String> upload = await _begin(ready, key);
      if (upload is FailureResult<String>) {
        return FailureResult<Uri>(upload.failure);
      }
      uploadId = (upload as Success<String>).value;
      parts = <_Part>[];
    } else {
      uploadId = resumed.id;
      parts = resumed.parts;
    }
    if (context != null) {
      await context.writeSession(
        jsonEncode(<String, String>{
          'fingerprint': context.fingerprint,
          'target': object.toString(),
          'id': uploadId,
        }),
      );
    }
    var cursor = 0;
    for (final _Part part in parts) {
      cursor += part.size;
    }
    if (cursor > 0) {
      onProgress?.call(cursor, file.length);
    }
    while (cursor < file.length) {
      if (cancel?.isCancelled ?? false) {
        await _abort(ready, key, uploadId);
        return const FailureResult<Uri>(CancelledFailure());
      }
      final int number = parts.length + 1;
      final int count = _partBytes < file.length - cursor
          ? _partBytes
          : file.length - cursor;
      final List<int> chunk = await file.read(cursor, count);
      if (chunk.length != count) {
        await _abort(ready, key, uploadId);
        return FailureResult<Uri>(cloudReadFailure);
      }
      final Result<CloudReply> part = await _signed(
        ready,
        method: 'PUT',
        key: key,
        query: <String, String>{'partNumber': '$number', 'uploadId': uploadId},
        body: chunk,
      );
      if (part is FailureResult<CloudReply>) {
        return _stopped(ready, key, uploadId, part.failure);
      }
      final CloudReply reply = (part as Success<CloudReply>).value;
      if (reply.status < 200 || reply.status >= 300) {
        return _stopped(ready, key, uploadId, cloudStatusFailure(reply.status));
      }
      parts.add((
        number: number,
        tag: reply.headers['etag'] ?? '',
        size: chunk.length,
      ));
      cursor += chunk.length;
      if (parts.last.tag.isEmpty) {
        return _stopped(
          ready,
          key,
          uploadId,
          ValidationFailure(
            localizedMessage:
                Copy.messages.failureTheBucketDidNotAcknowledgeTheUploaded,
            localizedRecovery:
                Copy.messages.failureTestTheDestinationAndTryAgain,
          ),
        );
      }
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
      return _stopped(ready, key, uploadId, done.failure);
    }
    final CloudReply finished = (done as Success<CloudReply>).value;
    if (finished.status < 200 || finished.status >= 300) {
      return _stopped(
        ready,
        key,
        uploadId,
        cloudStatusFailure(finished.status),
      );
    }
    final String completed;
    try {
      completed = utf8.decode(finished.body);
    } on FormatException {
      return _stopped(ready, key, uploadId, const ValidationFailure());
    }
    if (_block('Error').hasMatch(completed)) {
      final String? code = _tag(completed, 'Code');
      return _stopped(
        ready,
        key,
        uploadId,
        code == 'InternalError' ||
                code == 'SlowDown' ||
                code == 'ServiceUnavailable'
            ? NetworkFailure(
                localizedMessage:
                    Copy.messages.failureTheBucketDidNotFinishTheUpload,
                localizedRecovery: Copy.messages.failureTryAgain,
              )
            : ValidationFailure(
                localizedMessage:
                    Copy.messages.failureTheBucketRefusedToFinishTheUpload,
                localizedRecovery:
                    Copy.messages.failureTestTheDestinationAndTryAgain,
              ),
      );
    }
    if (!_block('CompleteMultipartUploadResult').hasMatch(completed) ||
        (_tag(completed, 'ETag')?.isEmpty ?? true)) {
      return _stopped(
        ready,
        key,
        uploadId,
        ValidationFailure(
          localizedMessage:
              Copy.messages.failureTheBucketDidNotConfirmTheCompleted,
          localizedRecovery: Copy.messages.failureTestTheDestinationAndTryAgain,
        ),
      );
    }
    return Success<Uri>(object);
  }

  /// Ends a send that failed part-way. A retryable failure keeps the
  /// multipart upload open, so a resume can continue from its acknowledged
  /// parts; a fatal one aborts it.
  Future<Result<Uri>> _stopped(
    _S3Config ready,
    String key,
    String uploadId,
    Failure failure,
  ) async {
    if (!cloudRetryable(failure)) {
      await _abort(ready, key, uploadId);
      await CloudUploadContext.current?.writeSession(null);
    }
    return FailureResult<Uri>(failure);
  }

  /// The newest open multipart upload of [key] and the parts the bucket
  /// acknowledged from part 1 onward, or null when there is none to resume.
  ///
  /// Only an unbroken run of full parts counts, plus a last part that ends
  /// the file exactly; anything else is resent.
  Future<_Upload?> _resumable(
    _S3Config ready,
    String key,
    int length, {
    String? requiredId,
  }) async {
    final Result<CloudReply> listed = await _signed(
      ready,
      method: 'GET',
      key: '',
      query: <String, String>{'uploads': '', 'prefix': key},
      body: const <int>[],
    );
    final String? uploads = _okBody(listed);
    if (uploads == null) {
      return null;
    }
    String? id;
    var newest = '';
    for (final RegExpMatch match in _block('Upload').allMatches(uploads)) {
      final String upload = match.group(1) ?? '';
      if (_tag(upload, 'Key') != key) {
        continue;
      }
      if (requiredId != null && _tag(upload, 'UploadId') != requiredId) {
        continue;
      }
      final String initiated = _tag(upload, 'Initiated') ?? '';
      if (id == null || initiated.compareTo(newest) > 0) {
        id = _tag(upload, 'UploadId');
        newest = initiated;
      }
    }
    if (id == null || id.isEmpty) {
      return null;
    }
    final List<_Part> listedParts = <_Part>[];
    var marker = '';
    for (var page = 0; page < _maxPartPages; page++) {
      final Result<CloudReply> reply = await _signed(
        ready,
        method: 'GET',
        key: key,
        query: <String, String>{
          'uploadId': id,
          if (marker.isNotEmpty) 'part-number-marker': marker,
        },
        body: const <int>[],
      );
      final String? body = _okBody(reply);
      if (body == null) {
        return null;
      }
      for (final RegExpMatch match in _block('Part').allMatches(body)) {
        final String part = match.group(1) ?? '';
        final int? number = int.tryParse(_tag(part, 'PartNumber') ?? '');
        final int? size = int.tryParse(_tag(part, 'Size') ?? '');
        final String tag = _tag(part, 'ETag') ?? '';
        if (number != null && size != null && tag.isNotEmpty) {
          listedParts.add((number: number, tag: tag, size: size));
        }
      }
      marker = _tag(body, 'NextPartNumberMarker') ?? '';
      if (_tag(body, 'IsTruncated') != 'true' || marker.isEmpty) {
        break;
      }
    }
    listedParts.sort((_Part a, _Part b) => a.number.compareTo(b.number));
    final List<_Part> acknowledged = <_Part>[];
    var covered = 0;
    for (final _Part part in listedParts) {
      if (part.number != acknowledged.length + 1) {
        break;
      }
      final bool full =
          part.size == _partBytes && covered + part.size <= length;
      final bool last = covered + part.size == length;
      if (!full && !last) {
        break;
      }
      acknowledged.add(part);
      covered += part.size;
      if (last) {
        break;
      }
    }
    return (id: id, parts: acknowledged);
  }

  /// The body of a 2xx reply as text, or null.
  String? _okBody(Result<CloudReply> reply) {
    return reply.fold((_) => null, (CloudReply value) {
      if (value.status < 200 || value.status >= 300) {
        return null;
      }
      return utf8.decode(value.body, allowMalformed: true);
    });
  }

  RegExp _block(String name) =>
      RegExp('<$name(?:\\s[^>]*)?>(.*?)</$name>', dotAll: true);

  String? _tag(String xml, String name) {
    return RegExp('<$name>([^<]*)</$name>').firstMatch(xml)?.group(1)?.trim();
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
      return FailureResult<String>(
        ValidationFailure(
          localizedMessage:
              Copy.messages.failureTheDestinationDidNotStartTheUpload,
          localizedRecovery: Copy.messages.failureTryTheConnectionAgain,
        ),
      );
    }
    return Success<String>(id);
  }

  Future<void> _abort(_S3Config ready, String key, String uploadId) async {
    await const CloudRequestScope().run(
      () => _signed(
        ready,
        method: 'DELETE',
        key: key,
        query: <String, String>{'uploadId': uploadId},
        body: const <int>[],
      ),
    );
  }

  Future<Result<_S3Config>> _config(Destination destination) async {
    final String? raw = await readSecret(destination.credentialRef);
    if (raw == null || raw.isEmpty) {
      return FailureResult<_S3Config>(
        PermissionFailure(
          localizedMessage:
              Copy.messages.failureThisDestinationHasNoSavedSignIn,
          localizedRecovery:
              Copy.messages.failureEnterTheKeysAndTestTheConnection,
        ),
      );
    }
    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return FailureResult<_S3Config>(
          ValidationFailure(
            localizedMessage: Copy.messages.failureTheSavedSignInIsNotUsable,
            localizedRecovery: Copy.messages.failureEnterTheKeysAgain,
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
        return FailureResult<_S3Config>(
          ValidationFailure(
            localizedMessage:
                Copy.messages.failureTheBucketSettingsAreIncomplete,
            localizedRecovery: Copy.messages.failureEnterTheKeyRegionAndBucket,
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
      return FailureResult<_S3Config>(
        ValidationFailure(
          localizedMessage: Copy.messages.failureTheSavedSignInIsNotUsable,
          localizedRecovery: Copy.messages.failureEnterTheKeysAgain,
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
      'host': url.authority,
      'x-amz-content-sha256': payload,
      'x-amz-date': amz,
    };
    final String signedHeaders = (headers.keys.toList()..sort()).join(';');
    final String canonicalHeaders = (headers.keys.toList()..sort())
        .map((String name) => '$name:${headers[name]}\n')
        .join();
    final String canonical = <String>[
      method,
      '/${url.pathSegments.map(_encode).join('/')}',
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
    } on Failure catch (failure) {
      return FailureResult<CloudReply>(failure);
    } on Object {
      return FailureResult<CloudReply>(
        NetworkFailure(
          localizedMessage:
              Copy.messages.failureTheDestinationCouldNotBeReached,
          localizedRecovery: Copy.messages.failureTryAgainWhenYouAreOnline,
        ),
      );
    }
  }

  Uri _url(
    _S3Config ready,
    String key, [
    Map<String, String> query = const <String, String>{},
  ]) {
    final String path = key.isEmpty ? '' : '/$key';
    final Uri base = ready.endpoint.isEmpty
        ? Uri.https(
            '${ready.bucket}.s3.${ready.region}.amazonaws.com',
            path.isEmpty ? '/' : path,
          )
        : Uri.parse(ready.endpoint).replace(path: '/${ready.bucket}$path');
    final List<String> pairs =
        query.entries
            .map((entry) => '${_encode(entry.key)}=${_encode(entry.value)}')
            .toList()
          ..sort();
    return base.replace(query: pairs.isEmpty ? null : pairs.join('&'));
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
      pairs.add('${_encode(key)}=${_encode(value)}');
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

  String _encode(String value) => utf8
      .encode(value)
      .map(
        (int byte) =>
            (byte >= 65 && byte <= 90) ||
                (byte >= 97 && byte <= 122) ||
                (byte >= 48 && byte <= 57) ||
                byte == 45 ||
                byte == 46 ||
                byte == 95 ||
                byte == 126
            ? String.fromCharCode(byte)
            : '%${byte.toRadixString(16).toUpperCase().padLeft(2, '0')}',
      )
      .join();

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

  String _completeXml(List<_Part> parts) {
    final StringBuffer buffer = StringBuffer('<CompleteMultipartUpload>');
    for (final _Part part in parts) {
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

/// One acknowledged part: its number, the ETag the bucket returned, and its
/// byte count.
typedef _Part = ({int number, String tag, int size});

/// An open multipart upload and the parts it can continue from.
typedef _Upload = ({String id, List<_Part> parts});

/// ListParts pages read before a resume gives up and starts again. S3 caps
/// an upload at 10,000 parts and a page at 1,000.
const int _maxPartPages = 10;
