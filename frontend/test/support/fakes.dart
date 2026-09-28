import 'package:tapture/core/ai/ai_service.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';

/// A named failure when a test opens a real socket or calls a real provider.
final class HarnessSocketError extends StateError {
  /// Creates the error for [target].
  HarnessSocketError(String target)
    : super('Harness blocked an outbound call to $target.');
}

/// Counts and refuses every attempt to leave the device.
final class SocketGuard {
  int _calls = 0;

  /// How many outbound attempts this guard has seen.
  int get calls => _calls;

  /// Records an outbound attempt and throws [HarnessSocketError].
  void block(String target) {
    _calls += 1;
    throw HarnessSocketError(target);
  }
}

/// In-process AI. It never opens a socket.
final class FakeAiService implements AiService {
  /// Creates a fake. [fail] makes every call a queueable failure.
  FakeAiService({this.fail = false});

  /// When true, calls return a failure and keep the request.
  final bool fail;

  int _calls = 0;

  /// How many calls this fake has answered.
  int get calls => _calls;

  @override
  bool get isAvailable => !fail;

  @override
  Future<Result<ReadTextResult>> readText(ReadTextRequest request) {
    return _ok(const ReadTextResult(text: 'read'));
  }

  @override
  Future<Result<ExtractFieldsResult>> extractFields(
    ExtractFieldsRequest request,
  ) {
    return _ok(
      const ExtractFieldsResult(fields: <String, String?>{'serial': 'A-1'}),
    );
  }

  @override
  Future<Result<RefineTextResult>> refineText(RefineTextRequest request) {
    return _ok(RefineTextResult(text: 'refined ${request.raw}'));
  }

  @override
  Future<Result<TranscribeResult>> transcribe(TranscribeRequest request) {
    return _ok(const TranscribeResult(text: 'heard'));
  }

  Future<Result<T>> _ok<T>(T value) async {
    _calls += 1;
    if (fail) {
      return FailureResult<T>(
        const ProviderFailure(
          message: 'Analysis can wait.',
          recoveryAction: 'Continue capturing. Analysis can wait.',
          kind: ProviderFailureKind.unavailable,
        ),
      );
    }
    return Success<T>(value);
  }
}

/// The organisation server as a test sees it. Reachability never opens a socket.
final class FakeBackend {
  /// Creates a backend that starts [reachable].
  FakeBackend({this.reachable = true});

  /// Whether sign-in and the proxy may run.
  bool reachable;

  int _signIns = 0;

  /// How many times [signIn] succeeded.
  int get signIns => _signIns;

  /// The device holds no provider key.
  bool holdsProviderKey = false;

  /// Makes the server answer.
  void markReachable() {
    reachable = true;
  }

  /// Makes the server stay away. Later calls do not leave the device.
  void markUnreachable() {
    reachable = false;
  }

  /// Signs in once. An unreachable server does not count and does not throw
  /// a network error; the caller keeps the cached grant.
  bool signIn() {
    if (!reachable) return false;
    _signIns += 1;
    holdsProviderKey = false;
    return true;
  }
}
