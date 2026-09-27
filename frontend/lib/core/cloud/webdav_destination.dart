import 'dart:convert';

import 'package:tapture/core/concurrency/cancellation_token.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';

import 'cloud_destination.dart';

/// A WebDAV or generic HTTPS folder. A redirect to another host fails
/// instead of being followed. Basic or bearer credentials are sent on each call.
final class WebdavDestination implements CloudDestination {
  /// Creates the backend. [readSecret] is called on every check and send.
  WebdavDestination({required this.transport, required this.readSecret});

  /// Transport that carries the WebDAV calls.
  final CloudSend transport;

  /// Reads the endpoint credential on every call.
  final SecretRead readSecret;

  @override
  DestinationKind get kind => DestinationKind.webdav;

  @override
  Future<Result<void>> check(Destination destination) async {
    final Result<_WebDavConfig> config = await _config(destination);
    if (config is FailureResult<_WebDavConfig>) {
      return FailureResult<void>(config.failure);
    }
    final _WebDavConfig ready = (config as Success<_WebDavConfig>).value;
    final Result<CloudReply> put = await _put(
      ready,
      destination,
      '.tapture-check',
      utf8.encode('ok'),
    );
    if (put is FailureResult<CloudReply>) {
      return FailureResult<void>(put.failure);
    }
    final CloudReply created = (put as Success<CloudReply>).value;
    if (created.status < 200 || created.status >= 300) {
      return FailureResult<void>(cloudStatusFailure(created.status));
    }
    final Result<CloudReply> removed = await _call(
      ready,
      method: 'DELETE',
      url: _fileUrl(ready, destination, '.tapture-check'),
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
    final Result<_WebDavConfig> config = await _config(destination);
    if (config is FailureResult<_WebDavConfig>) {
      return FailureResult<Uri>(config.failure);
    }
    final _WebDavConfig ready = (config as Success<_WebDavConfig>).value;
    final int start = offset.clamp(0, file.length);
    final List<int> body = start >= file.length
        ? const <int>[]
        : await file.read(start, file.length - start);
    if (cancel?.isCancelled ?? false) {
      return const FailureResult<Uri>(CancelledFailure());
    }
    final Result<CloudReply> put = await _put(
      ready,
      destination,
      remoteName,
      body,
    );
    if (put is FailureResult<CloudReply>) {
      return FailureResult<Uri>(put.failure);
    }
    final CloudReply reply = (put as Success<CloudReply>).value;
    if (reply.status < 200 || reply.status >= 300) {
      return FailureResult<Uri>(cloudStatusFailure(reply.status));
    }
    onProgress?.call(file.length, file.length);
    return Success<Uri>(_fileUrl(ready, destination, remoteName));
  }

  Future<Result<CloudReply>> _put(
    _WebDavConfig ready,
    Destination destination,
    String name,
    List<int> body,
  ) async {
    final Uri url = _fileUrl(ready, destination, name);
    final Result<CloudReply> first = await _call(
      ready,
      method: 'PUT',
      url: url,
      body: body,
    );
    if (first is FailureResult<CloudReply>) {
      return first;
    }
    final CloudReply reply = (first as Success<CloudReply>).value;
    if (reply.status != 404 && reply.status != 409) {
      return Success<CloudReply>(reply);
    }
    final Result<CloudReply> made = await _call(
      ready,
      method: 'MKCOL',
      url: _folderUrl(ready, destination),
      body: const <int>[],
    );
    if (made is FailureResult<CloudReply>) {
      return made;
    }
    return _call(ready, method: 'PUT', url: url, body: body);
  }

  Future<Result<CloudReply>> _call(
    _WebDavConfig ready, {
    required String method,
    required Uri url,
    required List<int> body,
  }) async {
    try {
      final CloudReply reply = await transport((
        method: method,
        url: url,
        headers: <String, String>{'authorization': ready.authorization},
        body: body,
      ));
      final Map<String, String> headers = <String, String>{
        for (final MapEntry<String, String> entry in reply.headers.entries)
          entry.key.toLowerCase(): entry.value,
      };
      if (reply.status >= 300 && reply.status < 400) {
        final String? location = headers['location'];
        if (location != null && location.isNotEmpty) {
          final Uri next = Uri.parse(location);
          if (next.host.isNotEmpty && next.host != url.host) {
            return const FailureResult<CloudReply>(
              ValidationFailure(
                message: 'The server redirected the upload to another host.',
                recoveryAction: 'Check the address and try again.',
              ),
            );
          }
        }
      }
      return Success<CloudReply>((
        status: reply.status,
        headers: headers,
        body: reply.body,
      ));
    } on Object {
      return const FailureResult<CloudReply>(
        NetworkFailure(
          message: 'The destination could not be reached.',
          recoveryAction: 'Try again when you are online.',
        ),
      );
    }
  }

  Future<Result<_WebDavConfig>> _config(Destination destination) async {
    final String? raw = await readSecret(destination.credentialRef);
    if (raw == null || raw.isEmpty) {
      return const FailureResult<_WebDavConfig>(
        PermissionFailure(
          message: 'This destination has no saved sign-in.',
          recoveryAction: 'Enter the address and sign-in, then test it.',
        ),
      );
    }
    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return const FailureResult<_WebDavConfig>(
          ValidationFailure(
            message: 'The saved sign-in is not usable.',
            recoveryAction: 'Enter the address and sign-in again.',
          ),
        );
      }
      final String base = '${decoded['baseUrl'] ?? ''}';
      final String bearer = '${decoded['bearer'] ?? ''}';
      final String username = '${decoded['username'] ?? ''}';
      final String password = '${decoded['password'] ?? ''}';
      if (base.isEmpty || Uri.tryParse(base)?.host.isEmpty != false) {
        return const FailureResult<_WebDavConfig>(
          ValidationFailure(
            message: 'The address is not usable.',
            recoveryAction: 'Enter a full https address.',
          ),
        );
      }
      final String authorization = bearer.isNotEmpty
          ? 'Bearer $bearer'
          : 'Basic ${base64Encode(utf8.encode('$username:$password'))}';
      if (bearer.isEmpty && username.isEmpty) {
        return const FailureResult<_WebDavConfig>(
          ValidationFailure(
            message: 'The sign-in is incomplete.',
            recoveryAction: 'Enter a token or a name and password.',
          ),
        );
      }
      return Success<_WebDavConfig>((
        base: Uri.parse(base),
        authorization: authorization,
      ));
    } on FormatException {
      return const FailureResult<_WebDavConfig>(
        ValidationFailure(
          message: 'The saved sign-in is not usable.',
          recoveryAction: 'Enter the address and sign-in again.',
        ),
      );
    }
  }

  Uri _folderUrl(_WebDavConfig ready, Destination destination) {
    final String folder = destination.folder.replaceAll(RegExp(r'^/+|/+$'), '');
    return ready.base.resolve(folder.isEmpty ? '' : '$folder/');
  }

  Uri _fileUrl(_WebDavConfig ready, Destination destination, String name) {
    return _folderUrl(ready, destination).resolve(name);
  }
}

typedef _WebDavConfig = ({Uri base, String authorization});
