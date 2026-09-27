import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/normalise/search_text.dart';

void main() {
  group('foldSearchText', () {
    test('folds case and Latin diacritics', () {
      expect(foldSearchText('Café Ñandú'), 'cafe nandu');
      expect(foldSearchText('Straße Œuvre'), 'strasse oeuvre');
    });

    test('leaves other scripts as they are', () {
      expect(foldSearchText('Ензи 東京'), 'ензи 東京');
    });
  });

  group('searchWords', () {
    test('splits a code into its letters and its number', () {
      expect(searchWords('UNI-001'), <String>['uni', '001']);
    });

    test('drops words too short to mean anything, keeping digits', () {
      expect(searchWords('I am going to count 5 laptops'), <String>[
        'going',
        'count',
        '5',
        'laptops',
      ]);
    });

    test('folds as it splits', () {
      expect(searchWords('Évaluation, Café!'), <String>['evaluation', 'cafe']);
    });

    test('an empty query has no words', () {
      expect(searchWords('  - '), isEmpty);
    });
  });

  group('searchStem', () {
    test('strips one common English ending', () {
      expect(searchStem('offices'), 'offic');
      expect(searchStem('laptops'), 'laptop');
      expect(searchStem('counting'), 'count');
      expect(searchStem('verified'), 'verifi');
    });

    test('a stem is a prefix of the word it came from', () {
      for (final String word in <String>['offices', 'office', 'assets']) {
        expect(word.startsWith(searchStem(word)), isTrue);
      }
    });

    test('keeps at least three letters', () {
      expect(searchStem('bus'), 'bus');
      expect(searchStem('used'), 'used');
      expect(searchStem('ring'), 'ring');
    });
  });
}
