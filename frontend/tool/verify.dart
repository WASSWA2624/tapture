import 'dart:io';

/// The only mode. A run checks the files that changed.
const String _changedFlag = '--changed';

/// Measured budgets run alone after the functional tests for those same files.
const String _performanceTag = 'performance';

/// How to call this, printed when the mode is missing or an argument is not
/// one this understands.
const String _usage =
    'usage: dart run tool/verify.dart $_changedFlag [path...]';

/// The base commit a clean tree is compared with, when the caller sets one.
///
/// Continuous integration sets this to the pull-request base or the previous
/// tip of the branch. A local clean tree falls back to the parent of `HEAD`.
const String _baseVariable = 'VERIFY_BASE';

/// A hook that is not itself a Dart file, and the test that covers it.
const Map<String, String> _pairedTests = <String, String>{
  'tool/hooks/pre-commit': 'test/tool/pre_commit_test.dart',
  'tool/hooks/commit-msg': 'test/tool/commit_msg_test.dart',
};

/// How a gate turned out.
enum _Outcome {
  /// The gate ran and was happy.
  passed,

  /// The gate ran and was not.
  failed,

  /// The gate had nothing in the change set, so it was not run at all.
  skipped,
}

/// One gate: what it is called, and the command that decides it.
///
/// A gate with no command had no changed files to check.
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

/// Git could not say which files changed.
final class _GitChanges implements Exception {
  /// What a run should print.
  _GitChanges(this.message);

  /// The reason, already worded for the person who ran the command.
  final String message;
}

/// Runs every gate the changed files need and reports them as one table.
///
/// `--changed` is required. Paths after it are the change; without them the
/// command asks git. Exits 0 when every gate passed or was skipped, and 1
/// when any gate failed or the change set could not be read.
Future<int> main(List<String> args) async {
  exitCode = await verify(args);
  return exitCode;
}

/// Collects every gate for the change set.
///
/// [runCommand] stands in for the process boundary, and [readChanges] for git,
/// so a test can decide both without leaving the package.
Future<int> verify(
  List<String> args, {
  Future<ProcessResult> Function(String, List<String>)? runCommand,
  Future<List<String>> Function()? readChanges,
}) async {
  if (!args.contains(_changedFlag)) {
    stderr.writeln(_usage);
    return 1;
  }
  final List<String> rest = args
      .where((String argument) => argument != _changedFlag && argument != '--')
      .toList();
  final List<String> unknown = rest
      .where((String argument) => argument.startsWith('-'))
      .toList();
  if (unknown.isNotEmpty) {
    stderr.writeln('unrecognised argument(s): ${unknown.join(', ')}');
    stderr.writeln(_usage);
    return 1;
  }

  final List<String> changed;
  try {
    changed = rest.isNotEmpty
        ? _unique(rest)
        : _unique(await (readChanges ?? _readGitChanges)());
  } on _GitChanges catch (error) {
    stderr.writeln(error.message);
    return 1;
  }

  final List<_Result> results = <_Result>[];
  for (final _Gate gate in _gates(changed)) {
    stdout.writeln('Running gate: ${gate.name}');
    final _Result result = await _runGate(gate, runCommand ?? _execute);
    results.add(result);
    stdout.writeln(
      'Completed ${result.name}: ${result.outcome.name} '
      '(${_seconds(result.took)})',
    );
    if (result.outcome == _Outcome.failed && result.detail.isNotEmpty) {
      stderr.writeln('--- ${result.name} ---');
      stderr.writeln(result.detail);
    }
  }

  _report(results);
  final bool anyFailed = results.any(
    (_Result result) => result.outcome == _Outcome.failed,
  );
  return anyFailed ? 1 : 0;
}

