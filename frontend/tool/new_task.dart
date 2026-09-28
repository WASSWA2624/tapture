import 'dart:io';

import 'sync_dev_tracker.dart' show readTracker;

/// The skeleton every generated task is rendered from, relative to
/// `frontend/`, which is where the tools run from.
const String _templatePath = 'tool/task_template.md';

/// Where the plan sits relative to `frontend/`, used when the phase folder is
/// named rather than given as a path.
///
/// The plan is a sibling of the application, never something it imports
/// (`frontend/.rules/01-structure.md`, FE-STR-01).
const String _defaultPlanRoot = '../dev-plan';

/// How to call this, printed when the arguments do not add up.
const String _usage =
    'usage: dart run tool/new_task.dart <phase-folder> <slug> "<title>"';

/// A task file is `NNN-slug.md`; the number is what this tool takes the next
/// of.
final RegExp _taskFileName = RegExp(r'^(\d{3,})-(.+)\.md$');

/// A slug is lower-case words joined by single hyphens, the way every file in
/// the plan is already named.
final RegExp _slug = RegExp(r'^[a-z0-9]+(-[a-z0-9]+)*$');

/// The heading a phase folder's README opens with: `# 01 — Phase title`.
final RegExp _phaseHeading = RegExp(r'^#\s+(\d+)\s+—\s+(.+)$');

/// One reason the tool will not generate, and the file and line behind it.
typedef _Problem = ({String file, int line, String message});

/// Everything a run worked out before it wrote anything.
typedef _Plan = ({
  int number,
  String slug,
  String title,
  Directory phase,
  Directory root,
  File task,
  String phaseLine,
});

/// Creates the next task file in a phase, and lists it in the phase README and
/// the index.
///
/// Takes the phase folder, the slug and the title. Exits 0 when the task was
/// written and 1 when something stopped it, having written nothing.
Future<int> main(List<String> args) async {
  if (args.length != 3) {
    stderr.writeln(
      'expected a phase folder, a slug and a title, and got '
      '${args.length} argument(s)',
    );
    stderr.writeln(_usage);
    exitCode = 1;
    return exitCode;
  }

  final (_Plan?, List<_Problem>) prepared = _prepare(args[0], args[1], args[2]);
  final List<_Problem> problems = prepared.$2;
  for (final _Problem problem in problems) {
    stderr.writeln('${problem.file}:${problem.line}: ${problem.message}');
  }
  final _Plan? plan = prepared.$1;
  if (plan == null) {
    stdout.writeln('new task: not created, ${problems.length} problem(s)');
    exitCode = 1;
    return exitCode;
  }

  try {
    _write(plan);
  } on FormatException catch (error) {
    stderr.writeln('new task: ${error.message}');
    return exitCode = 1;
  } on FileSystemException catch (error) {
    stderr.writeln('new task: ${error.message}: ${error.path}');
    return exitCode = 1;
  }
  stdout.writeln(
    'new task: ${_padded(plan.number)} in ${_basename(plan.phase.uri)}, '
    'listed in the phase README and the index',
  );
  exitCode = 0;
  return exitCode;
}

