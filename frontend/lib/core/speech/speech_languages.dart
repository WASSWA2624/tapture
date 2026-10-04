/// The whisper language code for the BCP 47 [tag], or null when the
/// multilingual whisper models do not know the language.
///
/// The primary subtag decides, so `en-UG` is `en` and `sw-KE` is `sw`;
/// Luganda (`lg`) has no whisper model and returns null. A session always
/// passes the result to the engine, never `''` or `'auto'`.
String? whisperLanguageFor(String tag) {
  final String primary = tag.trim().split(_subtagSeparator).first.toLowerCase();
  final String code = _aliases[primary] ?? primary;
  return _whisperLanguages.contains(code) ? code : null;
}

/// What separates the subtags of a language tag.
final RegExp _subtagSeparator = RegExp('[-_]');

/// BCP 47 subtags whisper spells differently.
const Map<String, String> _aliases = <String, String>{
  'fil': 'tl',
  'in': 'id',
  'iw': 'he',
  'ji': 'yi',
  'jv': 'jw',
  'nb': 'no',
};

/// Every language whisper.cpp 1.9.4 decodes (`g_lang` in `src/whisper.cpp`).
const Set<String> _whisperLanguages = <String>{
  'en', 'zh', 'de', 'es', 'ru', 'ko', 'fr', 'ja', 'pt', 'tr', //
  'pl', 'ca', 'nl', 'ar', 'sv', 'it', 'id', 'hi', 'fi', 'vi', //
  'he', 'uk', 'el', 'ms', 'cs', 'ro', 'da', 'hu', 'ta', 'no', //
  'th', 'ur', 'hr', 'bg', 'lt', 'la', 'mi', 'ml', 'cy', 'sk', //
  'te', 'fa', 'lv', 'bn', 'sr', 'az', 'sl', 'kn', 'et', 'mk', //
  'br', 'eu', 'is', 'hy', 'ne', 'mn', 'bs', 'kk', 'sq', 'sw', //
  'gl', 'mr', 'pa', 'si', 'km', 'sn', 'yo', 'so', 'af', 'oc', //
  'ka', 'be', 'tg', 'sd', 'gu', 'am', 'yi', 'lo', 'uz', 'fo', //
  'ht', 'ps', 'tk', 'nn', 'mt', 'sa', 'lb', 'my', 'bo', 'tl', //
  'mg', 'as', 'tt', 'haw', 'ln', 'ha', 'ba', 'jw', 'su', 'yue', //
};