/// The gates, in the order a run works through them.
///
/// Cheap and specific first. A gate with nothing of its own in [changed] is
/// reported as skipped rather than pointed at the rest of the package.
List<_Gate> _gates(List<String> changed) {
  final List<String> dartFiles = <String>[
    for (final String path in changed)
      if (_isPackageDart(path)) path,
  ];
  final List<String> tests = _selectedTests(changed);
  final List<String> guardrail = _where(tests, _isGuardrail);
  final List<String> golden = _where(tests, _isGolden);
  final List<String> integration = _where(tests, _isIntegration);
  final List<String> unit = _where(tests, _isUnit);
  final List<String> measured = <String>[
    for (final String path in unit)
      if (_measuresPerformance(path)) path,
  ];
  return <_Gate>[
    _when('dev tracker refresh', _any(changed, _isPlan), 'dart', <String>[
      'run',
      'tool/sync_dev_tracker.dart',
    ]),
    _when('format', dartFiles.isNotEmpty, 'dart', <String>[
      'format',
      '--output=none',
      '--set-exit-if-changed',
      ...dartFiles,
    ]),
    _when('analyzer', dartFiles.isNotEmpty, _flutter, <String>[
      'analyze',
      ...dartFiles,
    ]),
    _when(
      'dependency allowlist',
      _any(changed, _isDependency),
      'dart',
      <String>['run', 'tool/check_dependencies.dart'],
    ),
    _when('structure', _any(changed, _isTree), 'dart', <String>[
      'run',
      'tool/check_structure.dart',
    ]),
    _when('plan', _any(changed, _isPlan), 'dart', <String>[
      'run',
      'tool/check_plan.dart',
    ]),
    _when('templates', _any(changed, _isTemplate), 'dart', <String>[
      'run',
      'tool/check_templates.dart',
    ]),
    _when('localization', _any(changed, _isLocalization), 'dart', <String>[
      'run',
      'tool/check_l10n.dart',
    ]),
    _when(
      'localization factories',
      _any(changed, _isCopyFactory),
      'dart',
      <String>['run', 'tool/generate_copy_messages.dart', '--check'],
    ),
    _when('domain localization', _any(changed, _isDomainCopy), 'dart', <String>[
      'run',
      'tool/generate_domain_copy.dart',
      '--check',
    ]),
    _when('headless domain', _any(changed, _isDomainCopy), 'dart', <String>[
      'run',
      'tool/probe_domain_copy.dart',
    ]),
    _when('test presence', _any(changed, _isLibSource), 'dart', <String>[
      'run',
      'tool/check_tests.dart',
      '--strict',
    ]),
    _suite('guardrail tests', guardrail),
    _suite(
      'unit and widget tests',
      unit,
      options: const <String>['--exclude-tags', _performanceTag],
    ),
    _suite(
      'performance tests',
      measured,
      options: const <String>['--tags', _performanceTag, '--concurrency=1'],
    ),
    _suite('golden tests', golden),
    _suite(
      'integration tests',
      integration,
      options: const <String>['--concurrency=1'],
    ),
  ];
}

/// A gate that runs when [ready] and is skipped when the change set has
/// nothing for it.
_Gate _when(
  String name,
  bool ready,
  String executable,
  List<String> arguments,
) {
  if (!ready) {
    return (
      name: name,
      executable: null,
      arguments: const <String>[],
      skippedBecause: 'no changed files',
    );
  }
  return (
    name: name,
    executable: executable,
    arguments: arguments,
    skippedBecause: null,
  );
}

/// A gate that runs the tests under [paths], or is skipped when there are none.
_Gate _suite(
  String name,
  List<String> paths, {
  List<String> options = const <String>[],
}) {
  if (paths.isEmpty) {
    return (
      name: name,
      executable: null,
      arguments: const <String>[],
      skippedBecause: 'no changed files',
    );
  }
  return (
    name: name,
    executable: _flutter,
    arguments: <String>['test', ...options, ...paths],
    skippedBecause: null,
  );
}

/// The tests the change owes: a changed test file, the mirror of a changed
/// source file, the tests beside a changed golden, and the guardrail files
/// when a rule file changed.
List<String> _selectedTests(List<String> changed) {
  final Set<String> tests = <String>{};
  for (final String path in changed) {
    if (_isRunnableTest(path) && File(path).existsSync()) {
      tests.add(path);
      continue;
    }
    final String? mirror = _mirroredTest(path);
    if (mirror != null && File(mirror).existsSync()) {
      tests.add(mirror);
    }
    final int goldens = path.indexOf('/goldens/');
    if (goldens > 0) {
      tests.addAll(_testsIn(path.substring(0, goldens)));
    }
  }
  if (changed.any((String path) => path.startsWith('.rules/'))) {
    for (final String suite in const <String>[
      'test/architecture',
      'test/tool',
      'test/support',
    ]) {
      tests.addAll(_testsIn(suite));
    }
  }
  return tests.toList()..sort();
}

/// A test file the runner can be pointed at.
bool _isRunnableTest(String path) {
  return path.endsWith('_test.dart') &&
      (path.startsWith('test/') || path.startsWith('integration_test/'));
}

/// The test that belongs to a source file, when the layout has one.
String? _mirroredTest(String path) {
  final String? paired = _pairedTests[path];
  if (paired != null) {
    return paired;
  }
  if (!path.endsWith('.dart') ||
      path.endsWith('.g.dart') ||
      path.endsWith('.freezed.dart')) {
    return null;
  }
  if (path.startsWith('lib/')) {
    return 'test/${path.substring(4, path.length - 5)}_test.dart';
  }
  if (path.startsWith('tool/') && !path.substring(5).contains('/')) {
    return 'test/tool/${path.substring(5, path.length - 5)}_test.dart';
  }
  return null;
}

