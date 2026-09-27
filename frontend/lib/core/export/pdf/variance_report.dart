import 'pdf_engine.dart';

/// As-recorded against as-found, in three labelled sections (task 018).
final class VarianceReport {
  /// Sections for matched, missing and not-in-register rows.
  static PdfDocument build({
    required PdfEngine engine,
    required String project,
    required List<VarianceLine> matched,
    required List<VarianceLine> missing,
    required List<VarianceLine> notInRegister,
  }) {
    return engine.document(
      title: 'Variance report',
      project: project,
      coverLines: <String>[
        'matched ${matched.length}',
        'missing ${missing.length}',
        'not in register ${notInRegister.length}',
      ],
      bodyLines: <String>[
        'Matched',
        for (final VarianceLine line in matched) '${line.key} ${line.label}',
        'Missing',
        for (final VarianceLine line in missing) '${line.key} ${line.label}',
        'Not in register',
        for (final VarianceLine line in notInRegister)
          '${line.key} ${line.label}',
      ],
    );
  }
}

/// One variance row and its register key.
typedef VarianceLine = ({String key, String label});
