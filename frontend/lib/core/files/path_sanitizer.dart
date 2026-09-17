import 'package:tapture/core/errors/failure.dart';

/// Length cap for one path segment. Kept as a literal so it can be a default
/// argument; [path_sanitizer_test] asserts it matches
/// [AppConstants.folders.maxSegmentLength].
const int kMaxPathSegment = 80;

/// Turns arbitrary user text into one safe path segment.
///
/// The type this file is named for (FE-STR-06). The contract name is
/// [sanitiseSegment].
abstract final class PathSanitizer {
  /// Strips accents, turns whitespace into hyphens, removes reserved and
  /// non-printing characters, and caps length. Traversal, absolute paths,
  /// drive prefixes, device names and empty results are refused.
  static String sanitiseSegment(
    String input, {
    int maxLength = kMaxPathSegment,
  }) {
    if (_isHostile(input)) {
      throw const ValidationFailure(
        message: 'That name is not a valid folder.',
        recoveryAction: 'Choose a name without slashes that point elsewhere.',
      );
    }
    String segment = _stripAccents(input);
    segment = segment.replaceAll(_separator, '-');
    segment = segment.replaceAll(_reservedChar, '');
    segment = segment.replaceAll(_repeatHyphen, '-');
    segment = segment.replaceAll(_edgeHyphen, '');
    if (segment.length > maxLength) {
      segment = segment.substring(0, maxLength).replaceAll(_edgeHyphen, '');
    }
    if (segment.isEmpty || _isDeviceName(segment)) {
      throw const ValidationFailure(
        message: 'That name is not a valid folder.',
        recoveryAction: 'Choose a name with letters or digits.',
      );
    }
    return segment;
  }
}

/// Strips accents, turns whitespace into hyphens, removes reserved and
/// non-printing characters, and caps length.
///
/// Traversal (`..`), absolute paths, drive prefixes, device names and empty
/// results throw [ValidationFailure] rather than being rewritten into a
/// neighbour folder (FE-SEC-06).
String sanitiseSegment(String input, {int maxLength = kMaxPathSegment}) {
  return PathSanitizer.sanitiseSegment(input, maxLength: maxLength);
}

bool _isHostile(String input) {
  final String trimmed = input.trim();
  if (trimmed.isEmpty) {
    return true;
  }
  if (trimmed == '.' || trimmed == '..') {
    return true;
  }
  if (trimmed.startsWith('/') || trimmed.startsWith(r'\')) {
    return true;
  }
  if (_drivePrefix.hasMatch(trimmed) || trimmed.startsWith(r'\\')) {
    return true;
  }
  for (final String part in trimmed.split(_slash)) {
    if (part == '.' || part == '..') {
      return true;
    }
  }
  return false;
}

bool _isDeviceName(String segment) {
  final String lower = segment.toLowerCase();
  final int dot = lower.indexOf('.');
  final String stem = dot == -1 ? lower : lower.substring(0, dot);
  return _deviceNames.contains(stem);
}

String _stripAccents(String input) {
  final StringBuffer buffer = StringBuffer();
  for (final int rune in input.runes) {
    buffer.write(_latinAscii[rune] ?? String.fromCharCode(rune));
  }
  return buffer.toString().replaceAll(_combining, '');
}

final RegExp _separator = RegExp(r'[\s/\\]+');
final RegExp _reservedChar = RegExp(r'[^A-Za-z0-9-]');
final RegExp _repeatHyphen = RegExp(r'-{2,}');
final RegExp _edgeHyphen = RegExp(r'^-+|-+$');
final RegExp _slash = RegExp(r'[/\\]+');
final RegExp _drivePrefix = RegExp(r'^[A-Za-z]:');
final RegExp _combining = RegExp(r'[\u0300-\u036f]');

const Set<String> _deviceNames = <String>{
  'con',
  'prn',
  'aux',
  'nul',
  'com1',
  'com2',
  'com3',
  'com4',
  'com5',
  'com6',
  'com7',
  'com8',
  'com9',
  'lpt1',
  'lpt2',
  'lpt3',
  'lpt4',
  'lpt5',
  'lpt6',
  'lpt7',
  'lpt8',
  'lpt9',
};

/// Latin letters that NFC stores as a single rune, mapped to ASCII.
const Map<int, String> _latinAscii = <int, String>{
  0x00C0: 'A',
  0x00C1: 'A',
  0x00C2: 'A',
  0x00C3: 'A',
  0x00C4: 'A',
  0x00C5: 'A',
  0x00C6: 'AE',
  0x00C7: 'C',
  0x00C8: 'E',
  0x00C9: 'E',
  0x00CA: 'E',
  0x00CB: 'E',
  0x00CC: 'I',
  0x00CD: 'I',
  0x00CE: 'I',
  0x00CF: 'I',
  0x00D0: 'D',
  0x00D1: 'N',
  0x00D2: 'O',
  0x00D3: 'O',
  0x00D4: 'O',
  0x00D5: 'O',
  0x00D6: 'O',
  0x00D8: 'O',
  0x00D9: 'U',
  0x00DA: 'U',
  0x00DB: 'U',
  0x00DC: 'U',
  0x00DD: 'Y',
  0x00E0: 'a',
  0x00E1: 'a',
  0x00E2: 'a',
  0x00E3: 'a',
  0x00E4: 'a',
  0x00E5: 'a',
  0x00E6: 'ae',
  0x00E7: 'c',
  0x00E8: 'e',
  0x00E9: 'e',
  0x00EA: 'e',
  0x00EB: 'e',
  0x00EC: 'i',
  0x00ED: 'i',
  0x00EE: 'i',
  0x00EF: 'i',
  0x00F1: 'n',
  0x00F2: 'o',
  0x00F3: 'o',
  0x00F4: 'o',
  0x00F5: 'o',
  0x00F6: 'o',
  0x00F8: 'o',
  0x00F9: 'u',
  0x00FA: 'u',
  0x00FB: 'u',
  0x00FC: 'u',
  0x00FD: 'y',
  0x00FF: 'y',
  0x0152: 'OE',
  0x0153: 'oe',
  0x0160: 'S',
  0x0161: 's',
  0x0178: 'Y',
  0x017D: 'Z',
  0x017E: 'z',
};
