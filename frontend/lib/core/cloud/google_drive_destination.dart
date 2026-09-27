import 'dart:convert';

import 'package:tapture/core/concurrency/cancellation_token.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';

import 'cloud_destination.dart';
import 'oauth_destination_client.dart';

/// Google Drive files this app creates. The scope is `drive.file` only.
final class GoogleDriveDestination implements CloudDestination {
  /// Creates the backend over the shared OAuth client.
  GoogleDriveDestination({required this.client});

  /// Files the app creates or opens. Not the user's whole Drive.
  static const String scope = 'https://www.googleapis.com/auth/drive.file';

  /// Endpoints and [scope] for the shared OAuth client.
  static final OauthProvider oauth = (
    name: 'google',
    authorize: Uri.parse('https://accounts.google.com/o/oauth2/v2/auth'),
    token: Uri.parse('https://oauth2.googleapis.com/token'),
    scope: scope,
  );

  /// Shared authorisation client.
  final OauthDestinationClient client;

  @override
  DestinationKind get kind => DestinationKind.googleDrive;

  @override
  Future<Result<void>> check(Destination destination) async {
    final Result<Uri> sent = await send(destination, (
      length: 2,
      read: (int _, int _) async => utf8.encode('ok'),
    ), remoteName: '.tapture-check');
    if (sent is FailureResult<Uri>) {
      return FailureResult<void>(sent.failure);
    }
    final String id = (sent as Success<Uri>).value.queryParameters['id'] ?? '';
    if (id.isEmpty) {
      return const FailureResult<void>(
        ValidationFailure(
          message: 'The destination did not accept the test file.',
          recoveryAction: 'Sign in again and retry the test.',
        ),
      );
    }
    final Result<CloudReply> removed = await client.sendAuthorized(
      provider: oauth,
      credentialRef: destination.credentialRef,
      call: (
        method: 'DELETE',
        url: Uri.parse('https://www.googleapis.com/drive/v3/files/$id'),
        headers: const <String, String>{},
        body: const <int>[],
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
    final Map<String, Object?> meta = <String, Object?>{'name': remoteName};
    if (destination.folder.isNotEmpty) {
      meta['parents'] = <String>[destination.folder];
    }
    final Result<CloudReply> opened = await client.sendAuthorized(
      provider: oauth,
      credentialRef: destination.credentialRef,
      call: (
        method: 'POST',
        url: Uri.parse(
          'https://www.googleapis.com/upload/drive/v3/files?uploadType=resumable',
        ),
        headers: <String, String>{
          'content-type': 'application/json; charset=UTF-8',
          'x-upload-content-length': '${file.length}',
        },
        body: utf8.encode(jsonEncode(meta)),
      ),
    );
    if (opened is FailureResult<CloudReply>) {
      return FailureResult<Uri>(opened.failure);
    }
    final CloudReply session = (opened as Success<CloudReply>).value;
    if (session.status < 200 || session.status >= 300) {
      return FailureResult<Uri>(cloudStatusFailure(session.status));
    }
    final String? location = _header(session, 'location');
    if (location == null || location.isEmpty) {
      return const FailureResult<Uri>(
        NetworkFailure(
          message: 'The destination did not start the upload.',
          recoveryAction: 'Try again.',
        ),
      );
    }
    final int end = file.length == 0 ? 0 : file.length - 1;
    final Result<CloudReply> put = await client.sendAuthorized(
      provider: oauth,
      credentialRef: destination.credentialRef,
      call: (
        method: 'PUT',
        url: Uri.parse(location),
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
    final String id = _id(saved.body);
    return Success<Uri>(
      Uri.parse('https://www.googleapis.com/drive/v3/files/$id?id=$id'),
    );
  }

  String? _header(CloudReply reply, String name) {
    for (final MapEntry<String, String> entry in reply.headers.entries) {
      if (entry.key.toLowerCase() == name) {
        return entry.value;
      }
    }
    return null;
  }

  String _id(List<int> body) {
    try {
      final Object? decoded = jsonDecode(utf8.decode(body));
      if (decoded is Map && decoded['id'] != null) {
        return '${decoded['id']}';
      }
    } on FormatException {
      return '';
    }
    return '';
  }
}
