import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/features/capture/domain/capture_record_persistence.dart';
import 'package:tapture/features/capture/domain/capture_session.dart';

/// An in-memory [CaptureRecordPersistence]: every persisted session becomes
/// a record `record-1`, `record-2`, …, kept so a test can read what the
/// save froze, and each write can be made to fail (FE-TEST-03, FE-TEST-10).
final class FakeCaptureRecordPersistence implements CaptureRecordPersistence {
  /// Every session [persist] froze, in call order.
  final List<CaptureSession> persisted = <CaptureSession>[];

  /// Every edit [update] wrote, in call order.
  final List<CaptureSession> updates = <CaptureSession>[];

  /// The records on this device, by id, as [load] hands them back.
  final Map<String, CaptureSession> records = <String, CaptureSession>{};

  /// When set, [persist] returns this and freezes nothing.
  Failure? persistFailure;

  /// When set, [update] returns this and writes nothing.
  Failure? updateFailure;

  int _next = 0;

  @override
  Future<Result<String>> persist(CaptureSession session) async {
    final Failure? refused = persistFailure;
    if (refused != null) {
      return FailureResult<String>(refused);
    }
    final String id = 'record-${++_next}';
    persisted.add(session);
    records[id] = session.copyWith(recordId: id, editing: true);
    return Success<String>(id);
  }

  @override
  Future<Result<CaptureSession>> load(String recordId) async {
    final CaptureSession? record = records[recordId];
    if (record == null) {
      return const FailureResult<CaptureSession>(_missing);
    }
    return Success<CaptureSession>(record);
  }

  @override
  Future<Result<void>> update(CaptureSession edited) async {
    final Failure? refused = updateFailure;
    if (refused != null) {
      return FailureResult<void>(refused);
    }
    updates.add(edited);
    records[edited.recordId ?? edited.id] = edited;
    return const Success<void>(null);
  }
}

const StorageFailure _missing = StorageFailure(
  message: 'That record is not on this device.',
  recoveryAction: 'Go back and try again.',
);
