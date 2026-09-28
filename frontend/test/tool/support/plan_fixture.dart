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

  void phase(String name, {String title = 'Phase'}) {
    file('dev-plan/$name/README.md')
      ..parent.createSync(recursive: true)
      ..writeAsStringSync(
        '# ${name.substring(0, 2)} — $title\n\nHuman prose.\n',
      );
  }

  File task(
    String phase,
    String id, {
    String title = 'Task',
    String checks = '- [ ] Implemented.\n- [ ] Verified.',
    String started = '',
    String depends = '',
    String after = '',
  }) {
    return file('dev-plan/$phase/$id-task.md')..writeAsStringSync(
      '# $id — $title\n\n'
      '${started.isEmpty ? '' : '$started\n\n'}'
      '${depends.isEmpty ? '' : '**Depends on** $depends\n\n'}'
      '## Implement\n\nImplementation scope.\n\n'
      '## Files\n\nFiles to change.\n\n'
      '## Definition of done\n\n$checks\n\n'
      '## Notes\n\n$after\n',
    );
  }

  Future<ProcessResult> git(List<String> args) {
    return Process.run('git', args, workingDirectory: root.path);
  }
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
