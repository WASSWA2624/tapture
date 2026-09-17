import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/logging/logger.dart';

void main() {
  late Logger previous;

  setUp(() {
    previous = Logger.current;
  });

  tearDown(() {
    Logger.current = previous;
  });

  test('a secret-shaped value is redacted before it is stored', () {
    final Logger logger = Logger();
    logger.info('net', 'sk-abcdefghijklmnopqrstuvwxyz12');
    logger.info('net', 'bearer 0123456789abcdef');
    logger.info('net', '-----BEGIN PRIVATE KEY-----');
    logger.info('net', 'postgres://u:p@localhost');
    logger.info('net', 'caption: operator notes');
    logger.info('net', 'transcript: spoken words');

    final String joined = logger.buffer.join('\n');
    expect(joined, contains('[redacted:provider_key]'));
    expect(joined, contains('[redacted:bearer_token]'));
    expect(joined, contains('[redacted:private_key]'));
    expect(joined, contains('[redacted:connection_string]'));
    expect(joined, contains('caption=[redacted]'));
    expect(joined, contains('transcript=[redacted]'));
    expect(joined, isNot(contains('sk-abcdefghijklmnopqrstuvwxyz12')));
    expect(joined, isNot(contains('0123456789abcdef')));
    expect(joined, isNot(contains('BEGIN PRIVATE KEY')));
    expect(joined, isNot(contains('postgres://u:p@')));
    expect(joined, isNot(contains('operator notes')));
    expect(joined, isNot(contains('spoken words')));
  });

  test('level filtering discards anything below the configured level', () {
    final Logger logger = Logger(minLevel: LogLevel.warn);
    logger.trace('net', 'fine');
    logger.info('net', 'ok');
    logger.warn('net', 'careful');
    logger.error('net', 'failed');

    expect(logger.buffer, hasLength(2));
    expect(logger.buffer.first, contains('warn'));
    expect(logger.buffer.last, contains('error'));
    expect(logger.buffer.join(), isNot(contains('fine')));
    expect(logger.buffer.join(), isNot(contains('ok')));
  });

  test('the buffer drops the oldest line when it reaches its bound', () {
    final Logger logger = Logger(bufferSize: 2);
    logger.info('net', 'one');
    logger.info('net', 'two');
    logger.info('net', 'three');

    expect(logger.buffer, hasLength(2));
    expect(logger.buffer.first, contains('two'));
    expect(logger.buffer.last, contains('three'));
    expect(logger.buffer.join(), isNot(contains('one')));
  });

  test('accepted lines are pushed on the diagnostics stream', () async {
    final Logger logger = Logger();
    final List<String> seen = <String>[];
    final StreamSubscription<String> subscription = logger.entries.listen(
      seen.add,
    );
    addTearDown(subscription.cancel);

    logger.info('net', 'hello');
    await Future<void>.delayed(Duration.zero);

    expect(seen, hasLength(1));
    expect(seen.single, contains('hello'));
    expect(seen.single, contains('net'));
    expect(seen.single, contains('info'));
  });

  test('a persisted file is already redacted at rest', () {
    final Directory directory = Directory.systemTemp.createTempSync(
      'tapture-log-',
    );
    addTearDown(() {
      if (directory.existsSync()) {
        directory.deleteSync(recursive: true);
      }
    });

    final Logger logger = Logger(persist: true, directoryPath: directory.path);
    logger.info('net', 'sk-abcdefghijklmnopqrstuvwxyz12');

    final String stored = File(
      '${directory.path}/tapture.log',
    ).readAsStringSync();
    expect(stored, contains('[redacted:provider_key]'));
    expect(stored, isNot(contains('sk-abcdefghijklmnopqrstuvwxyz12')));
  });

  test('rotated files exist after the buffer wraps', () {
    final Directory directory = Directory.systemTemp.createTempSync(
      'tapture-log-',
    );
    addTearDown(() {
      if (directory.existsSync()) {
        directory.deleteSync(recursive: true);
      }
    });

    final Logger logger = Logger(
      persist: true,
      directoryPath: directory.path,
      bufferSize: 1,
    );
    logger.info('net', 'first');
    logger.info('net', 'second');

    expect(File('${directory.path}/tapture.log').existsSync(), isTrue);
    expect(File('${directory.path}/tapture.log.1').existsSync(), isTrue);
    expect(
      File('${directory.path}/tapture.log').readAsStringSync(),
      contains('second'),
    );
  });

  test('lines older than the retention window are not persisted', () {
    final Directory directory = Directory.systemTemp.createTempSync(
      'tapture-log-',
    );
    addTearDown(() {
      if (directory.existsSync()) {
        directory.deleteSync(recursive: true);
      }
    });

    var now = DateTime.utc(2026, 1, 1);
    final Logger logger = Logger(
      persist: true,
      directoryPath: directory.path,
      bufferSize: 10,
      clock: () => now,
    );
    logger.info('net', 'old');
    now = DateTime.utc(2026, 1, 1 + AppConstants.logging.retentionDays + 1);
    logger.info('net', 'fresh');

    final String stored = File(
      '${directory.path}/tapture.log',
    ).readAsStringSync();
    expect(stored, contains('fresh'));
    expect(stored, isNot(contains('old')));
  });

  test('the default buffer size is the configured constant', () {
    expect(AppConstants.logging.bufferSize, greaterThan(1));
    final Logger logger = Logger();
    for (int index = 0; index < AppConstants.logging.bufferSize + 1; index++) {
      logger.info('net', 'line-$index');
    }

    expect(logger.buffer, hasLength(AppConstants.logging.bufferSize));
    expect(logger.buffer.first, contains('line-1'));
    expect(
      logger.buffer.last,
      contains('line-${AppConstants.logging.bufferSize}'),
    );
  });
}