/// The `*_test.dart` files sitting directly in [directory].
List<String> _testsIn(String directory) {
  final Directory dir = Directory(directory);
  if (!dir.existsSync()) {
    return const <String>[];
  }
  return <String>[
    for (final FileSystemEntity entity in dir.listSync())
      if (entity is File && _basename(entity.uri).endsWith('_test.dart'))
        '$directory/${_basename(entity.uri)}',
  ];
}

/// Whether [path] carries the measured-budget tag.
bool _measuresPerformance(String path) {
  final File file = File(path);
  if (!file.existsSync()) {
    return false;
  }
  final String source = file.readAsStringSync();
  return source.contains('@Tags(') &&
      (source.contains("'$_performanceTag'") ||
          source.contains('"$_performanceTag"'));
}

bool _isPackageDart(String path) {
  return path.endsWith('.dart') && !path.startsWith('../');
}

bool _isPlan(String path) {
  return path.startsWith('../dev-plan/') || path == '../dev-tracker.md';
}

bool _isDependency(String path) {
  return path == 'pubspec.yaml' ||
      path == 'pubspec.lock' ||
      path == 'tool/allowlist.yaml';
}

bool _isTree(String path) {
  return path.startsWith('lib/') ||
      path.startsWith('test/') ||
      path.startsWith('tool/') ||
      path.startsWith('integration_test/');
}

bool _isTemplate(String path) {
  return path.startsWith('assets/templates/') ||
      path == 'tool/check_templates.dart' ||
      path == 'tool/build_template_catalogue.dart';
}

bool _isLocalization(String path) {
  return path.endsWith('.arb') ||
      path.startsWith('lib/core/copy/l10n/') ||
      path == 'tool/check_l10n.dart' ||
      (path.endsWith('.dart') &&
          (path.contains('/presentation/') || path.contains('/widgets/')));
}

bool _isCopyFactory(String path) {
  return path == 'lib/core/copy/copy.dart' ||
      path == 'tool/generate_copy_messages.dart' ||
      path == 'lib/core/copy/copy_messages.g.dart' ||
      path == 'lib/core/copy/localized_copy_resolver.g.dart';
}

bool _isDomainCopy(String path) {
  return path.startsWith('lib/core/copy/') ||
      path.contains('/domain/') ||
      path == 'tool/generate_domain_copy.dart' ||
      path == 'tool/probe_domain_copy.dart' ||
      path == 'tool/domain_copy_imports.g.dart';
}

bool _isLibSource(String path) {
  return path.startsWith('lib/') &&
      path.endsWith('.dart') &&
      !path.endsWith('.g.dart') &&
      !path.endsWith('.freezed.dart');
}

bool _isGuardrail(String path) {
  return path.startsWith('test/tool/') ||
      path.startsWith('test/architecture/') ||
      path.startsWith('test/support/');
}

bool _isGolden(String path) => path.startsWith('test/design_system/');

bool _isIntegration(String path) => path.startsWith('integration_test/');

bool _isUnit(String path) {
  return path.startsWith('test/') && !_isGuardrail(path) && !_isGolden(path);
}

/// The paths among [paths] for which [test] is true, in their existing order.
List<String> _where(List<String> paths, bool Function(String path) test) {
  return <String>[
    for (final String path in paths)
      if (test(path)) path,
  ];
}

bool _any(List<String> paths, bool Function(String path) test) {
  return paths.any(test);
}

