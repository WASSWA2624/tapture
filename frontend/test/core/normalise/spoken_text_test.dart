import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/normalise/spoken_text.dart';

void main() {
  group('tidy', () {
    test('a dictated run reads as a typed sentence', () {
      expect(
        SpokenText.tidy('  the list   is slow ,when i scroll '),
        'The list is slow, when I scroll.',
      );
    });

    test('every sentence in the run opens with a capital', () {
      expect(
        SpokenText.tidy('it froze. then it closed? yes'),
        'It froze. Then it closed? Yes.',
      );
    });

    test('a run that already ends in punctuation gets no extra stop', () {
      expect(SpokenText.tidy('why is it slow?'), 'Why is it slow?');
      expect(SpokenText.tidy('done..'), 'Done.');
    });

    test('punctuation glued to the next word is spaced', () {
      expect(SpokenText.tidy('first,second.third'), 'First, second. Third.');
    });

    test('numbers, decimals and times are left as spoken', () {
      expect(
        SpokenText.tidy('meter reads 3.5 at 10:30'),
        'Meter reads 3.5 at 10:30.',
      );
    });

    test('a phrase keeps its case and gets no stop', () {
      expect(SpokenText.tidy(' water   pump ', sentences: false), 'water pump');
    });

    test('a lone i becomes I only in English', () {
      expect(
        SpokenText.tidy("i think i'm stuck", sentences: false),
        "I think I'm stuck",
      );
      expect(SpokenText.tidy('i', sentences: false, languageTag: 'lg'), 'i');
    });

    test('nothing heard stays empty', () {
      expect(SpokenText.tidy('   '), '');
    });
  });

  group('insert', () {
    test('into an empty field it is a full sentence', () {
      final ({String text, int caret}) next = SpokenText.insert(
        text: '',
        spoken: 'the camera freezes',
      );
      expect(next.text, 'The camera freezes.');
      expect(next.caret, next.text.length);
    });

    test('after a finished sentence it opens a new one with a space', () {
      final ({String text, int caret}) next = SpokenText.insert(
        text: 'It is slow.',
        spoken: 'also it crashes',
      );
      expect(next.text, 'It is slow. Also it crashes.');
    });

    test('after an unfinished sentence it carries on', () {
      final ({String text, int caret}) next = SpokenText.insert(
        text: 'It is slow when',
        spoken: 'i scroll',
      );
      expect(next.text, 'It is slow when I scroll.');
    });

    test('in the middle of text it is spaced and not closed', () {
      final ({String text, int caret}) next = SpokenText.insert(
        text: 'The list is slow.',
        spoken: 'very',
        start: 12,
        end: 12,
      );
      expect(next.text, 'The list is very slow.');
      expect(next.caret, 'The list is very'.length);
    });

    test('a selection is replaced by the words spoken', () {
      final ({String text, int caret}) next = SpokenText.insert(
        text: 'The list is slow.',
        spoken: 'map',
        start: 4,
        end: 8,
      );
      expect(next.text, 'The map is slow.');
    });

    test('a phrase field gets no capital and no stop', () {
      final ({String text, int caret}) next = SpokenText.insert(
        text: 'water',
        spoken: 'pump',
        sentences: false,
      );
      expect(next.text, 'water pump');
    });

    test('the limit is kept by cutting at a word boundary', () {
      final ({String text, int caret}) next = SpokenText.insert(
        text: 'Hi.',
        spoken: 'this is far too long',
        maxLength: 15,
      );
      expect(next.text.length, lessThanOrEqualTo(15));
      expect(next.text, 'Hi. This is far');
    });

    test('a full field is left as it was', () {
      final ({String text, int caret}) next = SpokenText.insert(
        text: 'abcde',
        spoken: 'more',
        maxLength: 5,
      );
      expect(next.text, 'abcde');
      expect(next.caret, 5);
    });

    test('silence changes nothing', () {
      final ({String text, int caret}) next = SpokenText.insert(
        text: 'Keep me',
        spoken: '  ',
      );
      expect(next.text, 'Keep me');
    });
  });
}
