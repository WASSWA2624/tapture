import 'dart:convert';
import 'dart:math';

import 'package:tapture/core/concurrency/cancellation_token.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';

import 'cloud_destination.dart';
import 'cloud_probe_name.dart';
import 'cloud_request_scope.dart';
import 'cloud_stream_call.dart';

/// Streams into a unique WebDAV staging object, then publishes with MOVE.
/// Only that staging object is deleted on failure or cancellation.
final class WebdavDestination implements CloudDestination {
  /// Creates the backend with separate bounded and streaming transports.
  WebdavDestination({
    required this.transport,
    required this.streamTransport,
    required this.readSecret,
  });

  /// Small control requests.
  final CloudSend transport;

  /// Streaming PUT requests.
  final CloudStreamSend streamTransport;

  /// Reads the endpoint credential for each operation.
  final SecretRead readSecret;

  @override
  DestinationKind get kind => DestinationKind.webdav;

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
    return Result.captureAsync<void>(() async {
      final _WebDavConfig ready = (await _config(destination)).getOrThrow();
      final CloudReply reply = await _call(
        ready,
        'DELETE',
        (sent as Success<Uri>).value,
      );
      _accepted(reply);
    });
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
    _notCancelled(cancel);
    if (remoteName.isEmpty ||
        remoteName == '.' ||
        remoteName == '..' ||
        remoteName.contains('/') ||
        remoteName.contains('\\')) {
      throw ValidationFailure(
        localizedMessage: Copy.messages.failureTheUploadFilenameIsNotUsable,
        localizedRecovery:
            Copy.messages.failureChooseAFilenameWithoutFolderSeparators,
      );
    }
    final _WebDavConfig ready = (await _config(destination)).getOrThrow();
    final Uri target = _fileUrl(ready, destination, remoteName);
    final Uri staged = _fileUrl(
      ready,
      destination,
      '.tapture-upload-${_nonce()}.part',
    );
    var published = false;
    try {
      // PUT replaces a resource. Offset is deliberately ignored: a WebDAV
      // retry sends the full stream into a new, private staging resource.
      final CancellationToken? active =
          cancel ?? CloudRequestScope.current.cancel;
      Future<CloudReply> put() => CloudRequestScope(cancel: active).run(
        () => streamTransport((
          method: 'PUT',
          url: staged,
          headers: <String, String>{
            'authorization': ready.authorization,
            'if-none-match': '*',
            'content-type': 'application/octet-stream',
          },
          contentLength: file.length,
          openBody: () => _bytes(file, active),
        )),
      );
      CloudReply reply = await put();
      if (reply.status == 404 || reply.status == 409) {
        _notCancelled(cancel);
        final CloudReply made = await CloudRequestScope(
          cancel: active,
        ).run(() => _call(ready, 'MKCOL', _folderUrl(ready, destination)));
        if (made.status != 405) {
          _accepted(made);
        }
        reply = await put();
      }
      _accepted(reply);
      _notCancelled(cancel);
      final CloudReply moved = await CloudRequestScope(cancel: active).run(
        () => _call(
          ready,
          'MOVE',
          staged,
          headers: <String, String>{
            'destination': target.toString(),
            'overwrite': 'T',
          },
        ),
      );
      _accepted(moved);
      published = true;
      // Progress represents server-published bytes, not bytes merely read.
      onProgress?.call(file.length, file.length);
      return target;
    } finally {
      if (!published) {
        try {
          await const CloudRequestScope().run(
            () => _call(ready, 'DELETE', staged),
          );
        } on Object {
          // Cleanup cannot mask the original failure and never deletes target.
        }
      }
    }
  });

  Stream<List<int>> _bytes(CloudBytes file, CancellationToken? cancel) async* {
    for (var position = 0; position < file.length;) {
      _notCancelled(cancel);
      final int length = min(
        AppConstants.cloudUpload.streamBytes,
        file.length - position,
      );
      final List<int> bytes = await file.read(position, length);
      if (bytes.length != length) {
        throw cloudReadFailure;
      }
      _notCancelled(cancel);
      yield bytes;
      position += length;
    }
  }

  Future<CloudReply> _call(
    _WebDavConfig ready,
    String method,
    Uri url, {
    Map<String, String> headers = const <String, String>{},
  }) => transport((
    method: method,
    url: url,
    headers: <String, String>{'authorization': ready.authorization, ...headers},
    body: const <int>[],
  ));

  void _accepted(CloudReply reply) {
    if (reply.status < 200 || reply.status >= 300) {
      throw cloudStatusFailure(reply.status);
    }
  }

  void _notCancelled(CancellationToken? cancel) {
    if (cancel?.isCancelled ?? false) {
      throw const CancelledFailure();
    }
  }

  String _nonce() {
    final Random random = Random.secure();
    return List<String>.generate(
      24,
      (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
  }

  Future<Result<_WebDavConfig>> _config(Destination destination) async {
    final String? raw = await readSecret(destination.credentialRef);
    if (raw == null || raw.isEmpty) {
      return FailureResult<_WebDavConfig>(
        PermissionFailure(
          localizedMessage:
              Copy.messages.failureThisDestinationHasNoSavedSignIn,
          localizedRecovery: Copy.messages.failureEnterTheAddressAndSignInThen,
        ),
      );
    }
    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return FailureResult<_WebDavConfig>(_invalid);
      }
      final Uri? base = Uri.tryParse('${decoded['baseUrl'] ?? ''}');
      if (base == null ||
          base.scheme != 'https' ||
          base.host.isEmpty ||
          base.userInfo.isNotEmpty ||
          base.hasQuery ||
          base.hasFragment) {
        return FailureResult<_WebDavConfig>(_invalid);
      }
      final String bearer = '${decoded['bearer'] ?? ''}';
      final String username = '${decoded['username'] ?? ''}';
      final String password = '${decoded['password'] ?? ''}';
      if (bearer.isEmpty && username.isEmpty) {
        return FailureResult<_WebDavConfig>(_invalid);
      }
      return Success<_WebDavConfig>((
        base: base,
        authorization: bearer.isNotEmpty
            ? 'Bearer $bearer'
            : 'Basic ${base64Encode(utf8.encode('$username:$password'))}',
      ));
    } on FormatException {
      return FailureResult<_WebDavConfig>(_invalid);
    }
  }

  Uri _folderUrl(_WebDavConfig ready, Destination destination) {
    final String folder = destination.folder.replaceAll(RegExp(r'^/+|/+$'), '');
    if (folder.split('/').any((part) => part == '..' || part == '.') ||
        folder.contains('\\')) {
      throw _invalid;
    }
    return ready.base.resolveUri(Uri(path: folder.isEmpty ? '' : '$folder/'));
  }

  Uri _fileUrl(_WebDavConfig ready, Destination destination, String name) =>
      _folderUrl(ready, destination).resolveUri(Uri(path: name));
}

typedef _WebDavConfig = ({Uri base, String authorization});
final ValidationFailure _invalid = ValidationFailure(
  localizedMessage: Copy.messages.failureTheDestinationAddressOrSignInIs,
  localizedRecovery: Copy.messages.failureEnterAFullHTTPSAddressAndSign,
);
