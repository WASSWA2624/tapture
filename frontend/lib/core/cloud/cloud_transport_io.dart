import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';

import 'cloud_destination.dart';
import 'cloud_request_scope.dart';
import 'cloud_stream_call.dart';

/// Sends a bounded provider call without following redirects.
Future<CloudReply> sendCloud(CloudCall call) => sendCloudStream((
  method: call.method,
  url: call.url,
  headers: call.headers,
  contentLength: call.body.length,
  openBody: () => Stream<List<int>>.value(call.body),
));

/// Streams request bytes and bounds the reply. Cancellation aborts the active
/// request; the idle deadline also covers connection establishment and reads.
Future<CloudReply> sendCloudStream(CloudStreamCall call) async {
  final CloudRequestScope scope = CloudRequestScope.current;
  await scope.authorize?.call();
  if (scope.cancel?.isCancelled ?? false) {
    throw const CancelledFailure();
  }
  final HttpClient client = HttpClient();
  HttpClientRequest? request;
  Timer? idle;
  Failure? stopped;
  void stop(Failure failure) {
    stopped ??= failure;
    request?.abort(failure);
    client.close(force: true);
  }

  void touch() {
    idle?.cancel();
    idle = Timer(scope.idleTimeout, () => stop(_unreachable));
  }

  final void Function()? detach = scope.cancel?.register(
    () => stop(const CancelledFailure()),
  );
  try {
    if (stopped != null) {
      throw stopped!;
    }
    touch();
    request = await client.openUrl(call.method, call.url);
    if (stopped != null) {
      throw stopped!;
    }
    request.followRedirects = false;
    request.contentLength = call.contentLength;
    call.headers.forEach((String name, String value) {
      if (name.toLowerCase() != 'host' &&
          name.toLowerCase() != 'content-length') {
        request!.headers.set(name, value);
      }
    });
    var sent = 0;
    await request.addStream(
      call.openBody().map((List<int> bytes) {
        if (stopped != null) {
          throw stopped!;
        }
        sent += bytes.length;
        if (sent > call.contentLength) {
          throw cloudReadFailure;
        }
        touch();
        return bytes;
      }),
    );
    if (sent != call.contentLength) {
      throw cloudReadFailure;
    }
    final HttpClientResponse response = await request.close();
    final BytesBuilder body = BytesBuilder(copy: false);
    await for (final List<int> bytes in response) {
      touch();
      if (body.length + bytes.length > AppConstants.cloudUpload.replyMaxBytes) {
        throw ValidationFailure(
          localizedMessage:
              Copy.messages.failureTheDestinationReturnedTooMuchData,
          localizedRecovery:
              Copy.messages.failureCheckTheDestinationAddressAndTryAgain,
        );
      }
      body.add(bytes);
    }
    if (stopped != null) {
      throw stopped!;
    }
    final Map<String, String> headers = <String, String>{};
    response.headers.forEach((String name, List<String> values) {
      headers[name.toLowerCase()] = values.join(',');
    });
    return (
      status: response.statusCode,
      headers: headers,
      body: body.takeBytes(),
    );
  } on Object catch (error) {
    throw stopped ?? (error is Failure ? error : _unreachable);
  } finally {
    detach?.call();
    idle?.cancel();
    client.close(force: true);
  }
}

final NetworkFailure _unreachable = NetworkFailure(
  localizedMessage: Copy.messages.failureTheDestinationCouldNotBeReached,
  localizedRecovery: Copy.messages.failureTryAgainWhenYouAreOnline,
);
