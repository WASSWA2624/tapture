import 'dart:convert';

import 'package:tapture/core/concurrency/cancellation_token.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';

import 'cloud_destination.dart';
import 'oauth_destination_client.dart';

/// OneDrive's app folder only. The scope cannot read the rest of the drive.
final class OnedriveDestination implements CloudDestination {
  /// Creates the backend over the shared OAuth client.
  OnedriveDestination({required this.client});

  /// The app folder, plus refresh. Not Files.ReadWrite and not Files.Read.
  static const String scope = 'Files.ReadWrite.AppFolder offline_access';

  /// Endpoints and [scope] for the shared OAuth client.
  static final OauthProvider oauth = (
    name: 'microsoft',
    authorize: Uri.parse(
      'https://login.microsoftonline.com/common/oauth2/v2.0/authorize',
    ),
    token: Uri.parse(
      'https://login.microsoftonline.com/common/oauth2/v2.0/token',
    ),
    scope: scope,
  );

  /// Shared authorisation client.
  final OauthDestinationClient client;

  @override
  DestinationKind get kind => DestinationKind.oneDrive;

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
        method: 'DELETE',
        url: Uri.parse(_item(destination, '.tapture-check')),
        headers: const <String, String>{},
        body: const <int>[],
      ),
    );
    if (removed is FailureResult<CloudReply>) {
      return FailureResult<void>(removed.failure);
    }
    final CloudReply reply = (removed as Success<CloudReply>).value;
    if (reply.status >= 300 && reply.status != 404) {
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
    final String item = _item(destination, remoteName);
    final Result<CloudReply> opened = await client.sendAuthorized(
      provider: oauth,
      credentialRef: destination.credentialRef,
      call: (
        method: 'POST',
        url: Uri.parse('$item:/createUploadSession'),
        headers: const <String, String>{'content-type': 'application/json'},
        body: utf8.encode(
          '{"item":{"@microsoft.graph.conflictBehavior":"replace"}}',
        ),
      ),
    );
    if (opened is FailureResult<CloudReply>) {
      return FailureResult<Uri>(opened.failure);
    }
    final CloudReply session = (opened as Success<CloudReply>).value;
    if (session.status < 200 || session.status >= 300) {
      return FailureResult<Uri>(cloudStatusFailure(session.status));
    }
    final String uploadUrl = _uploadUrl(session.body);
    if (uploadUrl.isEmpty) {
      return const FailureResult<Uri>(
        NetworkFailure(
          message: 'The destination did not start the upload.',
          recoveryAction: 'Try again.',
        ),
      );
    }
    final int start = offset.clamp(0, file.length);
    final List<int> body = start >= file.length
        ? const <int>[]
        : await file.read(start, file.length - start);
    final int end = file.length == 0 ? 0 : file.length - 1;
    final Result<CloudReply> put = await client.sendAuthorized(
      provider: oauth,
      credentialRef: destination.credentialRef,
      call: (
        method: 'PUT',
        url: Uri.parse(uploadUrl),
        headers: <String, String>{
          'content-range': 'bytes $start-$end/${file.length}',
        },
        body: body,
      ),
    );
    if (put is FailureResult<CloudReply>) {
      return FailureResult<Uri>(put.failure);
    }
    final CloudReply saved = (put as Success<CloudReply>).value;
    if (saved.status < 200 || saved.status >= 300) {
      return FailureResult<Uri>(cloudStatusFailure(saved.status));
    }
    onProgress?.call(file.length, file.length);
    return Success<Uri>(Uri.parse(item));
  }

  String _item(Destination destination, String name) {
    final String folder = destination.folder.replaceAll(RegExp(r'^/+|/+$'), '');
    final String path = folder.isEmpty ? name : '$folder/$name';
    return 'https://graph.microsoft.com/v1.0/me/drive/special/approot:/$path';
  }

  String _uploadUrl(List<int> body) {
    try {
      final Object? decoded = jsonDecode(utf8.decode(body));
      if (decoded is Map && decoded['uploadUrl'] != null) {
        return '${decoded['uploadUrl']}';
      }
    } on FormatException {
      return '';
    }
    return '';
  }
}
