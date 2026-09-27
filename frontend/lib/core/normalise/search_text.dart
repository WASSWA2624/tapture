import 'package:tapture/core/constants/app_constants.dart';

/// Case-folds [input] and strips common Latin diacritics, so "Café" matches
/// "cafe" without a new package. Every search in the app folds through this.
String foldSearchText(String input) {
  String text = input.toLowerCase();
  text = text.replaceAll('ß', 'ss');
  text = text.replaceAll('æ', 'ae');
  text = text.replaceAll('œ', 'oe');
  final StringBuffer out = StringBuffer();
  for (final int rune in text.runes) {
    if (rune >= 0x0300 && rune <= 0x036F) {
      continue;
    }
    out.writeCharCode(_baseLetter(rune));
  }
  return out.toString();
}

/// The folded words of [input] worth matching on: split on anything that is
/// not a letter or a digit, keeping a word shorter than
/// `AppConstants.search.minWordLength` only when it holds a digit, as the
/// "001" of a code does, and dropping the English connectives a plain
/// description carries ("the", "and"…), which would match everything.
List<String> searchWords(String input) {
  return <String>[
    for (final String word in foldSearchText(input).split(_separators))
      if ((word.length >= AppConstants.search.minWordLength ||
              (word.isNotEmpty && word.contains(_digit))) &&
          !_connectives.contains(word))
        word,
  ];
}

/// [word] without one trailing `ing`, `ed`, `es` or `s`, when at least three
/// letters remain, so "offices" and "office" meet at "offic". Words in other
/// languages keep their form and still match by prefix.
String searchStem(String word) {
  for (final String suffix in _suffixes) {
    if (word.endsWith(suffix) && word.length - suffix.length >= _minimumStem) {
      return word.substring(0, word.length - suffix.length);
    }
  }
  return word;
}

final RegExp _separators = RegExp(r'[^\p{L}\p{N}]+', unicode: true);
final RegExp _digit = RegExp(r'\p{N}', unicode: true);
const List<String> _suffixes = <String>['ing', 'ed', 'es', 's'];

/// English words that join a description rather than describe the work.
const Set<String> _connectives = <String>{
  'and',
  'the',
  'for',
  'with',
  'from',
  'into',
  'that',
  'this',
  'are',
  'was',
  'our',
  'all',
  'any',
  'per',
  'its',
  'their',
  'going',
  'will',
};
const int _minimumStem = 3;

int _baseLetter(int rune) {
  if (rune < 0x00C0) {
    return rune;
  }
  if (rune >= 0x00E0 && rune <= 0x00E5) {
    return 0x61;
  }
  if (rune == 0x00E7) {
    return 0x63;
  }
  if (rune >= 0x00E8 && rune <= 0x00EB) {
    return 0x65;
  }
  if (rune >= 0x00EC && rune <= 0x00EF) {
    return 0x69;
  }
  if (rune == 0x00F1) {
    return 0x6E;
  }
  if (rune >= 0x00F2 && rune <= 0x00F6) {
    return 0x6F;
  }
  if (rune == 0x00F8) {
    return 0x6F;
  }
  if (rune >= 0x00F9 && rune <= 0x00FC) {
    return 0x75;
  }
  if (rune == 0x00FD || rune == 0x00FF) {
    return 0x79;
  }
  if (rune >= 0x0100 && rune <= 0x0105) {
    return 0x61;
  }
  if (rune >= 0x0106 && rune <= 0x010D) {
    return 0x63;
  }
  if (rune >= 0x010E && rune <= 0x0111) {
    return 0x64;
  }
  if (rune >= 0x0112 && rune <= 0x011B) {
    return 0x65;
  }
  if (rune >= 0x011C && rune <= 0x0123) {
    return 0x67;
  }
  if (rune >= 0x0124 && rune <= 0x0127) {
    return 0x68;
  }
  if (rune >= 0x0128 && rune <= 0x0131) {
    return 0x69;
  }
  if (rune >= 0x0134 && rune <= 0x0135) {
    return 0x6A;
  }
  if (rune >= 0x0136 && rune <= 0x0138) {
    return 0x6B;
  }
  if (rune >= 0x0139 && rune <= 0x0142) {
    return 0x6C;
  }
  if (rune >= 0x0143 && rune <= 0x014B) {
    return 0x6E;
  }
  if (rune >= 0x014C && rune <= 0x0151) {
    return 0x6F;
  }
  if (rune >= 0x0154 && rune <= 0x0159) {
    return 0x72;
  }
  if (rune >= 0x015A && rune <= 0x0161) {
    return 0x73;
  }
  if (rune >= 0x0162 && rune <= 0x0167) {
    return 0x74;
  }
  if (rune >= 0x0168 && rune <= 0x0173) {
    return 0x75;
  }
  if (rune >= 0x0174 && rune <= 0x0175) {
    return 0x77;
  }
  if (rune >= 0x0176 && rune <= 0x0178) {
    return 0x79;
  }
  if (rune >= 0x0179 && rune <= 0x017E) {
    return 0x7A;
  }
  return rune;
}
