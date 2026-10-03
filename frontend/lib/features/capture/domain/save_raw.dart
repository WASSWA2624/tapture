import 'package:tapture/core/copy/domain_copy.g.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/widgets/record_status.dart';

import 'capture_session.dart';

/// Raw save: persists as captured and runs nothing — no network, no AI
/// (FE-SEC-03, FE-SEC-04).
abstract final class SaveRaw {
  /// Status written; no processing is started.
  static const RecordStatus capturedStatus = RecordStatus.captured;

  /// Persists [session] via [persist]. Provably silent — no outbound calls.
  static Future<Result<String>> run({
    required CaptureSession session,
    required Future<Result<String>> Function(CaptureSession session) persist,
  }) async {
    if (!session.hasEvidence && session.recordCaption.trim().isEmpty) {
      return FailureResult<String>(
        ValidationFailure(
          localizedMessage: DomainCopy.messages.captureNeedsEvidence,
          localizedRecovery: DomainCopy.messages.captureNeedsEvidenceRecovery,
        ),
      );
    }
    return persist(session);
  }
}
