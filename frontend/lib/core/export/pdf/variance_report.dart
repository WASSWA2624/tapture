import 'pdf_engine.dart';

/// As-recorded against as-found (task 018 step 11): register items matched,
/// register items missing and items found that are not in the register, in
/// three labelled sections, each item carrying its register key.
final class VarianceReport {
  /// The report of the three sets. [matched] lines carry their field
  /// differences in [VarianceLine.detail].
  static PdfDocument build({
    required PdfEngine engine,
    required String project,
    required List<VarianceLine> matched,
    required List<VarianceLine> missing,
    required List<VarianceLine> notInRegister,
    List<String> cover = const <String>[],
  }) {
    final PdfLabels text = engine.labels;
    PdfSection part(String heading, List<VarianceLine> lines) {
      return engine.section(
        heading: heading,
        lines: <String>[
          for (final VarianceLine line in lines) ...<String>[
            line.label.isEmpty ? line.key : '${line.key} ${line.label}',
            ...line.detail,
          ],
        ],
      );
    }

    return engine.document(
      title: text.varianceReport,
      project: project,
      coverLines: <String>[
        ...cover,
        '${text.matched}: ${matched.length}',
        '${text.missing}: ${missing.length}',
        '${text.notInRegister}: ${notInRegister.length}',
      ],
      sections: <PdfSection>[
        part(text.matched, matched),
        part(text.missing, missing),
        part(text.notInRegister, notInRegister),
      ],
    );
  }
}

/// One variance item: its register key, what it is, and any field
/// differences found against the register.
typedef VarianceLine = ({String key, String label, List<String> detail});
