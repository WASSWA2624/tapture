import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/files/path_sanitizer.dart';

void main() {
  group('hostile inputs', () {
    const List<String> inputs = <String>[
      '',
      '   ',
      '.',
      '..',
      '../etc',
      'foo/../bar',
      '/etc/passwd',
      r'\Windows',
      r'C:\Windows',
      'C:Windows',
      r'\\server\share',
      'CON',
      'con',
      'PRN',
      'AUX',
      'NUL',
      'COM1',
      'LPT9',
      '😀',
    ];

    for (final String input in inputs) {
      test('refuses "$input"', () {
        expect(() => sanitiseSegment(input), throwsA(isA<ValidationFailure>()));
      });
    }
  });

  group('display names', () {
    const Map<String, String> cases = <String, String>{
      'Kampala': 'Kampala',
      'hello world': 'hello-world',
      'Medical / Equipment': 'Medical-Equipment',
      'Café Project': 'Cafe-Project',
      'Kasubi HC IV': 'Kasubi-HC-IV',
      'Kasubi-HC-IV': 'Kasubi-HC-IV',
      '  --Wing--  ': 'Wing',
      'hello 😀 world': 'hello-world',
    };

    for (final MapEntry<String, String> entry in cases.entries) {
      test('"${entry.key}" becomes "${entry.value}"', () {
        expect(sanitiseSegment(entry.key), entry.value);
      });
    }

    test('a 300-character name is capped at kMaxPathSegment', () {
      expect(kMaxPathSegment, AppConstants.folders.maxSegmentLength);
      expect(sanitiseSegment('a' * 300), 'a' * kMaxPathSegment);
    });

    test('a custom cap is honoured', () {
      expect(sanitiseSegment('abcdef', maxLength: 3), 'abc');
    });
  });
}
