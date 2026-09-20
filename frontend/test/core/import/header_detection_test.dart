import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/import/header_detection.dart';

void main() {
  test('a title block above the header is not chosen as the header', () {
    final HeaderGuess guess = HeaderDetection.choose(const <List<String>>[
      <String>['Equipment Register', '', ''],
      <String>['', '', ''],
      <String>['Asset tag', 'Serial', 'Status'],
      <String>['A-1', '100', 'Active'],
    ]);
    expect(guess.rowNumber, 3);
    expect(guess.labels, <String>['Asset tag', 'Serial', 'Status']);
    expect(guess.isSuggestion, isTrue);
  });

  test('a header on the first row is kept when there is no title block', () {
    final HeaderGuess guess = HeaderDetection.choose(const <List<String>>[
      <String>['Asset tag', 'Serial', 'Status'],
      <String>['A-1', '100', 'Active'],
    ]);
    expect(guess.rowNumber, 1);
    expect(guess.labels, <String>['Asset tag', 'Serial', 'Status']);
    expect(guess.isSuggestion, isTrue);
  });
}
