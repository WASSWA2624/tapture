import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// A disposable repository with deterministic plan sources and no real app code.
class PlanFixture {
  PlanFixture()
    : root = Directory.systemTemp.createTempSync('tapture tracker ') {
    addTearDown(() => root.deleteSync(recursive: true));
    Directory('${root.path}/dev-plan').createSync();
  }

  final Directory root;

  File file(String path) => File('${root.path}/$path');

  /// Starts the step file `dev-plan/<name>.md`, holding no task yet.
  File step(String name, {String title = 'Step'}) {
    return file('dev-plan/$name.md')..writeAsStringSync(
      '# ${name.substring(0, 2)} — $title\n\nHuman prose.\n',
    );
  }

  /// Appends task [id] to the step file `dev-plan/<step>.md` and returns that
  /// file.
  File task(
    String step,
    String id, {
    String? title,
    String checks = '- [ ] Implemented.\n- [ ] Verified.',
    String started = '',
    String depends = '',
    String after = '',
  }) {
    final File target = file('dev-plan/$step.md');
    target.writeAsStringSync(
      '\n${_task(id, title ?? 'Task $id', checks, started, depends, after, '##')}',
      mode: FileMode.append,
    );
    return target;
  }

  /// Writes task [id] as the next prompt file in the step folder
  /// `dev-plan/<step>/`, numbered on from the step number, and returns it.
  File folderTask(
    String step,
    String id, {
    String? title,
    String checks = '- [ ] Implemented.\n- [ ] Verified.',
    String started = '',
    String depends = '',
  }) {
    final Directory folder = Directory('${root.path}/dev-plan/$step')
      ..createSync(recursive: true);
    final int prefix =
        int.parse(step.substring(0, 2)) +
        folder.listSync().whereType<File>().length;
    return file(
      'dev-plan/$step/${prefix.toString().padLeft(2, '0')}-task-$id.md',
    )..writeAsStringSync(
      _task(id, title ?? 'Task $id', checks, started, depends, '', '#'),
    );
  }

  Future<ProcessResult> git(List<String> args) {
    return Process.run(
      'git',
      args,
      workingDirectory: root.path,
      environment: fixtureEnvironment(),
      includeParentEnvironment: false,
    );
  }
}

/// One task's prompt with its heading at [mark] and its sections one level
/// below.
String _task(
  String id,
  String title,
  String checks,
  String started,
  String depends,
  String after,
  String mark,
) {
  return '$mark $id — $title\n\n'
      '${started.isEmpty ? '' : '$started\n\n'}'
      '${depends.isEmpty ? '' : '**Depends on** $depends\n\n'}'
      '$mark# Implement\n\nImplementation scope.\n\n'
      '$mark# Files\n\nFiles to change.\n\n'
      '$mark# Definition of done\n\n$checks\n\n'
      '$mark# Notes\n\n${after.isEmpty ? 'None.' : after}\n';
}

/// Variables that bind git to a particular repository. A pre-commit hook
/// exports them, so a fixture run inside one would act on the real commit.
const Set<String> _repositoryBindings = <String>{
  'GIT_DIR',
  'GIT_INDEX_FILE',
  'GIT_WORK_TREE',
  'GIT_OBJECT_DIRECTORY',
  'GIT_ALTERNATE_OBJECT_DIRECTORIES',
  'GIT_COMMON_DIR',
  'GIT_PREFIX',
};

/// This process's environment without git's repository bindings, plus
/// [extra], for processes that must act on a fixture repository alone.
Map<String, String> fixtureEnvironment([
  Map<String, String> extra = const <String, String>{},
]) {
  // Windows names are case-insensitive, so an extra PATH replaces Path.
  final Set<String> replaced = <String>{
    for (final String key in extra.keys) key.toUpperCase(),
  };
  return <String, String>{
    for (final MapEntry<String, String> entry in Platform.environment.entries)
      if (!_repositoryBindings.contains(entry.key.toUpperCase()) &&
          !replaced.contains(entry.key.toUpperCase()))
        entry.key: entry.value,
    ...extra,
  };
}

String dartExecutable() {
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

Future<ProcessResult> runTracker(PlanFixture fixture, List<String> arguments) {
  return Process.run(
    dartExecutable(),
    <String>[
      'run',
      '--verbosity=error',
      File('tool/sync_dev_tracker.dart').absolute.path,
      '--root',
      fixture.root.path,
      ...arguments,
    ],
    stdoutEncoding: utf8,
    stderrEncoding: utf8,
  );
}

String? gitShell() {
  if (!Platform.isWindows) {
    return 'sh';
  }
  final ProcessResult result = Process.runSync('git', <String>['--exec-path']);
  if (result.exitCode != 0 || result.stdout is! String) {
    return null;
  }
  Directory directory = Directory((result.stdout as String).trim());
  while (directory.existsSync()) {
    for (final String suffix in <String>['usr/bin/sh.exe', 'bin/sh.exe']) {
      final File shell = File('${directory.path}/$suffix');
      if (shell.existsSync()) {
        return shell.path;
      }
    }
    if (directory.parent.path == directory.path) {
      return null;
    }
    directory = directory.parent;
  }
  return null;
}
