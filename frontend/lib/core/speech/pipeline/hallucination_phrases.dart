import 'word_sequence.dart';

/// What whisper writes over silence or noise when it hears no speech: the
/// closing lines of the subtitled videos it learned from (spec §30.4.7).
///
/// Data only. A phrase is compared word by word by [WordSequence.key], so
/// case and edge punctuation do not matter. Every language also carries the
/// English list, because whisper falls back to English closings.
abstract final class HallucinationPhrases {
  /// The phrases, as space-joined word keys, whisper invents in [language]
  /// (a whisper code such as `en`).
  static Set<String> forLanguage(String language) =>
      _byLanguage[language] ??= <String>{
        ..._normalised(_english),
        ..._normalised(_phrases[language] ?? const <String>[]),
      };

  /// Whether [words] say nothing but a known phrase in [language].
  static bool matches(String language, List<String> words) =>
      forLanguage(language).contains(WordSequence.keys(words).join(' '));

  static Iterable<String> _normalised(List<String> phrases) => phrases.map(
    (String phrase) => WordSequence.keys(WordSequence.words(phrase)).join(' '),
  );
}

final Map<String, Set<String>> _byLanguage = <String, Set<String>>{};

const List<String> _english = <String>[
  'you',
  'bye',
  'bye bye',
  'thanks',
  'thank you',
  'thank you very much',
  'thanks for watching',
  'thank you for watching',
  'thank you so much for watching',
  'please subscribe',
  'subscribe to my channel',
  'like and subscribe',
  'see you next time',
  'subtitles by the amara.org community',
  'subtitles by the amara org community',
];

const Map<String, List<String>> _phrases = <String, List<String>>{
  'fr': <String>[
    'merci',
    'merci beaucoup',
    "merci d'avoir regardé",
    "sous-titres réalisés par la communauté d'amara.org",
    'sous-titrage société radio-canada',
  ],
  'es': <String>[
    'gracias',
    'muchas gracias',
    'gracias por ver',
    'subtítulos realizados por la comunidad de amara.org',
    'suscríbete',
  ],
  'pt': <String>[
    'obrigado',
    'obrigada',
    'obrigado por assistir',
    'legendas pela comunidade amara.org',
  ],
  'sw': <String>['asante', 'asante sana', 'asante kwa kutazama'],
  'ar': <String>['شكرا', 'شكرا لكم', 'شكرا للمشاهدة', 'ترجمة نانسي قنقر'],
  'de': <String>[
    'danke',
    'vielen dank',
    'untertitel im auftrag des zdf',
    'untertitel der amara.org-community',
  ],
};
