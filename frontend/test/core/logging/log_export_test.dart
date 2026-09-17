import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/logging/log_export.dart';
import 'package:tapture/core/logging/logger.dart';

void main() {
  late Logger previous;

  setUp(() {
    previous = Logger.current;
  });

  tearDown(() {
    Logger.current = previous;
  });

  test('the export names the file with the date and the device id', () async {
    final Directory into = Directory.systemTemp.createTempSync('tapture-exp-');
    addTearDown(() {
      if (into.existsSync()) {
        into.deleteSync(recursive: true);
      }
    });

    final Logger logger = Logger(
      clock: () => DateTime.utc(2026, 9, 17, 8),
      deviceId: 'device-one',
    );
    Logger.current = logger;
    logger.info('net', 'hello');

    final Result<File> result = await exportLog(into: into);
    final File file = result.fold((_) => throw StateError('export failed'), (
      File value,
    ) {
      return value;
    });

    expect(file.existsSync(), isTrue);
    expect(file.uri.pathSegments.last, 'tapture-log-2026-09-17-device-one.txt');
    expect(file.readAsStringSync(), contains('hello'));
    expect(file.readAsStringSync(), contains('net'));
    expect(file.readAsStringSync(), contains('2026-09-17'));
  });

  test('the exported file matches no secret pattern', () async {
    final Directory into = Directory.systemTemp.createTempSync('tapture-exp-');
    addTearDown(() {
      if (into.existsSync()) {
        into.deleteSync(recursive: true);
      }
    });

    final File yaml = File('tool/secret_patterns.yaml');
    expect(yaml.existsSync(), isTrue);

    final Logger logger = Logger(patternsYaml: yaml.readAsStringSync());
    Logger.current = logger;
    logger.info('net', 'sk-abcdefghijklmnopqrstuvwxyz12');
    logger.info('net', 'bearer 0123456789abcdef');
    logger.info('net', '-----BEGIN PRIVATE KEY-----');
    logger.info('net', 'postgres://u:p@localhost');
    logger.info('net', 'A'.padRight(80, 'A'));
    logger.info('net', 'caption: field notes');
    logger.info('net', 'transcript: spoken words');

    final Result<File> result = await exportLog(into: into);
    final File file = result.fold((_) => throw StateError('export failed'), (
      File value,
    ) {
      return value;
    });
    final String body = file.readAsStringSync();

    for (final RegExp pattern in _patternsFrom(yaml.readAsStringSync())) {
      expect(pattern.hasMatch(body), isFalse);
    }
    expect(body, isNot(contains('field notes')));
    expect(body, isNot(contains('spoken words')));
    expect(body, contains('[redacted:provider_key]'));
  });
}

List<RegExp> _patternsFrom(String source) {
  final List<RegExp> patterns = <RegExp>[];
  String? expression;
  var inPatterns = false;
  for (final String raw in source.split('\n')) {
    final String trimmed = raw.trim();
    if (trimmed.isEmpty || trimmed.startsWith('#')) {
      continue;
    }
    final int indent = raw.length - raw.trimLeft().length;
    if (indent == 0) {
      inPatterns = trimmed == 'patterns:';
      expression = null;
      continue;
    }
    if (!inPatterns) {
      continue;
    }
    final int separator = trimmed.indexOf(':');
    if (separator == -1) {
      continue;
    }
    final String key = trimmed.substring(0, separator).trim();
    String value = trimmed.substring(separator + 1).trim();
    if (value.length >= 2) {
      final String first = value.substring(0, 1);
      final String last = value.substring(value.length - 1);
      if (first == last && (first == '"' || first == "'")) {
        value = value.substring(1, value.length - 1);
      }
    }
    if (indent == 2) {
      if (expression != null) {
        patterns.add(RegExp(expression, caseSensitive: false));
      }
      expression = null;
    } else if (indent >= 4 && key == 'pattern') {
      expression = value;
    }
  }
  if (expression != null) {
    patterns.add(RegExp(expression, caseSensitive: false));
  }
  return patterns;
}
