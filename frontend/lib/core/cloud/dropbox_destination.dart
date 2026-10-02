import 'dart:convert';

import 'package:tapture/core/concurrency/cancellation_token.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';

import 'cloud_destination.dart';
import 'cloud_probe_name.dart';
import 'oauth_destination_client.dart';
import 'oauth_upload_session.dart';

/// Dropbox uploads into the chosen folder. The scope can write files and
/// cannot list the rest of the account.
final class DropboxDestination implements CloudDestination {
  /// Creates the backend over the shared OAuth client.
  DropboxDestination({required this.client, int? partBytes})
    : _partBytes = partBytes ?? AppConstants.cloudUpload.partBytes;

  /// Write file bytes. Not metadata read and not account info.
  static const String scope = 'files.content.write';

  /// Endpoints and [scope] for the shared OAuth client.
  static final OauthProvider oauth = (
    name: 'dropbox',
    authorize: Uri.parse('https://www.dropbox.com/oauth2/authorize'),
    token: Uri.parse('https://api.dropboxapi.com/oauth2/token'),
    scope: scope,
    authorizationParameters: const <String, String>{
      'token_access_type': 'offline',
    },
  );

  /// Shared authorisation client.
  final OauthDestinationClient client;
  final int _partBytes;
  static final RegExp _nonHeaderCharacters = RegExp(r'[\u007f-\uffff]');

  @override
  DestinationKind get kind => DestinationKind.dropbox;

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
        method: 'POST',
        url: Uri.parse('https://api.dropboxapi.com/2/files/delete_v2'),
        headers: const <String, String>{'content-type': 'application/json'},
        body: utf8.encode(
          jsonEncode(<String, String>{'path': _path(destination, name)}),
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
  }) => Result.captureAsync<Uri>(() async {
    if (_partBytes <= 0) throw OauthUploadSession.invalidReply;
    final String path = _path(destination, remoteName);
    final OauthUploadSession session = await OauthUploadSession.open(
      client: client,
      provider: oauth.name,
      target: path,
      length: file.length,
      cancel: cancel,
    );
    try {
      String? id = session.id;
      var cursor = 0;
      if (id != null) {
        final CloudReply probe = await _request(
          destination,
          'append_v2',
          <String, Object?>{
            'cursor': <String, Object?>{
              'session_id': id,
              'offset': session.offset,
            },
            'close': false,
          },
          const <int>[],
          cancel,
        );
        if (probe.status == 200) {
          cursor = session.offset;
        } else if (probe.status == 409) {
          final Map<String, Object?> error = _lookupError(probe);
          final Object? tag = error['.tag'];
          if (tag == 'not_found' || tag == 'closed') {
            await session.clear();
            id = null;
          } else if (tag == 'incorrect_offset' &&
              error['correct_offset'] is int) {
            cursor = error['correct_offset']! as int;
            if (cursor < 0 || cursor > file.length) {
              throw OauthUploadSession.invalidReply;
            }
          } else {
            throw OauthUploadSession.invalidReply;
          }
        } else {
          throw cloudStatusFailure(probe.status);
        }
        if (id != null) await session.checkpoint(id, cursor);
      }
      if (id == null) {
        final CloudReply opened = await _request(
          destination,
          'start',
          const <String, Object?>{'close': false},
          const <int>[],
          cancel,
        );
        if (opened.status != 200) throw cloudStatusFailure(opened.status);
        final Object? value = OauthUploadSession.decode(
          opened.body,
        )['session_id'];
        if (value is! String || value.isEmpty) {
          throw OauthUploadSession.invalidReply;
        }
        id = value;
        await session.checkpoint(id, 0);
      }
      onProgress?.call(cursor, file.length);
      while (cursor < file.length) {
        final List<int> bytes = await session.read(file, cursor, _partBytes);
        final CloudReply appended = await _request(
          destination,
          'append_v2',
          <String, Object?>{
            'cursor': <String, Object?>{'session_id': id, 'offset': cursor},
            'close': false,
          },
          bytes,
          cancel,
        );
        if (appended.status != 200) throw cloudStatusFailure(appended.status);
        cursor += bytes.length;
        await session.checkpoint(id, cursor);
        onProgress?.call(cursor, file.length);
      }
      session.ensureActive();
      final CloudReply committed = await _request(
        destination,
        'finish',
        <String, Object?>{
          'cursor': <String, Object?>{'session_id': id, 'offset': cursor},
          'commit': <String, Object?>{
            'path': path,
            'mode': 'overwrite',
            'autorename': false,
          },
        },
        const <int>[],
        cancel,
      );
      if (committed.status != 200) throw cloudStatusFailure(committed.status);
      final Map<String, Object?> metadata = OauthUploadSession.decode(
        committed.body,
      );
      if (metadata['id'] is! String ||
          (metadata['id']! as String).isEmpty ||
          metadata['size'] != file.length) {
        throw OauthUploadSession.invalidReply;
      }
      await session.clear();
      return Uri(scheme: 'dropbox', path: path);
    } on Failure catch (failure) {
      if (!cloudRetryable(failure)) await session.clear();
      rethrow;
    }
  });

  Future<CloudReply> _request(
    Destination destination,
    String operation,
    Map<String, Object?> argument,
    List<int> body,
    CancellationToken? cancel,
  ) async => (await client.sendAuthorized(
    provider: oauth,
    credentialRef: destination.credentialRef,
    cancel: cancel,
    call: (
      method: 'POST',
      url: Uri.parse(
        'https://content.dropboxapi.com/2/files/upload_session/$operation',
      ),
      headers: <String, String>{
        'content-type': 'application/octet-stream',
        'dropbox-api-arg': _headerArgument(argument),
      },
      body: body,
    ),
  )).getOrThrow();

  String _headerArgument(Map<String, Object?> argument) {
    // Dropbox requires ASCII JSON in this header, including UTF-16 surrogate
    // escapes for names containing characters outside the basic plane.
    return jsonEncode(argument).replaceAllMapped(_nonHeaderCharacters, (
      Match match,
    ) {
      final String hex = match.group(0)!.codeUnitAt(0).toRadixString(16);
      return '\\u${hex.padLeft(4, '0')}';
    });
  }

  Map<String, Object?> _lookupError(CloudReply reply) {
    final Object? outer = OauthUploadSession.decode(reply.body)['error'];
    if (outer is! Map<String, Object?>) throw OauthUploadSession.invalidReply;
    if (outer['.tag'] == 'lookup_failed') {
      final Object? inner = outer['lookup_failed'];
      if (inner is! Map<String, Object?>) throw OauthUploadSession.invalidReply;
      return inner;
    }
    return outer;
  }

  String _path(Destination destination, String name) {
    final String folder = destination.folder.replaceAll(RegExp(r'^/+|/+$'), '');
    if (folder.isEmpty) {
      return '/$name';
    }
    return '/$folder/$name';
  }
}
