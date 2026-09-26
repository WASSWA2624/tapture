import 'package:tapture/core/constants/app_constants.dart';

/// Pulls identity values out of recognised plate text.
///
/// Every identity field pattern is applied. Candidates are ranked by how
/// high they sit on the plate, how specific the pattern is, and the block's
/// confidence. The originating block is kept so the value can be linked later.
final class IdentifierExtraction {
  /// All matches, best first. Empty when nothing fits.
  ///
  /// A value found inside a block carries that block's index in [blocks];
  /// when it appears in several blocks, the best-ranked one is kept. A value
  /// found only across the joined [text] carries none, sits lowest on the
  /// plate and takes the fallback confidence.
  static List<IdentifierCandidate> extract({
    required String text,
    required List<PlateBlock> blocks,
    required List<IdentityField> fields,
  }) {
    final double longest = fields.fold<double>(
      0,
      (double widest, IdentityField field) => field.pattern.length > widest
          ? field.pattern.length.toDouble()
          : widest,
    );
    final ({double first, double span}) plate = _extent(blocks);
    final List<IdentifierCandidate> found = <IdentifierCandidate>[];
    for (final IdentityField field in fields) {
      final RegExp? pattern = _compile(field.pattern);
      if (pattern == null) {
        continue;
      }
      final double specificity = longest <= 0
          ? 0
          : field.pattern.length / longest;
      for (var index = 0; index < blocks.length; index++) {
        final PlateBlock block = blocks[index];
        final double confidence = block.confidence.clamp(0, 1).toDouble();
        final double position = plate.span <= 0
            ? 1
            : 1 - (block.top - plate.first) / plate.span;
        for (final RegExpMatch match in pattern.allMatches(block.text)) {
          final String value = match.group(0) ?? '';
          if (value.isEmpty) {
            continue;
          }
          found.add((
            fieldKey: field.fieldKey,
            value: value,
            blockText: block.text,
            blockIndex: index,
            confidence: confidence,
            score: _score(
              position: position,
              specificity: specificity,
              confidence: confidence,
            ),
          ));
        }
      }
      final double fallback =
          AppConstants.processing.identifierFallbackConfidence;
      for (final RegExpMatch match in pattern.allMatches(text)) {
        final String value = match.group(0) ?? '';
        if (value.isEmpty || _seen(found, field.fieldKey, value)) {
          continue;
        }
        found.add((
          fieldKey: field.fieldKey,
          value: value,
          blockText: text,
          blockIndex: null,
          confidence: fallback,
          score: _score(
            position: 0,
            specificity: specificity,
            confidence: fallback,
          ),
        ));
      }
    }
    found.sort(
      (IdentifierCandidate a, IdentifierCandidate b) =>
          b.score.compareTo(a.score),
    );
    final List<IdentifierCandidate> ranked = <IdentifierCandidate>[];
    for (final IdentifierCandidate candidate in found) {
      if (!_seen(ranked, candidate.fieldKey, candidate.value)) {
        ranked.add(candidate);
      }
    }
    return ranked;
  }
}

/// An identity field and the pattern written on its template.
typedef IdentityField = ({String fieldKey, String pattern});

/// A block of plate text and where it sits. [top] is smaller when higher.
typedef PlateBlock = ({String text, double top, double confidence});

/// One ranked identity candidate.
///
/// [blockIndex] is the originating block's index in the blocks passed to
/// [IdentifierExtraction.extract], or null when the value was found only in
/// the joined text. [blockText] is the text the value was found in.
typedef IdentifierCandidate = ({
  String fieldKey,
  String value,
  String blockText,
  int? blockIndex,
  double confidence,
  double score,
});

bool _seen(List<IdentifierCandidate> found, String fieldKey, String value) {
  return found.any(
    (IdentifierCandidate candidate) =>
        candidate.fieldKey == fieldKey && candidate.value == value,
  );
}

({double first, double span}) _extent(List<PlateBlock> blocks) {
  if (blocks.isEmpty) {
    return (first: 0, span: 0);
  }
  var first = blocks.first.top;
  var last = blocks.first.top;
  for (final PlateBlock block in blocks) {
    if (block.top < first) {
      first = block.top;
    }
    if (block.top > last) {
      last = block.top;
    }
  }
  return (first: first, span: last - first);
}

double _score({
  required double position,
  required double specificity,
  required double confidence,
}) {
  return AppConstants.processing.identifierPositionWeight * position +
      AppConstants.processing.identifierSpecificityWeight * specificity +
      AppConstants.processing.identifierConfidenceWeight * confidence;
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
