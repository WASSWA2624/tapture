import 'dart:io';

import 'plan_source.dart';
import 'sync_dev_tracker.dart' show readTracker;

/// The skeleton every generated task is rendered from, relative to
/// `frontend/`, which is where the tools run from. It is written at a step
/// file's heading levels; a task file in a step folder is one level up.
const String _templatePath = 'tool/task_template.md';

/// Where the plan sits relative to `frontend/`, used when the step is named
/// rather than given as a path.
///
/// The plan is a sibling of the application, never something it imports
/// (`frontend/.rules/01-structure.md`, FE-STR-01).
const String _defaultPlanRoot = '../dev-plan';

/// How to call this, printed when the arguments do not add up.
const String _usage = 'usage: dart run tool/new_task.dart <step> "<title>"';

/// A step file, `NN-slug.md`, or a step folder, `NN-slug`.
final RegExp _stepName = RegExp(r'^\d{2}-[a-z0-9]+(?:-[a-z0-9]+)*(?:\.md)?$');

/// A heading outside a fenced block, which a step folder's task file holds one
/// level higher than a step file does.
final RegExp _heading = RegExp(r'^##+ ');

/// One reason the tool will not generate, and the file and line behind it.
typedef _Problem = ({String file, int line, String message});

/// Everything a run worked out before it wrote anything.
typedef _Plan = ({
  String number,
  String title,
  FileSystemEntity step,
  Directory root,
  File target,
});

/// Adds the next task to a step: appended to a step file, or written into a
/// step folder as its own prompt file. Then refreshes the tracker.
///
/// Takes the step and the title. Exits 0 when the task was written and 1 when
/// something stopped it, having written nothing.
Future<int> main(List<String> args) async {
  if (args.length != 2) {
    stderr.writeln(
      'expected a step and a title, and got ${args.length} argument(s)',
    );
    stderr.writeln(_usage);
    exitCode = 1;
    return exitCode;
  }

  final (_Plan?, List<_Problem>) prepared = _prepare(args[0], args[1]);
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
    'new task: ${plan.number} in ${_basename(plan.target.uri)}; '
    'dev-tracker.md refreshed',
  );
  exitCode = 0;
  return exitCode;
}

/// Works out everything a run needs, reporting every reason it cannot proceed
/// rather than stopping at the first.
///
/// Nothing is written here. A run that would half-finish leaves the plan in a
/// state the integrity checker would reject, so the decision to write is taken
/// once, at the end, when every precondition holds.
(_Plan?, List<_Problem>) _prepare(String stepArgument, String title) {
  final List<_Problem> problems = <_Problem>[];

  final FileSystemEntity? step = _resolveStep(stepArgument);
  if (step == null) {
    problems.add((
      file: stepArgument,
      line: 0,
      message:
          'no such NN-slug.md step file or NN-slug step folder, either as a '
          'path or inside $_defaultPlanRoot',
    ));
    return (null, problems);
  }
  final Directory root = step.parent;

  final String trimmed = title.trim();
  if (trimmed.isEmpty) {
    problems.add((
      file: _templatePath,
      line: 0,
      message: 'the title is empty, so the heading would say nothing',
    ));
  }
  if (!File(_templatePath).existsSync()) {
    problems.add((
      file: _templatePath,
      line: 0,
      message: 'there is no template to render a task from',
    ));
  }

  final PlanSource source = readPlan(root);
  problems.addAll(source.problems);
  int highest = 0;
  for (final PlanTask task in source.tasks) {
    final int id = int.parse(task.id);
    if (id > highest) {
      highest = id;
    }
    if (trimmed.isNotEmpty &&
        task.title.toLowerCase() == trimmed.toLowerCase()) {
      problems.add((
        file: '${_basename(root.uri)}/${task.path}',
        line: task.line,
        message:
            'the title "$trimmed" already names task ${task.id}; a title '
            'names one task',
      ));
    }
  }
  final String number = (highest + 1).toString().padLeft(3, '0');

  // A step folder numbers its prompt files on from its own step number.
  final String stepName = _basename(step.uri);
  final int held = source.steps
      .where((PlanStep each) => each.path == stepName)
      .fold(0, (int count, PlanStep each) => count + each.tasks.length);
  final String prefix = (int.parse(stepName.substring(0, 2)) + held)
      .toString()
      .padLeft(2, '0');
  final String slug = _slugOf(trimmed);
  final File target = step is File
      ? step
      : File('${step.path}/$prefix-$slug.md');
  if (step is Directory) {
    if (slug.isEmpty) {
      problems.add((
        file: _templatePath,
        line: 0,
        message: 'the title holds no letter or digit to name a task file with',
      ));
    } else if (target.existsSync()) {
      problems.add((
        file: '${_basename(step.uri)}/${_basename(target.uri)}',
        line: 1,
        message: 'this task already exists and will not be overwritten',
      ));
    }
  }

  if (problems.isNotEmpty) {
    return (null, problems);
  }
  return (
    (number: number, title: trimmed, step: step, root: root, target: target),
    problems,
  );
}

