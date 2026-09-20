@Timeout(Duration(minutes: 10))
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The gate names, in the order a run works through them.
///
/// The order is part of what this command is for: cheap and specific first, so
/// a run that is going to fail usually fails before it has spent a minute
/// running tests.
const List<String> _gateOrder = <String>[
  'format',
  'analyzer',
  'dependency allowlist',
  'structure',
  'plan',
  'templates',
  'test presence',
  'guardrail tests',
  'unit and widget tests',
  'golden tests',
  'integration tests',
];

/// The checkers a gate shells out to, which a fixture stands in for.
///
/// A fixture is verified in its own working directory, so the command under
/// test runs against these rather than against this repository. That is what
/// keeps the suite from re-entering itself: verify runs `flutter test`, and
/// this file is one of the tests it would run.
const List<String> _checkers = <String>[
  'tool/check_dependencies.dart',
  'tool/check_structure.dart',
  'tool/check_plan.dart',
  'tool/check_templates.dart',
  'tool/check_tests.dart',
];

/// A checker that is happy, written the way `dart format` would.
const String _passing = 'void main() {}\n';

/// A checker that is not, and says so, the way a real one reports what it
/// found.
const String _failing =
    '''
import 'dart:io';

void main() {
  stderr.writeln('$_complaint');
  exitCode = 1;
}
''';

/// What the unhappy checker says, which a run has to put in front of whoever
/// ran it rather than swallow.
const String _complaint = 'fixture.yaml:7: this gate is unhappy';

void main() {
  group('a tree where every gate is happy', () {
    late _Run run;

    setUpAll(() async {
      run = await _verify(_fixture(), <String>['--fast']);
    });

    test('exits 0', () {
      expect(run.exitCode, 0);
    });

    test('reports every gate, in order', () {
      expect(run.gates, _gateOrder);
    });

    test('counts what passed, failed and was skipped', () {
      expect(run.summary, 'verify (--fast): 7 passed, 0 failed, 4 skipped');
    });

    test('skips the suites that are not there yet', () {
      expect(run.outcomeOf('guardrail tests'), 'skipped');
      expect(run.outcomeOf('unit and widget tests'), 'skipped');
    });
  });

  group('a tree where one gate fails', () {
    late _Run run;

    setUpAll(() async {
      run = await _verify(
        _fixture(failing: <String>['tool/check_plan.dart']),
        <String>['--fast'],
      );
    });

    test('exits 1', () {
      expect(run.exitCode, 1);
    });

    test('names the gate that failed and leaves the others alone', () {
      expect(run.outcomeOf('plan'), 'failed');
      expect(run.outcomeOf('format'), 'passed');
      expect(run.outcomeOf('dependency allowlist'), 'passed');
      expect(run.outcomeOf('structure'), 'passed');
    });

    test('the count follows the gate that failed', () {
      expect(run.summary, 'verify (--fast): 6 passed, 1 failed, 4 skipped');
    });

    test('shows the failing gate its own output', () {
      expect(run.errors, contains('--- plan ---'));
      expect(run.errors, contains(_complaint));
    });
  });

  group('a tree where a different gate fails', () {
    late _Run run;

    setUpAll(() async {
      run = await _verify(
        _fixture(
          failing: <String>[
            'tool/check_structure.dart',
            'tool/check_dependencies.dart',
          ],
        ),
        <String>['--fast'],
      );
    });

    test('exits 1', () {
      expect(run.exitCode, 1);
    });

    test('the table follows the tree rather than a fixed answer', () {
      expect(run.outcomeOf('structure'), 'failed');
      expect(run.outcomeOf('dependency allowlist'), 'failed');
      expect(run.outcomeOf('plan'), 'passed');
    });

    test('every failure is counted, not only the first', () {
      expect(run.summary, 'verify (--fast): 5 passed, 2 failed, 4 skipped');
      expect(run.errors, contains('--- dependency allowlist ---'));
      expect(run.errors, contains('--- structure ---'));
      expect(run.errors, isNot(contains('--- plan ---')));
    });
  });

  group('the suites --fast sets aside', () {
    late _Run fast;
    late _Run full;

    setUpAll(() async {
      final Directory withSuites = _fixture(
        suites: <String>['test/design_system', 'integration_test'],
      );
      fast = await _verify(withSuites, <String>['--fast']);
      full = await _verify(withSuites, <String>[]);
    });

    test('--fast skips them and says why', () {
      expect(fast.outcomeOf('golden tests'), 'skipped');
      expect(fast.outcomeOf('integration tests'), 'skipped');
      expect(fast.exitCode, 0);
    });

    test('the full run does not skip them', () {
      expect(full.outcomeOf('golden tests'), isNot('skipped'));
      expect(full.outcomeOf('integration tests'), isNot('skipped'));
    });

    test('the full run says it is the full run', () {
      expect(fast.summary, startsWith('verify (--fast):'));
      expect(full.summary, startsWith('verify:'));
    });
  });

  group('an argument it does not understand', () {
    late _Run run;

    setUpAll(() async {
      run = await _verify(_fixture(), <String>['--bogus']);
    });

    test('exits 1 without running a gate', () {
      expect(run.exitCode, 1);
      expect(run.gates, isEmpty);
    });

    test('says which argument and how to call it', () {
      expect(run.errors, contains('unrecognised argument(s): --bogus'));
      expect(run.errors, contains('usage: dart run tool/verify.dart [--fast]'));
    });
  });
}

