import 'dart:io';

/// The flag that drops the two slowest suites for the pre-commit path.
const String _fastFlag = '--fast';

/// How to call this, printed when an argument is not one this understands.
const String _usage = 'usage: dart run tool/verify.dart [$_fastFlag]';

/// The suites that hold the architecture's own guardrails.
///
/// They are named separately from the rest because they are load-bearing
/// (`frontend/.rules/12-testing.md`, FE-TEST-06): they are never skipped to
/// make a change pass, so a run says plainly whether they went green.
const List<String> _guardrailSuites = <String>[
  'test/tool',
  'test/architecture',
  'test/support',
];

/// The suite holding the design-system goldens, which `--fast` skips.
const String _goldenSuite = 'test/design_system';

/// The suite holding the end-to-end flows, which `--fast` skips.
const String _integrationSuite = 'integration_test';

/// Folders under `test/` that the unit-and-widget gate does not run: the
/// guardrail suites have their own gate, the goldens have theirs, and
/// `support/` is run with the guardrails because it holds the accessibility
/// matchers.
const List<String> _notUnitSuites = <String>[
  'tool',
  'architecture',
  'design_system',
  'support',
];

/// How a gate turned out.
enum _Outcome {
  /// The gate ran and was happy.
  passed,

  /// The gate ran and was not.
  failed,

  /// The gate had nothing to run against, so it was not run at all.
  skipped,
}

/// One gate: what it is called, and the command that decides it.
///
/// A gate with no command is one there is nothing to run — a suite that does
/// not exist yet, or one `--fast` set aside.
typedef _Gate = ({
  String name,
  String? executable,
  List<String> arguments,
  String? skippedBecause,
});

/// What running one gate produced.
typedef _Result = ({
  String name,
  _Outcome outcome,
  String detail,
  Duration took,
});

/// Runs every gate the review depends on and reports them as one table.
///
/// Takes `--fast`, which sets aside the golden and integration suites for the
/// pre-commit path; the full run is what continuous integration uses. Exits 0
/// when every gate passed or was skipped, and 1 as soon as one failed.
Future<int> main(List<String> args) async {
  final List<String> unknown = args
      .where((String argument) => argument != _fastFlag)
      .toList();
  if (unknown.isNotEmpty) {
    stderr.writeln('unrecognised argument(s): ${unknown.join(', ')}');
    stderr.writeln(_usage);
    exitCode = 1;
    return exitCode;
  }

  final bool fast = args.contains(_fastFlag);
  final List<_Result> results = <_Result>[];
  for (final _Gate gate in _gates(fast: fast)) {
    results.add(await _runGate(gate));
  }

  _report(results, fast: fast);
  final bool anyFailed = results.any(
    (_Result result) => result.outcome == _Outcome.failed,
  );
  exitCode = anyFailed ? 1 : 0;
  return exitCode;
}

/// The gates, in the order a run works through them.
///
/// Cheap and specific first, so a run that is going to fail usually fails
/// before it has spent a minute running tests.
List<_Gate> _gates({required bool fast}) {
  return <_Gate>[
    _command('format', 'dart', <String>[
      'format',
      '--output=none',
      '--set-exit-if-changed',
      '.',
    ]),
    _command('analyzer', _flutter, <String>['analyze']),
    _command('dependency allowlist', 'dart', <String>[
      'run',
      'tool/check_dependencies.dart',
    ]),
    _command('structure', 'dart', <String>['run', 'tool/check_structure.dart']),
    _command('plan', 'dart', <String>['run', 'tool/check_plan.dart']),
    _command('templates', 'dart', <String>['run', 'tool/check_templates.dart']),
    _command('test presence', 'dart', <String>[
      'run',
      'tool/check_tests.dart',
      '--strict',
    ]),
    _suite('guardrail tests', _existing(_guardrailSuites)),
    _suite('unit and widget tests', _unitSuites()),
    _suite(
      'golden tests',
      _existing(<String>[_goldenSuite]),
      setAside: fast ? 'set aside by $_fastFlag' : null,
    ),
    _suite(
      'integration tests',
      _existing(<String>[_integrationSuite]),
      setAside: fast ? 'set aside by $_fastFlag' : null,
    ),
  ];
}

/// A gate that runs one command.
_Gate _command(String name, String executable, List<String> arguments) {
  return (
    name: name,
    executable: executable,
    arguments: arguments,
    skippedBecause: null,
  );
}

