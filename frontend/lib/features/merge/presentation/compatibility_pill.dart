import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/app_status_pill.dart';

import '../domain/compatibility_status.dart';

/// The pill for a compatibility [status], as icon, colour and words
/// together (FE-THEME-05, task 076, W20).
AppStatusPill compatibilityPill(
  CompatibilityStatus status, {
  LocalizedCopy? localizedCopy,
}) {
  return AppStatusPill.badge(
    status: switch (status) {
      CompatibilityStatus.compatible => RecordStatus.approved,
      CompatibilityStatus.compatibleWithDifferences => RecordStatus.needsReview,
      CompatibilityStatus.incompatible => RecordStatus.failed,
    },
    label: (localizedCopy ?? Copy.english).compatibilityStatus(status.name),
  );
}
