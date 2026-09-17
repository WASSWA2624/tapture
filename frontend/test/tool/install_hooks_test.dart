import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/install_hooks.dart';

void main() {
  group('installing the hooks', () {
    test('puts every hook this package ships into the repository', () {
      final Directory package = _package();

      final InstallReport report = installHooks(package);

      expect(report.problems, isEmpty);
      expect(
        report.installed.map((Installation each) => each.hook),
        unorderedEquals(hookNames),
      );
      for (final String name in hookNames) {
        expect(installedHook(package, name), isNotNull);
      }
    });

    test('running it twice leaves exactly one copy of each hook', () {
      final Directory package = _package();

      installHooks(package);
      installHooks(package);

      final List<String> present = _hookFiles(package);
      expect(present, unorderedEquals(hookNames));
      expect(present, hasLength(hookNames.length));
    });

    test('the second run says it replaced what the first put there', () {
      final Directory package = _package();

      final InstallReport first = installHooks(package);
      final InstallReport second = installHooks(package);

      expect(
        first.installed.map((Installation each) => each.replaced),
        everyElement(isFalse),
      );
      expect(
        second.installed.map((Installation each) => each.replaced),
        everyElement(isTrue),
      );
    });

    test('what lands is what this package ships', () {
      final Directory package = _package();

      installHooks(package);

      for (final String name in hookNames) {
        expect(
          installedHook(package, name),
          File('${package.path}/$hookSource/$name').readAsStringSync(),
        );
      }
    });

    test('a hook keeps the line endings a shell can read', () {
      final Directory package = _package(carriageReturns: true);

      installHooks(package);

      for (final String name in hookNames) {
        expect(installedHook(package, name), isNot(contains('\r')));
        expect(installedHook(package, name), startsWith('#!/bin/sh\n'));
      }
    });

    test('an existing hook from somewhere else is replaced, not added to', () {
      final Directory package = _package();
      Directory('${package.parent.path}/.git/hooks').createSync();
      File(
        '${package.parent.path}/.git/hooks/commit-msg',
      ).writeAsStringSync('#!/bin/sh\n# somebody else was here\nexit 42\n');

      installHooks(package);

      expect(
        installedHook(package, 'commit-msg'),
        isNot(contains('somebody else was here')),
      );
      expect(
        installedHook(package, 'commit-msg'),
        File('${package.path}/$hookSource/commit-msg').readAsStringSync(),
      );
      expect(_hookFiles(package), hasLength(hookNames.length));
    });
  });

  group('refusing to install', () {
    test('a directory in no repository is reported', () {
      final Directory root = Directory.systemTemp.createTempSync(
        'tapture_hooks_',
      );
      addTearDown(() => root.deleteSync(recursive: true));
      _shipHooks(root);

      final InstallReport report = installHooks(root);

      expect(
        report.problems.map(_asLine),
        contains(contains('no git repository here or above it')),
      );
      expect(report.installed, isEmpty);
    });

    test('a hook this package does not ship is reported', () {
      final Directory package = _package();
      File('${package.path}/$hookSource/commit-msg').deleteSync();

      final InstallReport report = installHooks(package);

      expect(
        report.problems.map(_asLine),
        contains(
          contains(
            '$hookSource/commit-msg:0: this package ships no such hook to '
            'install',
          ),
        ),
      );
    });

    test('one missing hook stops the other being installed', () {
      final Directory package = _package();
      File('${package.path}/$hookSource/commit-msg').deleteSync();

      final InstallReport report = installHooks(package);

      expect(report.installed, isEmpty);
      expect(_hookFiles(package), isEmpty);
    });

    test('every problem is reported, not only the first', () {
      final Directory root = Directory.systemTemp.createTempSync(
        'tapture_hooks_',
      );
      addTearDown(() => root.deleteSync(recursive: true));
      Directory('${root.path}/$hookSource').createSync(recursive: true);

      final InstallReport report = installHooks(root);

      expect(report.problems, hasLength(hookNames.length + 1));
    });

    test('every problem names the file and the line', () {
      final Directory package = _package();
      File('${package.path}/$hookSource/pre-commit').deleteSync();

      for (final Problem problem in installHooks(package).problems) {
        expect(problem.file, isNotEmpty);
        expect(problem.line, greaterThanOrEqualTo(0));
        expect(problem.message, isNotEmpty);
      }
    });
  });
}

/// Builds a throwaway repository with this package inside it, holding the
/// hooks this one actually ships so a case proves the installer moves the real
/// files rather than invented ones.
Directory _package({bool carriageReturns = false}) {
  final Directory root = Directory.systemTemp.createTempSync('tapture_hooks_');
  addTearDown(() => root.deleteSync(recursive: true));
  Directory('${root.path}/.git').createSync();
  final Directory package = Directory('${root.path}/frontend')..createSync();
  _shipHooks(package, carriageReturns: carriageReturns);
  return package;
}

/// Copies the shipped hooks into [package], optionally as a checkout with
/// `core.autocrlf` would leave them.
void _shipHooks(Directory package, {bool carriageReturns = false}) {
  Directory('${package.path}/$hookSource').createSync(recursive: true);
  for (final String name in hookNames) {
    final String text = File(
      '$hookSource/$name',
    ).readAsStringSync().replaceAll('\r\n', '\n').replaceAll('\r', '');
    File(
      '${package.path}/$hookSource/$name',
    ).writeAsStringSync(carriageReturns ? text.replaceAll('\n', '\r\n') : text);
  }
}

/// The hooks a repository would actually run, ignoring the samples git puts
/// there itself.
List<String> _hookFiles(Directory package) {
  final Directory hooks = Directory('${package.parent.path}/.git/hooks');
  if (!hooks.existsSync()) {
    return <String>[];
  }
  return <String>[
    for (final FileSystemEntity entity in hooks.listSync())
      if (entity is File) entity.uri.pathSegments.last,
  ]..removeWhere((String name) => name.endsWith('.sample'));
}

String _asLine(Problem problem) =>
    '${problem.file}:${problem.line}: ${problem.message}';
