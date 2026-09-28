import 'dart:io';

import 'sync_dev_tracker.dart' show readTracker;

/// Checks the proposed commit, independently of remaining workspace edits.
/// Only plan files are copied, and the Git index itself is never changed.
Future<int> main(List<String> args) async {
  if (args.isNotEmpty) {
    stderr.writeln('usage: dart run tool/check_staged_dev_tracker.dart');
    return exitCode = 1;
  }
  Directory? snapshot;
  try {
    final ProcessResult located = await Process.run('git', <String>[
      'rev-parse',
      '--show-toplevel',
    ]);
    if (located.exitCode != 0) {
      stderr.write(located.stderr);
      return exitCode = 1;
    }
    final String repository = (located.stdout as String).trim();
    final ProcessResult listed = await Process.run('git', <String>[
      'ls-files',
      '-z',
      '--',
      'dev-plan',
      'dev-tracker.md',
    ], workingDirectory: repository);
    if (listed.exitCode != 0) {
      stderr.write(listed.stderr);
      return exitCode = 1;
    }
    final List<String> paths = (listed.stdout as String)
        .split('\u0000')
        .where((String path) => path.isNotEmpty)
        .toList();
    if (paths.isEmpty) {
      stderr.writeln(
        'dev tracker: stage the development plan before committing.',
      );
      return exitCode = 1;
    }
    snapshot = Directory.systemTemp.createTempSync('tapture_staged_plan_');
    final ProcessResult copied = await Process.run('git', <String>[
      'checkout-index',
      '--prefix=${snapshot.path.replaceAll('\\', '/')}/',
      '--',
      ...paths,
    ], workingDirectory: repository);
    if (copied.exitCode != 0) {
      stderr.write(copied.stderr);
      return exitCode = 1;
    }
    final List<String> stale = readTracker(snapshot).stalePaths;
    if (stale.isNotEmpty) {
      stderr.writeln(
        'dev tracker: staged summaries do not match the staged task checklists '
        'and implementation order:',
      );
      for (final String path in stale) {
        stderr.writeln('  $path');
      }
      stderr.writeln(
        'Review the task sources and generated summaries, then stage a '
        'consistent set of changes. Nothing was auto-staged.',
      );
      return exitCode = 1;
    }
    stdout.writeln('dev tracker: staged plan and summaries agree');
    return exitCode = 0;
  } on FormatException catch (error) {
    stderr.writeln('dev tracker: invalid staged plan: ${error.message}');
    return exitCode = 1;
  } on FileSystemException catch (error) {
    stderr.writeln('dev tracker: ${error.message}: ${error.path}');
    return exitCode = 1;
  } on ProcessException catch (error) {
    stderr.writeln(
      'dev tracker: could not inspect staged plan: ${error.message}',
    );
    return exitCode = 1;
  } finally {
    // Created by this invocation, never supplied by a caller.
    snapshot?.deleteSync(recursive: true);
  }
}