/// Works out everything a run needs, reporting every reason it cannot proceed
/// rather than stopping at the first.
///
/// Nothing is written here. A run that would half-finish — a task file on disk
/// that no checklist mentions — leaves the plan in a state the integrity
/// checker would reject, so the decision to write is taken once, at the end,
/// when every precondition holds.
(_Plan?, List<_Problem>) _prepare(
  String phaseArgument,
  String slug,
  String title,
) {
  final List<_Problem> problems = <_Problem>[];

  final Directory? phase = _resolvePhase(phaseArgument);
  if (phase == null) {
    problems.add((
      file: phaseArgument,
      line: 0,
      message:
          'no such phase folder, either as a path or inside $_defaultPlanRoot',
    ));
    return (null, problems);
  }
  final Directory root = phase.parent;

  if (!_slug.hasMatch(slug)) {
    problems.add((
      file: _templatePath,
      line: 0,
      message:
          'the slug "$slug" is not lower-case words joined by single hyphens, '
          'which is how every file in the plan is named',
    ));
  }
  if (title.trim().isEmpty) {
    problems.add((
      file: _templatePath,
      line: 0,
      message: 'the title is empty, so the heading would say nothing',
    ));
  }

  final File template = File(_templatePath);
  if (!template.existsSync()) {
    problems.add((
      file: _templatePath,
      line: 0,
      message: 'there is no template to render a task from',
    ));
  }

  final File readme = File('${phase.path}/README.md');
  final File index = File('${root.path}/INDEX.md');
  if (!readme.existsSync()) {
    problems.add((
      file: '${_basename(phase.uri)}/README.md',
      line: 0,
      message: 'the phase has no README to list the new task in',
    ));
  }
  if (!index.existsSync()) {
    problems.add((
      file: 'INDEX.md',
      line: 0,
      message: 'the plan has no INDEX.md to list the new task in',
    ));
  }

  final int highest = _highestNumber(root);
  if (highest == 0) {
    problems.add((
      file: _basename(root.uri),
      line: 0,
      message: 'the plan holds no numbered task, so there is no next number',
    ));
  }
  final int number = highest + 1;

  final File task = File('${phase.path}/${_padded(number)}-$slug.md');
  if (task.existsSync()) {
    problems.add((
      file: '${_basename(phase.uri)}/${_basename(task.uri)}',
      line: 1,
      message: 'this task already exists and will not be overwritten',
    ));
  }
  final File? clash = _existingSlug(phase, slug);
  if (clash != null) {
    problems.add((
      file: '${_basename(phase.uri)}/${_basename(clash.uri)}',
      line: 1,
      message:
          'the slug "$slug" already names a task here; a slug names one task',
    ));
  }

  ({int number, String title})? heading;
  if (readme.existsSync()) {
    heading = _phaseOf(readme);
    if (heading == null) {
      problems.add((
        file: '${_basename(phase.uri)}/README.md',
        line: 1,
        message:
            'no heading of the form `# NN — Phase title`, so nothing says '
            'which phase this is',
      ));
    }
  }

  if (problems.isNotEmpty || heading == null) {
    return (null, problems);
  }
  return (
    (
      number: number,
      slug: slug,
      title: title.trim(),
      phase: phase,
      root: root,
      task: task,
      phaseLine: '${_padded2(heading.number)} · ${heading.title}',
    ),
    problems,
  );
}

/// Validates the existing plan, then generates every summary from one model.
void _write(_Plan plan) {
  readTracker(plan.root.parent);
  plan.task.writeAsStringSync(
    File(_templatePath)
        .readAsStringSync()
        .replaceAll('{{number}}', _padded(plan.number))
        .replaceAll('{{title}}', plan.title)
        .replaceAll('{{phase}}', plan.phaseLine),
  );
  try {
    final snapshot = readTracker(plan.root.parent);
    snapshot.write();
  } on FormatException {
    plan.task.deleteSync();
    rethrow;
  }
}

/// The phase folder named by [argument], as a path or as a folder inside the
/// plan beside this package.
Directory? _resolvePhase(String argument) {
  final Directory given = Directory(argument);
  if (given.existsSync()) {
    return given;
  }
  // Only a bare folder name is looked for inside the plan. A path that was
  // given and is not there is simply not there: joining it onto the plan root
  // would build something the host cannot parse, and asking whether that
  // exists throws rather than answering.
  if (argument.contains('/') || argument.contains('\\')) {
    return null;
  }
  final Directory inPlan = Directory('$_defaultPlanRoot/$argument');
  return inPlan.existsSync() ? inPlan : null;
}

/// The highest task number anywhere in the plan, or 0 when it holds none.
int _highestNumber(Directory root) {
  int highest = 0;
  for (final FileSystemEntity entity in root.listSync(recursive: true)) {
    if (entity is! File) {
      continue;
    }
    final Match? match = _taskFileName.firstMatch(_basename(entity.uri));
    if (match == null) {
      continue;
    }
    final int number = int.parse(match.group(1)!);
    if (number > highest) {
      highest = number;
    }
  }
  return highest;
}

/// The task in [phase] already carrying [slug], or null when none does.
File? _existingSlug(Directory phase, String slug) {
  for (final FileSystemEntity entity in phase.listSync()) {
    if (entity is! File) {
      continue;
    }
    final Match? match = _taskFileName.firstMatch(_basename(entity.uri));
    if (match != null && match.group(2) == slug) {
      return entity;
    }
  }
  return null;
}

/// The number and title a phase README opens with.
({int number, String title})? _phaseOf(File readme) {
  for (final String line in readme.readAsLinesSync()) {
    final Match? match = _phaseHeading.firstMatch(line.trim());
    if (match != null) {
      return (
        number: int.parse(match.group(1)!),
        title: match.group(2)!.trim(),
      );
    }
  }
  return null;
}

/// A task number as the plan writes it: at least three digits.
String _padded(int number) => number.toString().padLeft(3, '0');

/// A phase number as the plan writes it: two digits.
String _padded2(int number) => number.toString().padLeft(2, '0');

/// The last segment of a URI's path, so the host's separator never has to be
/// spelled out.
String _basename(Uri uri) {
  return uri.pathSegments.where((String segment) => segment.isNotEmpty).last;
}
