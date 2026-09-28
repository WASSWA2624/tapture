import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/features/capture/domain/transcript_store.dart';

const TranscriptStore _raw = TranscriptStore(
  text: 'meter reads twelve point five',
  languageTag: 'en-GB',
  confidence: 0.87,
);

void main() {
  test('a transcript round-trips through JSON with its language and '
      'confidence', () {
    final TranscriptStore restored = TranscriptStore.fromJson(_raw.toJson());

    expect(restored.text, _raw.text);
    expect(restored.languageTag, 'en-GB');
    expect(restored.confidence, 0.87);
  });

  test('a transcript without a confidence round-trips with none', () {
    const TranscriptStore unrated = TranscriptStore(
      text: 'hello',
      languageTag: 'sw',
    );

    final TranscriptStore restored = TranscriptStore.fromJson(
      unrated.toJson(),
    );

    expect(restored.confidence, isNull);
    expect(restored.toJson()['confidence'], isNull);
  });

  test('a whole-number confidence in JSON is read as a fraction', () {
    final TranscriptStore restored = TranscriptStore.fromJson(
      const <String, Object?>{'text': 'x', 'languageTag': 'en', 'confidence': 1},
    );

    expect(restored.confidence, 1.0);
    expect(restored.confidence, isA<double>());
  });

  test('missing fields read as empty text and language', () {
    final TranscriptStore restored = TranscriptStore.fromJson(
      const <String, Object?>{},
    );

    expect(restored.text, '');
    expect(restored.languageTag, '');
    expect(restored.confidence, isNull);
  });

  test('the language stored is the one actually used, not the one asked '
      'for', () {
    const String requested = 'en';
    const TranscriptStore heard = TranscriptStore(
      text: 'habari',
      languageTag: 'sw',
    );

    expect(heard.languageTag, isNot(requested));
    expect(TranscriptStore.fromJson(heard.toJson()).languageTag, 'sw');
  });

  test('refinement writes elsewhere and never alters the raw row', () {
    final Map<String, Object?> before = _raw.toJson();

    final String refined = '${_raw.unchangedByRefinement.text} (tidied)';

    expect(identical(_raw.unchangedByRefinement, _raw), isTrue);
    expect(_raw.toJson(), before);
    expect(_raw.text, isNot(refined));
    expect(_raw.unchangedByRefinement.text, 'meter reads twelve point five');
  });
}
