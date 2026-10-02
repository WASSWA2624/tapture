import 'dart:convert';

import 'package:tapture/core/concurrency/cancellation_token.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';

import 'cloud_destination.dart';
import 'oauth_destination_client.dart';

/// Durable resumable state for one provider, source and remote target.
///
/// Session URLs and IDs are credentials: only the client's secure session store
/// sees the serialized state. A checkpoint is awaited before progress is reported.
final class OauthUploadSession {
  OauthUploadSession._({
    required this._client,
    required this._provider,
    required this._target,
    required this._length,
    required this._cancel,
  });

  final OauthDestinationClient _client;
  final String _provider;
  final String _target;
  final int _length;
  final CancellationToken? _cancel;
  String? _id;
  int _offset = 0;

  /// Session identifier, absent until the provider opens a session.
  String? get id => _id;

  /// Last durably recorded acknowledgement; the provider verifies it on resume.
  int get offset => _offset;

  /// Restores only state matching the current source fingerprint and target.
  static Future<OauthUploadSession> open({
    required OauthDestinationClient client,
    required String provider,
    required String target,
    required int length,
    CancellationToken? cancel,
  }) async {
    final OauthUploadSession session = OauthUploadSession._(
      client: client,
      provider: provider,
      target: target,
      length: length,
      cancel: cancel,
    );
    session.ensureActive();
    final String? saved = await client.readUploadSession();
    session.ensureActive();
    if (saved == null) return session;
    try {
      final Map<String, Object?> state = decode(utf8.encode(saved));
      final String? fingerprint = client.uploadFingerprint;
      final Object? id = state['id'];
      final Object? offset = state['offset'];
      if (fingerprint != null &&
          fingerprint.isNotEmpty &&
          state['fingerprint'] == fingerprint &&
          state['provider'] == provider &&
          state['target'] == target &&
          state['length'] == length &&
          id is String &&
          id.isNotEmpty &&
          offset is int &&
          offset >= 0 &&
          offset <= length) {
        session._id = id;
        session._offset = offset;
        return session;
      }
    } on ValidationFailure {
      // Invalid or obsolete stored state cannot authorize a resumed upload.
    }
    await session.clear();
    return session;
  }

  /// Saves the session before bytes leave, or after an acknowledged chunk.
  Future<void> checkpoint(String id, int offset) async {
    if (id.isEmpty || offset < 0 || offset > _length) {
      throw invalidReply;
    }
    await _client.writeUploadSession(
      jsonEncode(<String, Object?>{
        'provider': _provider,
        'fingerprint': _client.uploadFingerprint,
        'target': _target,
        'length': _length,
        'id': id,
        'offset': offset,
      }),
    );
    _id = id;
    _offset = offset;
  }

  /// Forgets completed, cancelled or expired state.
  Future<void> clear() async {
    await _client.writeUploadSession(null);
    _id = null;
    _offset = 0;
  }

  /// Stops before another read or request when the operator cancels.
  void ensureActive() {
    if (_cancel?.isCancelled ?? false) throw const CancelledFailure();
  }

  /// Reads at most [bound] bytes and refuses a changing or unreadable file.
  Future<List<int>> read(CloudBytes file, int offset, int bound) async {
    ensureActive();
    if (offset < 0 || offset > file.length || bound <= 0) {
      throw invalidReply;
    }
    final int count = (file.length - offset).clamp(0, bound);
    final List<int> bytes = count == 0
        ? const <int>[]
        : await file.read(offset, count);
    ensureActive();
    if (bytes.length != count) throw cloudReadFailure;
    return bytes;
  }

  /// Floors a configured memory bound to the provider's wire-format unit.
  static int alignedChunk(int bound, int unit) {
    if (bound < unit || unit <= 0) {
      throw ValidationFailure(
        localizedMessage: Copy.messages.failureTheUploadChunkSizeIsNotUsable,
        localizedRecovery: Copy.messages.failureUseTheStandardUploadSettings,
      );
    }
    return bound - bound % unit;
  }

  /// Parses structured provider data without coercing malformed values.
  static Map<String, Object?> decode(List<int> bytes) {
    try {
      final Object? value = jsonDecode(utf8.decode(bytes));
      if (value is Map<String, Object?>) return value;
    } on FormatException {
      // Provider text is deliberately excluded from failure messages.
    }
    throw invalidReply;
  }

  /// Validates a secret upload URL without ever including it in a failure.
  static Uri secureUri(String value) {
    final Uri? uri = Uri.tryParse(value);
    if (uri == null ||
        uri.scheme != 'https' ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty) {
      throw invalidReply;
    }
    return uri;
  }

  /// Provider data cannot justify another read, progress or completion.
  static final ValidationFailure invalidReply = ValidationFailure(
    localizedMessage:
        Copy.messages.failureTheDestinationReturnedAnUnusableUploadResponse,
    localizedRecovery: Copy.messages.failureTestTheDestinationThenTryTheUpload,
  );
}