/// Writes the task, then regenerates the tracker from the whole plan. A plan
/// the tracker rejects puts the step back exactly as it was.
void _write(_Plan plan) {
  final String block = File(_templatePath)
      .readAsStringSync()
      .replaceAll('\r\n', '\n')
      .replaceAll('{{number}}', plan.number)
      .replaceAll('{{title}}', plan.title);
  final File target = plan.target;
  final String? before = plan.step is File ? target.readAsStringSync() : null;
  if (before == null) {
    target.writeAsStringSync(_promoted(block));
  } else {
    target.writeAsStringSync('${before.trimRight()}\n\n$block');
  }
  try {
    readTracker(plan.root.parent).write();
  } on FormatException {
    if (before == null) {
      target.deleteSync();
    } else {
      target.writeAsStringSync(before);
    }
    rethrow;
  }
}

/// [block] one heading level higher, for a task that is its own prompt file.
String _promoted(String block) {
  bool fenced = false;
  return block
      .split('\n')
      .map((String line) {
        if (line.trimLeft().startsWith('```')) {
          fenced = !fenced;
        }
        return !fenced && _heading.hasMatch(line) ? line.substring(1) : line;
      })
      .join('\n');
}

/// A task file's slug from its title: lower-case words joined by hyphens.
String _slugOf(String title) => title
    .toLowerCase()
    .replaceAll(RegExp('[^a-z0-9]+'), '-')
    .replaceAll(RegExp(r'^-+|-+$'), '');

/// The step named by [argument], as a path or as a step inside the plan beside
/// this package.
FileSystemEntity? _resolveStep(String argument) {
  final FileSystemEntity? given = _existing(argument);
  if (given != null) {
    return _stepName.hasMatch(_basename(given.uri)) ? given : null;
  }
  // Only a bare name is looked for inside the plan. A path that was given and
  // is not there is simply not there: joining it onto the plan root would
  // build something the host cannot parse, and asking whether that exists
  // throws rather than answering.
  if (argument.contains('/') ||
      argument.contains('\\') ||
      !_stepName.hasMatch(argument)) {
    return null;
  }
  return _existing('$_defaultPlanRoot/$argument') ??
      _existing('$_defaultPlanRoot/$argument.md');
}

/// The file or directory at [path], or null when there is neither.
FileSystemEntity? _existing(String path) {
  if (File(path).existsSync()) {
    return File(path);
  }
  if (Directory(path).existsSync()) {
    return Directory(path);
  }
  return null;
}

/// The last segment of a URI's path, so the host's separator never has to be
/// spelled out.
String _basename(Uri uri) {
  return uri.pathSegments.where((String segment) => segment.isNotEmpty).last;
}