/// A gate that runs the tests under [paths], or is skipped when there are none
/// or when the caller has set it aside.
_Gate _suite(String name, List<String> paths, {String? setAside}) {
  if (setAside != null) {
    return (
      name: name,
      executable: null,
      arguments: const <String>[],
      skippedBecause: setAside,
    );
  }
  if (paths.isEmpty) {
    return (
      name: name,
      executable: null,
      arguments: const <String>[],
      skippedBecause: 'no such suite yet',
    );
  }
  return (
    name: name,
    executable: _flutter,
    arguments: <String>['test', ...paths],
    skippedBecause: null,
  );
}

/// Runs one gate, timing it and keeping whatever it said for the report.
Future<_Result> _runGate(_Gate gate) async {
  final String? executable = gate.executable;
  if (executable == null) {
    return (
      name: gate.name,
      outcome: _Outcome.skipped,
      detail: gate.skippedBecause ?? 'nothing to run',
      took: Duration.zero,
    );
  }
  final Stopwatch stopwatch = Stopwatch()..start();
  ProcessResult result;
  try {
    result = await Process.run(executable, gate.arguments);
  } on ProcessException catch (error) {
    stopwatch.stop();
    return (
      name: gate.name,
      outcome: _Outcome.failed,
      detail: 'could not run $executable: ${error.message}',
      took: stopwatch.elapsed,
    );
  }
  stopwatch.stop();
  return (
    name: gate.name,
    outcome: result.exitCode == 0 ? _Outcome.passed : _Outcome.failed,
    detail: _outputOf(result),
    took: stopwatch.elapsed,
  );
}

/// Prints what every gate said, then the table, so the table is the last thing
/// on screen and the reason for a failure is right above it.
void _report(List<_Result> results, {required bool fast}) {
  for (final _Result result in results) {
    if (result.outcome == _Outcome.failed && result.detail.isNotEmpty) {
      stderr.writeln('--- ${result.name} ---');
      stderr.writeln(result.detail);
    }
  }

  final int width = results
      .map((_Result result) => result.name.length)
      .reduce((int a, int b) => a > b ? a : b);
  stdout.writeln('${'gate'.padRight(width)}  outcome  time');
  for (final _Result result in results) {
    stdout.writeln(
      '${result.name.padRight(width)}  '
      '${result.outcome.name.padRight(7)}  '
      '${_seconds(result.took)}',
    );
  }

  final int passed = _count(results, _Outcome.passed);
  final int failed = _count(results, _Outcome.failed);
  final int skipped = _count(results, _Outcome.skipped);
  stdout.writeln(
    'verify${fast ? ' ($_fastFlag)' : ''}: $passed passed, $failed failed, '
    '$skipped skipped',
  );
}

/// How many results carry [outcome].
int _count(List<_Result> results, _Outcome outcome) {
  return results.where((_Result result) => result.outcome == outcome).length;
}

/// A gate's own output, standard error first, since that is where a tool that
/// is unhappy says why.
String _outputOf(ProcessResult result) {
  final Object? errors = result.stderr;
  final Object? output = result.stdout;
  final String text =
      '${errors is String ? errors : ''}\n${output is String ? output : ''}';
  return text.trim();
}

/// The suites holding ordinary unit and widget tests: everything under `test/`
/// that another gate does not already own.
List<String> _unitSuites() {
  final Directory tests = Directory('test');
  if (!tests.existsSync()) {
    return <String>[];
  }
  final List<String> paths = <String>[];
  for (final FileSystemEntity entity in tests.listSync()) {
    final String name = _basename(entity.uri);
    if (entity is Directory) {
      if (!_notUnitSuites.contains(name)) {
        paths.add('test/$name');
      }
    } else if (entity is File && name.endsWith('_test.dart')) {
      paths.add('test/$name');
    }
  }
  return paths..sort();
}

/// The paths among [candidates] that are there to be run.
List<String> _existing(List<String> candidates) {
  return <String>[
    for (final String path in candidates)
      if (Directory(path).existsSync()) path,
  ];
}

/// The Flutter command line. On Windows it is a batch file, which has to be
/// named in full for the host to find it.
String get _flutter => Platform.isWindows ? 'flutter.bat' : 'flutter';

/// A duration as the table shows it.
String _seconds(Duration took) {
  return took == Duration.zero
      ? '—'
      : '${(took.inMilliseconds / 1000).toStringAsFixed(1)}s';
}

/// The last segment of a URI's path, so the host's separator never has to be
/// spelled out.
String _basename(Uri uri) {
  return uri.pathSegments.where((String segment) => segment.isNotEmpty).last;
}
