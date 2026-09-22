import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';

import 'capture_session.dart';

/// Raw save: persists as CAPTURED and runs nothing — no network, no AI
/// (FE-SEC-03, FE-SEC-04).
abstract final class SaveRaw {
  /// Status written; no processing is started.
  static const String capturedStatus = 'CAPTURED';

  /// Persists [session] via [persist]. Provably silent — no outbound calls.
  static Future<Result<String>> run({
    required CaptureSession session,
    required Future<Result<String>> Function(CaptureSession session) persist,
  }) async {
    if (!session.hasEvidence && session.recordCaption.trim().isEmpty) {
      return const FailureResult<String>(
        ValidationFailure(
          message: 'Add at least one photo or a caption before saving.',
          recoveryAction: 'Add evidence, then try again.',
        ),
      );
    }
    return persist(session);
  }
}
