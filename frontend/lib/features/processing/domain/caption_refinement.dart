/// Rewords a caption without adding a fact the raw text did not contain.
///
/// A refinement that introduces an identifier, a quantity or a date absent
/// from the raw text is rejected. The raw row is never edited.
final class CaptionRefinement {
  /// Accepts [proposed] only when it stays inside [raw].
  static CaptionOutcome refine({
    required String raw,
    required String proposed,
  }) {
    final String cleaned = proposed.trim();
    if (cleaned.isEmpty) {
      return (
        accepted: false,
        refined: null,
        reason: 'The refinement is empty.',
      );
    }
    final String? invented = _invented(raw, cleaned);
    if (invented != null) {
      return (accepted: false, refined: null, reason: invented);
    }
    return (accepted: true, refined: cleaned, reason: null);
  }
}

/// Whether a refinement may be stored beside the raw caption.
typedef CaptionOutcome = ({bool accepted, String? refined, String? reason});

String? _invented(String raw, String proposed) {
  final String rawFolded = raw.toLowerCase();
  // Any number the raw text does not have is a new fact, whatever unit or
  // word follows it: a quantity, a reading, a count or part of a date.
  final Set<String> rawNumbers = <String>{
    for (final RegExpMatch match in _number.allMatches(raw)) match.group(0)!,
  };
  for (final RegExpMatch match in _number.allMatches(proposed)) {
    if (!rawNumbers.contains(match.group(0))) {
      return 'The refinement adds a number that is not in the raw text.';
    }
  }
  for (final RegExpMatch match in _identifier.allMatches(proposed)) {
    final String token = match.group(0) ?? '';
    if (!raw.toLowerCase().contains(token.toLowerCase())) {
      return 'The refinement adds an identifier that is not in the raw text.';
    }
  }
  for (final RegExpMatch match in _quantity.allMatches(proposed)) {
    final String token = (match.group(0) ?? '').toLowerCase();
    if (!rawFolded.contains(token.replaceAll(RegExp(r'\s+'), ''))) {
      final String tight = token.replaceAll(RegExp(r'\s+'), '');
      final String rawTight = rawFolded.replaceAll(RegExp(r'\s+'), '');
      if (!rawTight.contains(tight)) {
        return 'The refinement adds a quantity that is not in the raw text.';
      }
    }
  }
  for (final RegExpMatch match in _date.allMatches(proposed)) {
    final String token = (match.group(0) ?? '').toLowerCase();
    if (!rawFolded.contains(token)) {
      return 'The refinement adds a date that is not in the raw text.';
    }
  }
  return null;
}

final RegExp _number = RegExp(r'\d+(?:[.,]\d+)?');

final RegExp _identifier = RegExp(
  r'\b(?:SN[0-9A-Z]{4,}|[A-Z]{1,4}-\d{3,}|\d{4,})\b',
);

final RegExp _quantity = RegExp(
  r'\b\d+(?:\.\d+)?\s?(?:l|litre|litres|liter|kg|v|volts|mm|cm|m)\b',
  caseSensitive: false,
);

final RegExp _date = RegExp(
  r'\b(?:\d{1,2}[/-]\d{1,2}[/-]\d{2,4}|(?:19|20)\d{2}|jan|feb|mar|apr|may|jun|jul|aug|sep|sept|oct|nov|dec)[a-z]*\b',
  caseSensitive: false,
);
