/// Pulls identity values out of recognised plate text.
///
/// Every identity field pattern is applied. Candidates are ranked by how
/// high they sit on the plate, how specific the pattern is, and the block's
/// confidence. The originating block is kept so the value can be linked later.
final class IdentifierExtraction {
  /// All matches, best first. Empty when nothing fits.
  static List<IdentifierCandidate> extract({
    required String text,
    required List<PlateBlock> blocks,
    required List<IdentityField> fields,
  }) {
    final List<PlateBlock> source = blocks.isEmpty
        ? <PlateBlock>[(text: text, top: 0, confidence: 1)]
        : blocks;
    final List<IdentifierCandidate> found = <IdentifierCandidate>[];
    for (final IdentityField field in fields) {
      final RegExp? pattern = _compile(field.pattern);
      if (pattern == null) {
        continue;
      }
      for (final PlateBlock block in source) {
        for (final RegExpMatch match in pattern.allMatches(block.text)) {
          final String value = match.group(0) ?? '';
          if (value.isEmpty) {
            continue;
          }
          found.add((
            fieldKey: field.fieldKey,
            value: value,
            blockText: block.text,
            confidence: block.confidence,
            score: _score(
              top: block.top,
              specificity: field.pattern.length.toDouble(),
              confidence: block.confidence,
            ),
          ));
        }
      }
      if (blocks.isNotEmpty) {
        for (final RegExpMatch match in pattern.allMatches(text)) {
          final String value = match.group(0) ?? '';
          if (value.isEmpty ||
              found.any(
                (IdentifierCandidate candidate) =>
                    candidate.fieldKey == field.fieldKey &&
                    candidate.value == value,
              )) {
            continue;
          }
          found.add((
            fieldKey: field.fieldKey,
            value: value,
            blockText: text,
            confidence: 0.5,
            score: _score(
              top: 1,
              specificity: field.pattern.length.toDouble(),
              confidence: 0.5,
            ),
          ));
        }
      }
    }
    found.sort(
      (IdentifierCandidate a, IdentifierCandidate b) =>
          b.score.compareTo(a.score),
    );
    return found;
  }
}

/// An identity field and the pattern written on its template.
typedef IdentityField = ({String fieldKey, String pattern});

/// A block of plate text and where it sits. [top] is smaller when higher.
typedef PlateBlock = ({String text, double top, double confidence});

/// One ranked identity candidate.
typedef IdentifierCandidate = ({
  String fieldKey,
  String value,
  String blockText,
  double confidence,
  double score,
});

double _score({
  required double top,
  required double specificity,
  required double confidence,
}) {
  final double height = top <= 0 ? 1 : 1 / (1 + top);
  return height + specificity + confidence;
}

RegExp? _compile(String pattern) {
  if (pattern.isEmpty) {
    return null;
  }
  try {
    return RegExp(pattern);
  } on FormatException {
    return null;
  }
}
