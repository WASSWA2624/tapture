import 'package:tapture/core/validation/validation_issue.dart';

import 'export_record.dart';
import 'export_request.dart';

/// The pre-export gate. It reports incomplete and unapproved records and
/// applies the operator's decision. Field checks come from the validation
/// issues it is given, not a second copy of those rules.
final class ExportValidation {
  /// Incomplete field keys and unapproved record ids.
  static ExportValidationReport assess({
    required List<ValidationIssue> issues,
    required List<ExportRecord> records,
  }) {
    return (
      incomplete: <String>[
        for (final ValidationIssue issue in issues)
          if (issue.blocks) issue.fieldKey ?? issue.message,
      ],
      unapproved: <String>[
        for (final ExportRecord record in records)
          if (!record.approved) record.id,
      ],
    );
  }

  /// Whether [report] names nothing.
  static bool isClean(ExportValidationReport report) {
    return report.incomplete.isEmpty && report.unapproved.isEmpty;
  }

  /// Applies [choice]. Fix now does not export. Exclude drops the named
  /// records. Export anyway sets the incomplete mark on the request.
  static ExportGate apply({
    required ExportRequest request,
    required ExportValidationReport report,
    required ExportGateChoice choice,
  }) {
    final Set<String> named = <String>{
      ...report.incomplete,
      ...report.unapproved,
    };
    return switch (choice) {
      ExportGateChoice.fixNow => (
        proceed: false,
        request: request,
        named: named.toList(),
      ),
      ExportGateChoice.excludeThem => (
        proceed: true,
        request: request.without(named),
        named: const <String>[],
      ),
      ExportGateChoice.exportAnyway => (
        proceed: true,
        request: request.markIncomplete(),
        named: named.toList(),
      ),
    };
  }
}

/// What the gate found.
typedef ExportValidationReport = ({
  List<String> incomplete,
  List<String> unapproved,
});

/// The operator's decision.
enum ExportGateChoice { fixNow, excludeThem, exportAnyway }

/// The request to run, or a stop.
typedef ExportGate = ({
  bool proceed,
  ExportRequest request,
  List<String> named,
});