/// What one run of the command reported.
class _Run {
  const _Run(this.exitCode, this.rows, this.summary, this.errors);

  /// The exit code: 0 when every gate passed or was skipped, 1 once one
  /// failed.
  final int exitCode;

  /// Each gate of the table, in the order it was reported.
  final List<({String gate, String outcome})> rows;

  /// The closing line counting the outcomes.
  final String summary;

  /// Everything the run wrote to standard error.
  final String errors;

  /// The gate names, in the order the table listed them.
  List<String> get gates =>
      rows.map((({String gate, String outcome}) row) => row.gate).toList();

  /// What the table said about [gate].
  String outcomeOf(String gate) {
    for (final ({String gate, String outcome}) row in rows) {
      if (row.gate == gate) {
        return row.outcome;
      }
    }
    return 'not reported';
  }
}

/// Builds a throwaway tree the command can be run against.
///
/// It holds a stand-in for each checker so the gates that shell out have
/// something to shell out to, every one happy unless [failing] names it.
/// [suites] creates test folders, which are otherwise absent so those gates
/// skip.
Directory _fixture({
  List<String> failing = const <String>[],
  List<String> suites = const <String>[],
}) {
  final Directory root = Directory.systemTemp.createTempSync('tapture_verify_');
  addTearDown(() => root.deleteSync(recursive: true));
  Directory('${root.path}/tool').createSync();
  for (final String checker in _checkers) {
    File(
      '${root.path}/$checker',
    ).writeAsStringSync(failing.contains(checker) ? _failing : _passing);
  }
  for (final String suite in suites) {
    Directory('${root.path}/$suite').createSync(recursive: true);
  }
  return root;
}

/// Runs the command inside [root] and reads back the table it printed.
///
/// The output is decoded as UTF-8 rather than as whatever the host's console
/// codepage is, so a row arrives as the command wrote it.
Future<_Run> _verify(Directory root, List<String> args) async {
  final ProcessResult result = await Process.run(
    _dartExecutable(),
    <String>['run', _verifyScript, ...args],
    workingDirectory: root.path,
    stdoutEncoding: utf8,
    stderrEncoding: utf8,
  );
  final Object? output = result.stdout;
  final Object? errors = result.stderr;
  final List<String> lines = (output is String ? output : '').split('\n');
  final List<({String gate, String outcome})> rows =
      <({String gate, String outcome})>[];
  String summary = '';
  for (final String line in lines) {
    final String trimmed = line.trimRight();
    if (trimmed.startsWith('verify')) {
      summary = trimmed;
      continue;
    }
    final List<String> fields = trimmed.split(RegExp('  +'));
    if (fields.length < 3 || fields.first == 'gate') {
      continue;
    }
    rows.add((gate: fields[0].trim(), outcome: fields[1].trim()));
  }
  return _Run(
    result.exitCode,
    rows,
    summary,
    (errors is String ? errors : '').trim(),
  );
}

/// The command under test, named absolutely because it is run from inside a
/// fixture rather than from this package.
final String _verifyScript = Uri.file(
  '${Directory.current.path}/tool/verify.dart',
).toFilePath();

/// The Dart command line, which is not the executable running this test:
/// `flutter test` runs it inside the Flutter tester.
String _dartExecutable() {
  final String suffix = Platform.isWindows ? '.exe' : '';
  final String running = Platform.resolvedExecutable;
  if (Uri.file(running).pathSegments.last == 'dart$suffix') {
    return running;
  }
  final String? flutterRoot = Platform.environment['FLUTTER_ROOT'];
  return flutterRoot == null
      ? 'dart$suffix'
      : '$flutterRoot/bin/cache/dart-sdk/bin/dart$suffix';
}
