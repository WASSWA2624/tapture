import 'dart:convert';
import 'dart:io';

/// Regenerates the development pseudo-locale while preserving ICU syntax.
/// `--check` refuses a stale catalogue without modifying it.
void main(List<String> args) {
  final File source = File('lib/core/copy/l10n/app_en.arb');
  final Map<String, Object?> catalog = Map<String, Object?>.from(
    jsonDecode(source.readAsStringSync()) as Map,
  );
  final Map<String, Object?> pseudo = <String, Object?>{
    for (final MapEntry<String, Object?> entry in catalog.entries)
      entry.key: entry.key == '@@locale'
          ? 'en_XA'
          : entry.key.startsWith('@') || entry.value is! String
          ? entry.value
          : pseudoMessage(entry.value! as String),
  };
  final String expected =
      '${const JsonEncoder.withIndent('  ').convert(pseudo)}\n';
  final File target = File('lib/core/copy/l10n/app_en_XA.arb');
  if (args.contains('--check')) {
    if (!target.existsSync() || target.readAsStringSync() != expected) {
      stderr.writeln(
        'Pseudo-locale is stale: dart run tool/generate_pseudo_locale.dart',
      );
      exitCode = 1;
    }
  } else {
    target.writeAsStringSync(expected);
  }
}

/// Expands each visible message segment by at least 35 percent. Placeholders
/// remain verbatim, so names, values and other user data are unchanged.
String pseudoMessage(String message) => _PseudoParser(message).run();

final class _PseudoParser {
  _PseudoParser(this.source);
  final String source;
  int offset = 0;

  String run({bool nested = false}) {
    final StringBuffer result = StringBuffer();
    final StringBuffer text = StringBuffer();
    void flush() {
      final String segment = text.toString();
      text.clear();
      if (!RegExp('[A-Za-z]').hasMatch(segment)) {
        result.write(segment);
        return;
      }
      const Map<String, String> accents = <String, String>{
        'a': 'á',
        'e': 'é',
        'i': 'í',
        'o': 'ó',
        'u': 'ú',
        'A': 'Á',
        'E': 'É',
        'I': 'Í',
        'O': 'Ó',
        'U': 'Ú',
      };
      final int expansion = (segment.runes.length * .35).ceil();
      result.write(segment.split('').map((String c) => accents[c] ?? c).join());
      result.write('·' * expansion);
    }

    while (offset < source.length) {
      final String character = source[offset];
      if (character == '}' && nested) break;
      if (character == "'") {
        // ICU escaped braces and apostrophes are structural, not message text.
        final int start = offset++;
        if (offset < source.length && source[offset] == "'") {
          offset++;
        } else {
          while (offset < source.length && source[offset++] != "'") {}
        }
        text.write(source.substring(start, offset));
        continue;
      }
      if (character != '{') {
        text.write(character);
        offset++;
        continue;
      }
      flush();
      final int start = offset;
      final Match? complex = RegExp(
        r'\{\w+\s*,\s*(?:plural|select|selectordinal)\s*,\s*',
      ).matchAsPrefix(source, offset);
      if (complex == null) {
        final int end = source.indexOf('}', offset);
        if (end < 0) throw const FormatException('Unclosed ICU placeholder');
        offset = end + 1;
        result.write(source.substring(start, offset));
        continue;
      }
      offset = complex.end;
      result.write(source.substring(start, offset));
      while (offset < source.length && source[offset] != '}') {
        final int opening = source.indexOf('{', offset);
        if (opening < 0) throw const FormatException('Unclosed ICU choice');
        result.write(source.substring(offset, opening + 1));
        offset = opening + 1;
        result.write(run(nested: true));
        if (offset >= source.length) {
          throw const FormatException('Unclosed ICU branch');
        }
        result.write(source[offset++]);
        while (offset < source.length &&
            RegExp(r'\s').hasMatch(source[offset])) {
          result.write(source[offset++]);
        }
      }
      if (offset >= source.length) {
        throw const FormatException('Unclosed ICU choice');
      }
      result.write(source[offset++]);
    }
    flush();
    return result.toString();
  }
}
