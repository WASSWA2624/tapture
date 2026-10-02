import 'dart:convert';

import 'package:tapture/core/concurrency/cancellation_token.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';

import 'cloud_destination.dart';
import 'cloud_probe_name.dart';
import 'oauth_destination_client.dart';
import 'oauth_upload_session.dart';

/// Google Drive files this app creates. The scope is `drive.file` only.
final class GoogleDriveDestination implements CloudDestination {
  /// Creates the backend over the shared OAuth client.
  GoogleDriveDestination({required this.client, int? partBytes})
    : _partBytes = partBytes ?? AppConstants.cloudUpload.partBytes;

  /// Files the app creates or opens. Not the user's whole Drive.
  static const String scope = 'https://www.googleapis.com/auth/drive.file';

  /// Endpoints and [scope] for the shared OAuth client.
  static final OauthProvider oauth = (
    name: 'google',
    authorize: Uri.parse('https://accounts.google.com/o/oauth2/v2/auth'),
    token: Uri.parse('https://oauth2.googleapis.com/token'),
    scope: scope,
    authorizationParameters: const <String, String>{
      'access_type': 'offline',
      'prompt': 'consent',
    },
  );

  /// Shared authorisation client.
  final OauthDestinationClient client;
  final int _partBytes;

  @override
  DestinationKind get kind => DestinationKind.googleDrive;

  @override
  Future<Result<void>> check(Destination destination) async {
    final String name = CloudProbeName.create();
    final Result<Uri> sent = await send(destination, (
      length: 2,
      read: (int _, int _) async => utf8.encode('ok'),
    ), remoteName: name);
    if (sent is FailureResult<Uri>) {
      return FailureResult<void>(sent.failure);
    }
    final String id = (sent as Success<Uri>).value.queryParameters['id'] ?? '';
    if (id.isEmpty) {
      return FailureResult<void>(
        ValidationFailure(
          localizedMessage:
              Copy.messages.failureTheDestinationDidNotAcceptTheTest,
          localizedRecovery: Copy.messages.failureSignInAgainAndRetryTheTest,
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
  }) => Result.captureAsync<Uri>(() async {
    final int bound = OauthUploadSession.alignedChunk(
      _partBytes,
      AppConstants.cloudUpload.googleChunkUnit,
    );
    final OauthUploadSession session = await OauthUploadSession.open(
      client: client,
      provider: oauth.name,
      target: '${destination.folder}/$remoteName',
      length: file.length,
      cancel: cancel,
    );
    try {
      Uri? url;
      var cursor = 0;
      if (session.id case final String saved) {
        url = _uploadUri(saved);
        final CloudReply probe = await _request(destination, (
          method: 'PUT',
          url: url,
          headers: <String, String>{'content-range': 'bytes */${file.length}'},
          body: const <int>[],
        ), cancel);
        if (probe.status == 404 || probe.status == 410) {
          await session.clear();
          url = null;
        } else if (probe.status == 200 || probe.status == 201) {
          final Uri completed = await _complete(probe, session);
          onProgress?.call(file.length, file.length);
          return completed;
        } else if (probe.status == 308) {
          cursor = _acknowledged(probe, file.length);
          await session.checkpoint(url.toString(), cursor);
        } else {
          throw cloudStatusFailure(probe.status);
        }
      }
      if (url == null) {
        final CloudReply opened = await _request(destination, (
          method: 'POST',
          url: Uri.parse(
            'https://www.googleapis.com/upload/drive/v3/files?uploadType=resumable',
          ),
          headers: <String, String>{
            'content-type': 'application/json; charset=UTF-8',
            'x-upload-content-length': '${file.length}',
          },
          body: utf8.encode(
            jsonEncode(<String, Object?>{
              'name': remoteName,
              if (destination.folder.isNotEmpty)
                'parents': <String>[destination.folder],
            }),
          ),
        ), cancel);
        if (opened.status != 200 && opened.status != 201) {
          throw cloudStatusFailure(opened.status);
        }
        url = _uploadUri(_header(opened, 'location') ?? '');
        // A new session always starts at zero, regardless of a caller's offset.
        await session.checkpoint(url.toString(), 0);
      }
      onProgress?.call(cursor, file.length);
      do {
        final List<int> bytes = await session.read(file, cursor, bound);
        final int end = cursor + bytes.length;
        final CloudReply reply = await _request(destination, (
          method: 'PUT',
          url: url,
          headers: <String, String>{
            'content-length': '${bytes.length}',
            'content-range': bytes.isEmpty
                ? 'bytes */${file.length}'
                : 'bytes $cursor-${end - 1}/${file.length}',
          },
          body: bytes,
        ), cancel);
        if (reply.status == 200 || reply.status == 201) {
          if (end != file.length) throw OauthUploadSession.invalidReply;
          final Uri completed = await _complete(reply, session);
          onProgress?.call(file.length, file.length);
          return completed;
        }
        if (reply.status != 308) throw cloudStatusFailure(reply.status);
        final int acknowledged = _acknowledged(reply, file.length);
        if (acknowledged <= cursor || acknowledged > end) {
          throw OauthUploadSession.invalidReply;
        }
        cursor = acknowledged;
        await session.checkpoint(url.toString(), cursor);
        onProgress?.call(cursor, file.length);
      } while (cursor < file.length);
      throw NetworkFailure(
        localizedMessage:
            Copy.messages.failureTheDestinationHasNotFinishedTheUpload,
        localizedRecovery: Copy.messages.failureRetryTheUpload,
      );
    } on Failure catch (failure) {
      if (!cloudRetryable(failure)) await session.clear();
      rethrow;
    }
  });

  Future<CloudReply> _request(
    Destination destination,
    CloudCall call,
    CancellationToken? cancel,
  ) async => (await client.sendAuthorized(
    provider: oauth,
    credentialRef: destination.credentialRef,
    call: call,
    cancel: cancel,
  )).getOrThrow();

  Uri _uploadUri(String value) {
    final Uri uri = OauthUploadSession.secureUri(value);
    if (uri.host != 'googleapis.com' && !uri.host.endsWith('.googleapis.com')) {
      throw OauthUploadSession.invalidReply;
    }
    return uri;
  }

  int _acknowledged(CloudReply reply, int length) {
    final String? range = _header(reply, 'range');
    if (range == null) return 0;
    final RegExpMatch? match = RegExp(r'^bytes=0-(\d+)$').firstMatch(range);
    final int? last = int.tryParse(match?.group(1) ?? '');
    if (last == null || last < 0 || last >= length) {
      throw OauthUploadSession.invalidReply;
    }
    return last + 1;
  }

  Future<Uri> _complete(CloudReply reply, OauthUploadSession session) async {
    final Object? value = OauthUploadSession.decode(reply.body)['id'];
    if (value is! String || value.isEmpty) {
      throw OauthUploadSession.invalidReply;
    }
    await session.clear();
    return Uri.https(
      'www.googleapis.com',
      '/drive/v3/files/${Uri.encodeComponent(value)}',
      <String, String>{'id': value},
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
}
