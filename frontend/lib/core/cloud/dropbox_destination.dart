import 'dart:convert';

import 'package:tapture/core/concurrency/cancellation_token.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';

import 'cloud_destination.dart';
import 'oauth_destination_client.dart';

/// Dropbox uploads into the chosen folder. The scope can write files and
/// cannot list the rest of the account.
final class DropboxDestination implements CloudDestination {
  /// Creates the backend over the shared OAuth client.
  DropboxDestination({required this.client});

  /// Write file bytes. Not metadata read and not account info.
  static const String scope = 'files.content.write';

  /// Endpoints and [scope] for the shared OAuth client.
  static final OauthProvider oauth = (
    name: 'dropbox',
    authorize: Uri.parse('https://www.dropbox.com/oauth2/authorize'),
    token: Uri.parse('https://api.dropboxapi.com/oauth2/token'),
    scope: scope,
  );

  /// Shared authorisation client.
  final OauthDestinationClient client;

  @override
  DestinationKind get kind => DestinationKind.dropbox;

  @override
  Future<Result<void>> check(Destination destination) async {
    final Result<Uri> sent = await send(destination, (
      length: 2,
      read: (int _, int _) async => utf8.encode('ok'),
    ), remoteName: '.tapture-check');
    if (sent is FailureResult<Uri>) {
      return FailureResult<void>(sent.failure);
    }
    final Result<CloudReply> removed = await client.sendAuthorized(
      provider: oauth,
      credentialRef: destination.credentialRef,
      call: (
        method: 'POST',
        url: Uri.parse('https://api.dropboxapi.com/2/files/delete_v2'),
        headers: const <String, String>{'content-type': 'application/json'},
        body: utf8.encode(
          jsonEncode(<String, String>{
            'path': _path(destination, '.tapture-check'),
          }),
        ),
      ),
    );
    if (removed is FailureResult<CloudReply>) {
      return FailureResult<void>(removed.failure);
    }
    final CloudReply reply = (removed as Success<CloudReply>).value;
    if (reply.status >= 300) {
      return FailureResult<void>(cloudStatusFailure(reply.status));
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
    final int start = offset.clamp(0, file.length);
    final List<int> body = start >= file.length
        ? const <int>[]
        : await file.read(start, file.length - start);
    final String path = _path(destination, remoteName);
    final Result<CloudReply> saved = await client.sendAuthorized(
      provider: oauth,
      credentialRef: destination.credentialRef,
      call: (
        method: 'POST',
        url: Uri.parse(
          'https://content.dropboxapi.com/2/files/upload_session/append_v2',
        ),
        headers: <String, String>{
          'content-type': 'application/octet-stream',
          'dropbox-api-arg': jsonEncode(<String, Object>{
            'cursor': <String, Object>{'session_id': path, 'offset': start},
            'close': start + body.length >= file.length,
            'path': path,
          }),
        },
        body: body,
      ),
    );
    if (saved is FailureResult<CloudReply>) {
      return FailureResult<Uri>(saved.failure);
    }
    final CloudReply reply = (saved as Success<CloudReply>).value;
    if (reply.status < 200 || reply.status >= 300) {
      return FailureResult<Uri>(cloudStatusFailure(reply.status));
    }
    onProgress?.call(file.length, file.length);
    return Success<Uri>(Uri.parse('dropbox://$path'));
  }

  String _path(Destination destination, String name) {
    final String folder = destination.folder.replaceAll(RegExp(r'^/+|/+$'), '');
    if (folder.isEmpty) {
      return '/$name';
    }
    return '/$folder/$name';
  }
}
