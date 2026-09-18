import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/check_repo_hygiene.dart';

void main() {
  group('repository hygiene', () {
    test('the checked-in tree satisfies every hygiene rule', () {
      expect(findRepoHygieneViolations(Directory.current), isEmpty);
    });

    test('a gitignore that has lost its build output pattern is reported', () {
      final Directory root = _fixture(
        gitignore: _realGitignoreWithout('build/'),
      );

      expect(
        findRepoHygieneViolations(root).map(_asLine),
        contains(contains('no pattern ignores build/app/outputs')),
      );
    });

    test('a gitignore that stops hiding signing material is reported', () {
      final Directory root = _fixture(
        gitignore: _realGitignoreWithout('*.keystore'),
      );

      expect(
        findRepoHygieneViolations(root).map(_asLine),
        contains(contains('upload.keystore')),
      );
    });

    test('every unignored path is reported, not only the first', () {
      final Directory root = _fixture(gitignore: '# nothing is ignored here\n');

      final Iterable<String> reported = findRepoHygieneViolations(
        root,
      ).map(_asLine);

      expect(reported, hasLength(greaterThan(1)));
      expect(reported, contains(contains('.dart_tool/package_config.json')));
      expect(reported, contains(contains('project_dao.g.dart')));
      expect(reported, contains(contains('project.freezed.dart')));
      expect(reported, contains(contains('android/key.properties')));
      expect(reported, contains(contains('.env.local')));
      expect(reported, contains(contains('deviceA__2026-09-08T1030.zip')));
      expect(reported, contains(contains('photos/front.jpg')));
    });

    test('every violation names the file and the line that must change', () {
      final Directory root = _fixture(
        gitignore: '# nothing is ignored here\n',
        editorConfig: '',
      );

      for (final ({String file, int line, String message}) violation
          in findRepoHygieneViolations(root)) {
        expect(violation.file, isNotEmpty);
        expect(violation.line, greaterThanOrEqualTo(0));
        expect(violation.message, isNotEmpty);
      }
    });

    test('an editorconfig that does not fix line endings is reported', () {
      final Directory root = _fixture(
        editorConfig: _realEditorConfigWithout('end_of_line'),
      );

      expect(
        findRepoHygieneViolations(root).map(_asLine),
        contains(contains('[*] does not set end_of_line = lf')),
      );
    });

    test('an editorconfig that fixes the wrong line ending is reported', () {
      final Directory root = _fixture(
        editorConfig: _realEditorConfig().replaceAll(
          'end_of_line = lf',
          'end_of_line = crlf',
        ),
      );

      expect(
        findRepoHygieneViolations(root).map(_asLine),
        contains(contains('sets end_of_line = crlf, expected lf')),
      );
    });

    test('an editorconfig without a Dart section is reported', () {
      final Directory root = _fixture(
        editorConfig:
            '[*]\ncharset = utf-8\n'
            'end_of_line = lf\ninsert_final_newline = true\n',
      );

      expect(
        findRepoHygieneViolations(root).map(_asLine),
        contains(contains('no [*.dart] section')),
      );
    });

    test('a tree with neither hygiene file is reported for both', () {
      final Directory root = Directory.systemTemp.createTempSync(
        'tapture_hygiene_',
      );
      addTearDown(() => root.deleteSync(recursive: true));

      expect(
        findRepoHygieneViolations(root).map(_asLine),
        containsAll(<Matcher>[
          contains('.gitignore:0: the repository has no .gitignore'),
          contains('.editorconfig:0: the repository has no .editorconfig'),
        ]),
      );
    });
  });
}

/// Builds a throwaway tree holding the two hygiene files, each defaulting to
/// the copy this repository actually ships.
Directory _fixture({String? gitignore, String? editorConfig}) {
  final Directory root = Directory.systemTemp.createTempSync(
    'tapture_hygiene_',
  );
  addTearDown(() => root.deleteSync(recursive: true));
  File(
    '${root.path}/.gitignore',
  ).writeAsStringSync(gitignore ?? _realGitignore());
  File(
    '${root.path}/.editorconfig',
  ).writeAsStringSync(editorConfig ?? _realEditorConfig());
  return root;
}

String _realGitignore() => File('.gitignore').readAsStringSync();

String _realEditorConfig() => File('.editorconfig').readAsStringSync();

/// The shipped `.gitignore` with one pattern deleted, so a test can prove the
/// checker notices a real rule going missing rather than a made-up one.
String _realGitignoreWithout(String pattern) {
  return _realGitignore()
      .split('\n')
      .where((String line) => line.trim() != pattern)
      .join('\n');
}

String _realEditorConfigWithout(String key) {
  return _realEditorConfig()
      .split('\n')
      .where((String line) => !line.trim().startsWith(key))
      .join('\n');
}

String _asLine(({String file, int line, String message}) violation) =>
    '${violation.file}:${violation.line}: ${violation.message}';
