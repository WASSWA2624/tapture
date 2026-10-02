import 'dart:convert';

import 'package:tapture/core/concurrency/cancellation_token.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';

import 'cloud_destination.dart';
import 'cloud_probe_name.dart';
import 'cloud_request_scope.dart';
import 'oauth_destination_client.dart';
import 'oauth_upload_session.dart';

/// OneDrive's app folder only. The scope cannot read the rest of the drive.
final class OnedriveDestination implements CloudDestination {
  /// Creates the backend over the shared OAuth client.
  OnedriveDestination({required this.client, int? partBytes})
    : _partBytes = partBytes ?? AppConstants.cloudUpload.partBytes;

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
    authorizationParameters: const <String, String>{},
  );

  /// Shared authorisation client.
  final OauthDestinationClient client;
  final int _partBytes;

  @override
  DestinationKind get kind => DestinationKind.oneDrive;

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
    final Result<CloudReply> removed = await client.sendAuthorized(
      provider: oauth,
      credentialRef: destination.credentialRef,
      call: (
        method: 'DELETE',
        url: Uri.parse(_item(destination, name)),
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
  }) => Result.captureAsync<Uri>(() async {
    final int bound = OauthUploadSession.alignedChunk(
      _partBytes.clamp(0, AppConstants.cloudUpload.oneDriveMaxChunkBytes - 1),
      AppConstants.cloudUpload.oneDriveChunkUnit,
    );
    final String item = _item(destination, remoteName);
    final OauthUploadSession session = await OauthUploadSession.open(
      client: client,
      provider: oauth.name,
      target: item,
      length: file.length,
      cancel: cancel,
    );
    Uri? url;
    try {
      var cursor = 0;
      if (session.id case final String saved) {
        url = OauthUploadSession.secureUri(saved);
        final CloudReply probe = (await client.sendPublic(
          call: (
            method: 'GET',
            url: url,
            headers: const <String, String>{},
            body: const <int>[],
          ),
          cancel: cancel,
        )).getOrThrow();
        if (probe.status == 404 || probe.status == 410) {
          await session.clear();
          url = null;
        } else if (probe.status == 200 || probe.status == 202) {
          cursor = _nextOffset(probe, file.length);
          await session.checkpoint(url.toString(), cursor);
        } else {
          throw cloudStatusFailure(probe.status);
        }
      }
      if (url == null) {
        final CloudReply opened = (await client.sendAuthorized(
          provider: oauth,
          credentialRef: destination.credentialRef,
          cancel: cancel,
          call: (
            method: 'POST',
            url: Uri.parse('$item:/createUploadSession'),
            headers: const <String, String>{'content-type': 'application/json'},
            body: utf8.encode(
              '{"item":{"@microsoft.graph.conflictBehavior":"replace"}}',
            ),
          ),
        )).getOrThrow();
        if (opened.status != 200 && opened.status != 201) {
          throw cloudStatusFailure(opened.status);
        }
        final Object? uploadUrl = OauthUploadSession.decode(
          opened.body,
        )['uploadUrl'];
        if (uploadUrl is! String) throw OauthUploadSession.invalidReply;
        url = OauthUploadSession.secureUri(uploadUrl);
        await session.checkpoint(url.toString(), 0);
      }
      onProgress?.call(cursor, file.length);
      if (file.length == 0 || cursor == file.length) {
        throw OauthUploadSession.invalidReply;
      }
      while (cursor < file.length) {
        final List<int> bytes = await session.read(file, cursor, bound);
        final int end = cursor + bytes.length;
        final CloudReply reply = (await client.sendPublic(
          call: (
            method: 'PUT',
            url: url,
            headers: <String, String>{
              'content-length': '${bytes.length}',
              'content-range': 'bytes $cursor-${end - 1}/${file.length}',
            },
            body: bytes,
          ),
          cancel: cancel,
        )).getOrThrow();
        if (reply.status == 200 || reply.status == 201) {
          final Object? id = OauthUploadSession.decode(reply.body)['id'];
          if (end != file.length || id is! String || id.isEmpty) {
            throw OauthUploadSession.invalidReply;
          }
          await session.clear();
          onProgress?.call(file.length, file.length);
          return Uri.parse(item);
        }
        if (reply.status != 202) throw cloudStatusFailure(reply.status);
        final int acknowledged = _nextOffset(reply, file.length);
        if (acknowledged <= cursor ||
            acknowledged > end ||
            acknowledged >= file.length) {
          throw OauthUploadSession.invalidReply;
        }
        cursor = acknowledged;
        await session.checkpoint(url.toString(), cursor);
        onProgress?.call(cursor, file.length);
      }
      throw OauthUploadSession.invalidReply;
    } on Failure catch (failure) {
      if (!cloudRetryable(failure)) {
        if (url != null) {
          final Uri cleanupUrl = url;
          // Cleanup must remain possible after the transfer token was cancelled.
          await const CloudRequestScope().run(
            () => client.sendPublic(
              call: (
                method: 'DELETE',
                url: cleanupUrl,
                headers: const <String, String>{},
                body: const <int>[],
              ),
            ),
          );
        }
        await session.clear();
      }
      rethrow;
    }
  });

  int _nextOffset(CloudReply reply, int length) {
    final Object? ranges = OauthUploadSession.decode(
      reply.body,
    )['nextExpectedRanges'];
    if (ranges is! List<Object?> || ranges.isEmpty) {
      throw OauthUploadSession.invalidReply;
    }
    int? first;
    for (final Object? range in ranges) {
      if (range is! String) throw OauthUploadSession.invalidReply;
      final RegExpMatch? parsed = RegExp(r'^(\d+)-(?:\d+)?$').firstMatch(range);
      final int? offset = int.tryParse(parsed?.group(1) ?? '');
      if (offset == null || offset < 0 || offset >= length) {
        throw OauthUploadSession.invalidReply;
      }
      if (first == null || offset < first) first = offset;
    }
    return first!;
  }

  String _item(Destination destination, String name) {
    final String folder = destination.folder.replaceAll(RegExp(r'^/+|/+$'), '');
    final String path = <String>[
      ...folder.split('/').where((String part) => part.isNotEmpty),
      name,
    ].map(Uri.encodeComponent).join('/');
    return 'https://graph.microsoft.com/v1.0/me/drive/special/approot:/$path';
  }
}
