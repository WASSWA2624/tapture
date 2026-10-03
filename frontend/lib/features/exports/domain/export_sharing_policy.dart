import 'package:tapture/core/errors/result.dart';

/// Revalidates current protections before previously saved bytes leave again.
abstract interface class ExportSharingPolicy {
  /// Verifies the saved artifact still matches current protections.
  Future<Result<void>> allowShare(String exportId);

  /// Privacy actions recorded in the saved artifact.
  Future<Result<ExportPrivacySummary>> privacySummary(String exportId);
}

/// Omitted records and the number of blurred faces in each exported photo.
typedef ExportPrivacySummary = ({
  List<String> omittedRecordIds,
  Map<String, int> photoFaceCounts,
});
