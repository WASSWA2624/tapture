import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/features/templates/domain/domain.dart' show FieldDef;

import 'ocr_field_value.dart';
import 'ocr_mapped_field.dart';
import 'ocr_mapping_outcome.dart';
import 'ocr_mapping_profile.dart';
import 'ocr_parameter_block.dart';

/// Maps photographed parameter labels onto the captured template's fields.
/// Exact labels, keys and output columns support mapping; no value is guessed.
abstract final class OcrFieldMapping {
  /// Maps text and spatial blocks into unapproved candidates with their source.
  static OcrMappingOutcome extract({
    required String text,
    required List<OcrParameterBlock> blocks,
    required OcrMappingProfile profile,
    Set<String>? targetKeys,
  }) {
    final List<FieldDef> fields = profile.fields;
    final List<_Line> lines = <_Line>[
      for (var index = 0; index < blocks.length; index++)
        for (final String line in blocks[index].text.split(RegExp(r'[\r\n]+')))
          if (line.trim().isNotEmpty)
            (text: line, index: index, confidence: blocks[index].confidence),
    ];
    for (final String line in text.split(RegExp(r'[\r\n]+'))) {
      if (line.trim().isNotEmpty &&
          !lines.any((_Line existing) => existing.text.trim() == line.trim())) {
        lines.add((
          text: line,
          index: null,
          confidence: AppConstants.processing.identifierFallbackConfidence,
        ));
      }
    }
    final Map<String, FieldDef> byKey = <String, FieldDef>{
      for (final FieldDef field in fields)
        if (targetKeys == null || targetKeys.contains(field.fieldKey))
          field.fieldKey: field,
    };
    final List<OcrMappedField> candidates = <OcrMappedField>[];
    final Set<String> labelled = <String>{};
    final Set<String> findings = <String>{};
    final List<List<_Label>> labels = <List<_Label>>[
      for (final _Line line in lines) _labels(line.text, profile),
    ];
    for (var lineIndex = 0; lineIndex < lines.length; lineIndex++) {
      final _Line line = lines[lineIndex];
      final List<_Label> matches = labels[lineIndex];
      for (var matchIndex = 0; matchIndex < matches.length; matchIndex++) {
        final _Label match = matches[matchIndex];
        labelled.addAll(match.keys);
        if (match.keys.length != 1) {
          for (final String key in match.keys) {
            if (!byKey.containsKey(key)) continue;
            findings.add(
              'The photographed label for $key is ambiguous. Review the evidence.',
            );
          }
          continue;
        }
        final String key = match.keys.single;
        if (!byKey.containsKey(key)) continue;
        final int end = matchIndex + 1 < matches.length
            ? matches[matchIndex + 1].start
            : line.text.length;
        String raw = _trim(line.text.substring(match.end, end));
        _Line origin = line;
        if (raw.isEmpty && matches.length == 1) {
          final _Line? adjacent = _adjacent(lineIndex, lines, labels, blocks);
          if (adjacent != null) {
            raw = _trim(adjacent.text);
            origin = adjacent;
          }
        }
        if (raw.isEmpty) {
          findings.add('The photographed value for $key needs manual review.');
          continue;
        }
        final String? normalised = OcrFieldValue.read(raw, byKey[key]!);
        if (normalised == null) {
          findings.add('The photographed value for $key needs manual review.');
          continue;
        }
        if (candidates.any(
          (OcrMappedField prior) => prior.fieldKey == key && prior.value == raw,
        )) {
          continue;
        }
        candidates.add((
          fieldKey: key,
          value: raw,
          normalised: normalised,
          blockIndex: origin.index,
          snippet: origin.text,
          confidence: origin.confidence.isFinite
              ? origin.confidence.clamp(0, 1).toDouble()
              : 0,
        ));
      }
    }
    return (
      candidates: candidates,
      labelledKeys: labelled,
      findings: findings.toList(),
    );
  }
}

typedef _Line = ({String text, int? index, double confidence});
typedef _Label = ({int start, int end, Set<String> keys});

List<_Label> _labels(String text, OcrMappingProfile profile) {
  final List<_Label> found = <_Label>[
    for (final match in profile.matches(text))
      (start: match.start, end: match.end, keys: <String>{match.key}),
  ];
  found.sort((_Label a, _Label b) {
    final int start = a.start.compareTo(b.start);
    return start == 0 ? b.end.compareTo(a.end) : start;
  });
  final List<_Label> selected = <_Label>[];
  for (final _Label label in found) {
    if (selected.isNotEmpty && label.start < selected.last.end) {
      final _Label prior = selected.last;
      if (prior.start == label.start && prior.end == label.end) {
        prior.keys.addAll(label.keys);
      }
      continue;
    }
    selected.add(label);
  }
  return selected;
}

String _trim(String raw) => raw
    .replaceFirst(RegExp(r'^\s*[:=|]*\s*'), '')
    .replaceFirst(RegExp(r'\s*[;|,]+\s*$'), '')
    .trim();

_Line? _adjacent(
  int index,
  List<_Line> lines,
  List<List<_Label>> labels,
  List<OcrParameterBlock> blocks,
) {
  final _Line line = lines[index];
  final int? blockIndex = line.index;
  if (blockIndex == null) {
    return index + 1 < lines.length && labels[index + 1].isEmpty
        ? lines[index + 1]
        : null;
  }
  final OcrParameterBlock label = blocks[blockIndex];
  final List<({double gap, _Line line})> beside =
      <({double gap, _Line line})>[];
  final List<({double gap, _Line line})> below = <({double gap, _Line line})>[];
  for (var other = 0; other < lines.length; other++) {
    if (other == index || labels[other].isNotEmpty) continue;
    final _Line candidate = lines[other];
    final int? candidateIndex = candidate.index;
    if (candidateIndex == null) continue;
    if (candidateIndex == blockIndex && other == index + 1) return candidate;
    final OcrParameterBlock value = blocks[candidateIndex];
    if (value.left >= label.right &&
        value.left - label.right <= label.right - label.left &&
        value.top < label.bottom &&
        value.bottom > label.top) {
      beside.add((gap: value.left - label.right, line: candidate));
    } else if (value.top >= label.bottom &&
        value.top - label.bottom <= label.bottom - label.top &&
        value.left < label.right &&
        value.right > label.left) {
      below.add((gap: value.top - label.bottom, line: candidate));
    }
  }
  final List<({double gap, _Line line})> possible = beside.isEmpty
      ? below
      : beside;
  possible.sort((a, b) => a.gap.compareTo(b.gap));
  // Equally near cells have no reliable owner; leave the decision to review.
  if (possible.isEmpty ||
      (possible.length > 1 && possible.first.gap == possible[1].gap)) {
    return null;
  }
  return possible.first.line;
}
