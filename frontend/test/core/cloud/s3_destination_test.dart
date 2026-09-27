import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/cloud/cloud_destination.dart';
import 'package:tapture/core/cloud/s3_destination.dart';
import 'package:tapture/core/concurrency/cancellation_token.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/time/clock.dart';

void main() {
  const Destination destination = (
    id: 'dest',
    kind: DestinationKind.s3,
    label: 'Bucket',
    folder: 'inbox',
    credentialRef: 'ref',
    lastCheck: null,
  );
  final String secret = jsonEncode(<String, String>{
    'accessKey': 'AKIAKEY',
    'secret': 'wJalrXUtn',
    'region': 'us-east-1',
    'bucket': 'archive',
    'endpoint': 'https://minio.local',
    'prefix': 'inbox',
  });

  S3Destination backend(CloudSend send) {
    return S3Destination(
      transport: send,
      readSecret: (_) async => secret,
      clock: FixedClock(DateTime.utc(2026, 9, 28, 12)),
      partBytes: 8,
    );
  }

  test('requests are signed for the configured endpoint', () async {
    final List<CloudCall> calls = <CloudCall>[];
    final S3Destination s3 = backend((CloudCall call) async {
      calls.add(call);
      return (
        status: 200,
        headers: const <String, String>{},
        body: const <int>[],
      );
    });
    expect(await s3.check(destination), isA<Success<void>>());
    expect(calls, hasLength(2));
    expect(calls.first.method, 'PUT');
    expect(calls.last.method, 'DELETE');
    expect(calls.first.url.host, 'minio.local');
    expect(
      calls.first.headers['authorization'],
      startsWith('AWS4-HMAC-SHA256'),
    );
    expect(
      calls.first.headers['authorization'],
      contains('Credential=AKIAKEY/'),
    );
    expect(calls.first.headers['host'], 'minio.local');
  });

  test('a fatal status is not retryable and a 500 is', () async {
    final S3Destination denied = backend((CloudCall _) async {
      return (
        status: 403,
        headers: const <String, String>{},
        body: const <int>[],
      );
    });
    final Result<void> forbidden = await denied.check(destination);
    expect(forbidden, isA<FailureResult<void>>());
    expect(cloudRetryable((forbidden as FailureResult<void>).failure), isFalse);

    final S3Destination down = backend((CloudCall _) async {
      return (
        status: 503,
        headers: const <String, String>{},
        body: const <int>[],
      );
    });
    final Result<void> unavailable = await down.check(destination);
    expect((unavailable as FailureResult<void>).failure, isA<NetworkFailure>());
    expect(cloudRetryable(unavailable.failure), isTrue);
  });

  test(
    'multipart resumes from the offset and cancel leaves no upload',
    () async {
      final List<int> reads = <int>[];
      final List<CloudCall> calls = <CloudCall>[];
      final CancellationToken token = CancellationToken();
      final S3Destination s3 = backend((CloudCall call) async {
        calls.add(call);
        if (call.url.query.contains('uploads')) {
          return (
            status: 200,
            headers: const <String, String>{},
            body: utf8.encode('<UploadId>up-1</UploadId>'),
          );
        }
        return (
          status: 200,
          headers: const <String, String>{'etag': '"p"'},
          body: const <int>[],
        );
      });
      final Result<Uri> cancelled = await s3.send(
        destination,
        (
          length: 1 << 30,
          read: (int offset, int length) async {
            reads.add(offset);
            expect(length <= 8, isTrue);
            token.cancel();
            return List<int>.filled(length, 1);
          },
        ),
        remoteName: 'archive.zip',
        cancel: token,
      );
      expect(cancelled, isA<FailureResult<Uri>>());
      expect(
        (cancelled as FailureResult<Uri>).failure,
        isA<CancelledFailure>(),
      );
      expect(reads, <int>[0]);
      expect(calls.last.method, 'DELETE');

      final List<int> resumed = <int>[];
      final S3Destination again = backend((CloudCall call) async {
        if (call.url.query.contains('uploads')) {
          return (
            status: 200,
            headers: const <String, String>{},
            body: utf8.encode('<UploadId>up-2</UploadId>'),
          );
        }
        if (call.url.query.contains('uploadId') && call.method == 'POST') {
          return (
            status: 200,
            headers: const <String, String>{},
            body: const <int>[],
          );
        }
        return (
          status: 200,
          headers: const <String, String>{'etag': '"p"'},
          body: const <int>[],
        );
      });
      final Result<Uri> sent = await again.send(
        destination,
        (
          length: 20,
          read: (int offset, int length) async {
            resumed.add(offset);
            return List<int>.filled(length, 2);
          },
        ),
        remoteName: 'archive.zip',
        offset: 8,
      );
      expect(sent, isA<Success<Uri>>());
      expect(resumed.first, 8);
      expect(resumed.contains(0), isFalse);
    },
  );
}
