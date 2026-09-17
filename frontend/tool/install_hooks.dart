import 'dart:io';

/// The hooks that ship with this package, named as git names them.
const List<String> hookNames = <String>['pre-commit', 'commit-msg'];

/// Where the hooks are kept, relative to the package that ships them.
const String hookSource = 'tool/hooks';

/// One hook, where it landed, and whether something was already there.
typedef Installation = ({String hook, String path, bool replaced});

/// One reason the installer could not do its job, and the file behind it.
typedef Problem = ({String file, int line, String message});

/// What one run of the installer did, and everything that stopped it.
typedef InstallReport = ({
  List<Installation> installed,
  List<Problem> problems,
});

/// Installs the git hooks, printing one line per hook and per problem.
///
/// Takes the package directory to install from, defaulting to the working
/// directory. Exits 0 when both hooks are in place and 1 when something
/// stopped it.
Future<int> main(List<String> args) async {
  final Directory package = Directory(
    args.isEmpty ? Directory.current.path : args.first,
  );
  final InstallReport report = installHooks(package);
  for (final Problem problem in report.problems) {
    stderr.writeln('${problem.file}:${problem.line}: ${problem.message}');
  }
  for (final Installation installation in report.installed) {
    stdout.writeln(
      '${installation.hook} -> ${installation.path}'
      '${installation.replaced ? ' (replaced)' : ''}',
    );
  }
  stdout.writeln(
    report.problems.isEmpty
        ? 'hooks: ${report.installed.length} installed'
        : 'hooks: not installed, ${report.problems.length} problem(s)',
  );
  exitCode = report.problems.isEmpty ? 0 : 1;
  return exitCode;
}

/// Copies every hook shipped in [package] into the repository that holds it,
/// replacing whatever was there.
///
/// Running this twice does the same thing twice: a hook is written to a fixed
/// name, so the second run replaces the first rather than adding to it.
///
/// Reports every problem it finds rather than stopping at the first, and
/// installs nothing at all unless all of them can be installed — a repository
/// with one of the two hooks in place is a repository with a gate that only
/// half works.
InstallReport installHooks(Directory package) {
  final List<Problem> problems = <Problem>[];

  final Directory? hooks = _hooksDirectory(package);
  if (hooks == null) {
    problems.add((
      file: package.path,
      line: 0,
      message:
          'no git repository here or above it, so there is nowhere to put a '
          'hook',
    ));
  }

  final List<File> sources = <File>[];
  for (final String name in hookNames) {
    final File source = File('${package.path}/$hookSource/$name');
    if (source.existsSync()) {
      sources.add(source);
    } else {
      problems.add((
        file: '$hookSource/$name',
        line: 0,
        message: 'this package ships no such hook to install',
      ));
    }
  }

  if (problems.isNotEmpty || hooks == null) {
    return (installed: const <Installation>[], problems: problems);
  }

  hooks.createSync(recursive: true);
  final List<Installation> installed = <Installation>[];
  for (final File source in sources) {
    final String name = _basename(source.uri);
    final File destination = File('${hooks.path}/$name');
    final bool replaced = destination.existsSync();
    destination.writeAsStringSync(_withUnixLineEndings(source));
    _makeExecutable(destination);
    installed.add((hook: name, path: destination.path, replaced: replaced));
  }
  return (installed: installed, problems: problems);
}

/// The hook a git repository would run, read back as text.
///
/// Takes the package directory and the hook's name, so a caller can ask what
/// is actually installed rather than what was meant to be.
String? installedHook(Directory package, String name) {
  final Directory? hooks = _hooksDirectory(package);
  if (hooks == null) {
    return null;
  }
  final File hook = File('${hooks.path}/$name');
  return hook.existsSync() ? hook.readAsStringSync() : null;
}

/// The hooks directory of the repository holding [package], or null when
/// nothing above it is a repository.
///
/// A worktree's `.git` is a file naming the real directory rather than being
/// one, so both shapes are followed.
Directory? _hooksDirectory(Directory package) {
  Directory? directory = package.absolute;
  while (directory != null) {
    final Directory asDirectory = Directory('${directory.path}/.git');
    if (asDirectory.existsSync()) {
      return Directory('${asDirectory.path}/hooks');
    }
    final File asFile = File('${directory.path}/.git');
    if (asFile.existsSync()) {
      final Directory? linked = _linkedGitDirectory(asFile);
      if (linked != null) {
        return Directory('${linked.path}/hooks');
      }
    }
    final Directory parent = directory.parent;
    directory = parent.path == directory.path ? null : parent;
  }
  return null;
}

/// The directory a worktree's `.git` file points at.
Directory? _linkedGitDirectory(File marker) {
  const String prefix = 'gitdir:';
  for (final String line in marker.readAsLinesSync()) {
    if (!line.startsWith(prefix)) {
      continue;
    }
    final String path = line.substring(prefix.length).trim();
    final Directory linked = Directory(path);
    if (linked.isAbsolute) {
      return linked;
    }
    return Directory('${marker.parent.path}/$path');
  }
  return null;
}

/// A hook's text with every line ending as a shell expects one.
///
/// This repository sets `core.autocrlf`, so a checkout can leave these files
/// carrying carriage returns. A shell reads the first line as the interpreter
/// to run, and `/bin/sh\r` is not a program anybody has, so the hook would
/// fail to run at all rather than fail loudly.
String _withUnixLineEndings(File source) {
  return source
      .readAsStringSync()
      .replaceAll('\r\n', '\n')
      .replaceAll('\r', '');
}

/// Marks a hook executable, which git requires of one on a POSIX host.
///
/// Windows has no such bit, and git there runs a hook through its own shell
/// regardless, so there is nothing to set.
void _makeExecutable(File hook) {
  if (Platform.isWindows) {
    return;
  }
  Process.runSync('chmod', <String>['+x', hook.path]);
}

/// The last segment of a URI's path, so the host's separator never has to be
/// spelled out.
String _basename(Uri uri) {
  return uri.pathSegments.where((String segment) => segment.isNotEmpty).last;
}
