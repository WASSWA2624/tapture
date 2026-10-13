/// Maps a phrase onto a choice without discarding the phrase.
final class Choices {
  /// Reads template option strings or objects without losing their aliases.
  static List<ChoiceOption> options(List<Object?> raw) => <ChoiceOption>[
    for (final Object? option in raw)
      if (option is String)
        (label: option, code: null, aliases: const <String>[])
      else if (option is Map && option['label'] is String)
        (
          label: option['label'] as String,
          code: option['code'] is String ? option['code'] as String : null,
          aliases: option['aliases'] is List
              ? <String>[
                  for (final Object? alias in option['aliases'] as List)
                    if (alias is String) alias,
                ]
              : const <String>[],
        ),
  ];

  /// Label, code, then alias. The original sentence is kept on the result.
  static ChoiceMatch? match(String raw, {required List<ChoiceOption> options}) {
    final String folded = raw.trim().toLowerCase();
    if (folded.isEmpty) {
      return null;
    }
    for (final ChoiceOption option in options) {
      if (option.label.toLowerCase() == folded) {
        return (label: option.label, original: raw);
      }
      final String? code = option.code;
      if (code != null && code.toLowerCase() == folded) {
        return (label: option.label, original: raw);
      }
    }
    for (final ChoiceOption option in options) {
      for (final String alias in option.aliases) {
        if (alias.isEmpty) {
          continue;
        }
        if (alias.toLowerCase() == folded || _containsPhrase(folded, alias)) {
          return (label: option.label, original: raw);
        }
      }
    }
    return null;
  }
}

/// An option from the options editor: label, optional code, aliases.
typedef ChoiceOption = ({String label, String? code, List<String> aliases});

/// The chosen label and the sentence that produced it.
typedef ChoiceMatch = ({String label, String original});

bool _containsPhrase(String text, String alias) {
  final String needle = alias.trim().toLowerCase();
  if (needle.isEmpty) {
    return false;
  }
  return RegExp('\\b${RegExp.escape(needle)}\\b').hasMatch(text);
}