/// Runs one gate, timing it and keeping whatever it said for the report.
Future<_Result> _runGate(
  _Gate gate,
  Future<ProcessResult> Function(String, List<String>) execute,
) async {
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
    result = await execute(executable, gate.arguments);
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

Future<ProcessResult> _execute(String executable, List<String> arguments) {
  return Process.run(executable, arguments);
}

/// The changed files, as paths relative to this package.
///
/// A dirty tree contributes its staged, unstaged and untracked files. A clean
/// tree contributes the diff from [VERIFY_BASE] or from the parent of `HEAD`.
Future<List<String>> _readGitChanges() async {
  final ProcessResult top = await Process.run('git', <String>[
    'rev-parse',
    '--show-toplevel',
  ]);
  if (top.exitCode != 0) {
    throw _GitChanges(
      'verify: not a git repository, so changed files cannot be listed',
    );
  }
  final String root = _text(top).trim();
  final String prefix = _packagePrefix(root, Directory.current.path);
  final List<String> dirty = <String>[
    ...await _git(root, <String>['diff', '--name-only', '--diff-filter=ACMR']),
    ...await _git(root, <String>[
      'diff',
      '--cached',
      '--name-only',
      '--diff-filter=ACMR',
    ]),
    ...await _git(root, <String>['ls-files', '--others', '--exclude-standard']),
  ];
  if (dirty.isNotEmpty) {
    return <String>[for (final String path in dirty) _fromGit(path, prefix)];
  }

  final String? base = _usableBase(Platform.environment[_baseVariable]);
  if (base != null) {
    return <String>[
      for (final String path in await _git(root, <String>[
        'diff',
        '--name-only',
        '--diff-filter=ACMR',
        base,
        'HEAD',
      ]))
        _fromGit(path, prefix),
    ];
  }
  final ProcessResult parent = await Process.run('git', <String>[
    '-C',
    root,
    'rev-parse',
    '--verify',
    '--quiet',
    'HEAD^',
  ]);
  if (parent.exitCode == 0) {
    return <String>[
      for (final String path in await _git(root, <String>[
        'diff',
        '--name-only',
        '--diff-filter=ACMR',
        'HEAD^',
        'HEAD',
      ]))
        _fromGit(path, prefix),
    ];
  }
  return <String>[
    for (final String path in await _git(root, <String>[
      'diff-tree',
      '--no-commit-id',
      '--name-only',
      '-r',
      '--root',
      'HEAD',
    ]))
      _fromGit(path, prefix),
  ];
}

/// One git command whose output is a list of paths. A failure is the reason
/// the change set could not be read.
Future<List<String>> _git(String root, List<String> args) async {
  final ProcessResult result = await Process.run('git', <String>[
    '-C',
    root,
    ...args,
  ]);
  if (result.exitCode != 0) {
    throw _GitChanges(
      'verify: git ${args.join(' ')} failed\n${_text(result)}'.trim(),
    );
  }
  return _lines(result);
}

/// [base] when it names a commit, and null when it is absent or the all-zero
/// placeholder a new branch push carries.
String? _usableBase(String? base) {
  if (base == null) {
    return null;
  }
  final String trimmed = base.trim();
  if (trimmed.isEmpty || RegExp(r'^0+$').hasMatch(trimmed)) {
    return null;
  }
  return trimmed;
}

/// This package's path inside [repoRoot], or empty when the command is already
/// standing at the root.
String _packagePrefix(String repoRoot, String cwd) {
  final String root = _slash(Directory(repoRoot).absolute.path);
  final String here = _slash(Directory(cwd).absolute.path);
  if (here.toLowerCase() == root.toLowerCase()) {
    return '';
  }
  if (here.toLowerCase().startsWith('${root.toLowerCase()}/')) {
    return here.substring(root.length + 1);
  }
  return '';
}

/// A repo-relative git path written the way this package names files.
String _fromGit(String repoPath, String packagePrefix) {
  final String path = _clean(repoPath);
  if (packagePrefix.isEmpty) {
    return path;
  }
  if (path.startsWith('$packagePrefix/')) {
    return path.substring(packagePrefix.length + 1);
  }
  return '../$path';
}

/// [paths] cleaned, with a repeated path kept once, in a stable order.
///
/// A leading `frontend/` is dropped so a repo-relative path and a
/// package-relative path name the same file.
List<String> _unique(Iterable<String> paths) {
  final Set<String> unique = <String>{};
  for (final String raw in paths) {
    String path = _clean(raw);
    if (path.isEmpty) {
      continue;
    }
    if (path.startsWith('frontend/')) {
      path = path.substring('frontend/'.length);
    }
    unique.add(path);
  }
  return unique.toList()..sort();
}

/// [raw] with the host's separators and a leading `./` set aside.
String _clean(String raw) {
  String path = raw.trim().replaceAll('\\', '/');
  while (path.startsWith('./')) {
    path = path.substring(2);
  }
  return path;
}

/// [path] with every separator written as `/`.
String _slash(String path) {
  final String slashed = path.replaceAll('\\', '/');
  return slashed.endsWith('/')
      ? slashed.substring(0, slashed.length - 1)
      : slashed;
}

/// Prints the final table; failures are reported immediately by [verify].
void _report(List<_Result> results) {
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
    'verify ($_changedFlag): $passed passed, $failed failed, $skipped skipped',
  );
}

/// How many results carry [outcome].
int _count(List<_Result> results, _Outcome outcome) {
  return results.where((_Result result) => result.outcome == outcome).length;
}

/// A gate's own output, standard error first, since that is where a tool that
/// is unhappy says why.
String _outputOf(ProcessResult result) {
  return _text(result).trim();
}

/// Standard error, then standard output, as text.
String _text(ProcessResult result) {
  final Object? errors = result.stderr;
  final Object? output = result.stdout;
  return '${errors is String ? errors : ''}\n${output is String ? output : ''}';
}

/// The non-empty lines of a git listing.
List<String> _lines(ProcessResult result) {
  return <String>[
    for (final String line in _text(result).split('\n'))
      if (line.trim().isNotEmpty) line.trim(),
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
