@Timeout(Duration(minutes: 3))
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/check_native_library.dart';

/// Four arm64 Android shared objects, each a few KiB, built with the NDK's
/// clang (dev-plan task 103) from `int tw_fixture(int)`:
///
/// - `aligned16k.so`: `-nostdlib -Wl,-z,max-page-size=16384`, the passing case;
/// - `aligned4k.so`: the same at `max-page-size=4096`;
/// - `extra_export.so`: 16 KiB, also exporting `helper_value`;
/// - `needs_libomp.so`: 16 KiB, `-fopenmp` without `-static-openmp`, so it
///   needs `libomp.so`.
const String _fixtures = 'test/tool/fixtures/native_library';

String _fixture(String name) => '$_fixtures/$name';

String _asLine(({String file, int line, String message}) violation) =>
    '${violation.file}:${violation.line}: ${violation.message}';

void main() {
  group('check_native_library', () {
    test('a 16 KiB library exporting only tw_* and needing nothing passes', () {
      expect(
        findNativeLibraryViolations(<String>[_fixture('aligned16k.so')]),
        isEmpty,
      );
    });

    test('one run reports each failing fixture with file and line', () {
      final List<String> lines = findNativeLibraryViolations(<String>[
        _fixture('aligned16k.so'),
        _fixture('aligned4k.so'),
        _fixture('extra_export.so'),
        _fixture('needs_libomp.so'),
      ]).map(_asLine).toList();

      expect(lines, hasLength(5));
      expect(
        lines.where((String line) => line.startsWith(_fixture('aligned4k.so'))),
        everyElement(contains(':0: PT_LOAD p_align 4096 < 16384')),
      );
      expect(
        lines.where((String line) => line.startsWith(_fixture('aligned4k.so'))),
        hasLength(3),
      );
      expect(
        lines,
        contains(
          "${_fixture('extra_export.so')}:0: exports 'helper_value': only "
          'tw_* may be visible',
        ),
      );
      expect(
        lines,
        contains(
          "${_fixture('needs_libomp.so')}:0: DT_NEEDED 'libomp.so' is not a "
          'system library: link it statically',
        ),
      );
      expect(
        lines.where((String line) => line.startsWith(_fixture('aligned16k'))),
        isEmpty,
      );
    });

    test('a missing file and a file that is not ELF are reported', () {
      final Directory scratch = Directory.systemTemp.createTempSync('tw_elf_');
      addTearDown(() => scratch.deleteSync(recursive: true));
      final File text = File('${scratch.path}/text.so')
        ..writeAsStringSync('not an ELF file at all, only text');

      final List<String> lines = findNativeLibraryViolations(<String>[
        '${scratch.path}/absent.so',
        text.path,
      ]).map(_asLine).toList();

      expect(lines, <String>[
        '${scratch.path}/absent.so:0: no such file',
        '${text.path}:0: not a little-endian ELF shared object',
      ]);
    });

    test('the command exits 1 on a violation and 0 on a clean library', () {
      final ProcessResult failing = Process.runSync('dart', <String>[
        'run',
        '--verbosity=error',
        'tool/check_native_library.dart',
        _fixture('aligned16k.so'),
        _fixture('needs_libomp.so'),
      ], runInShell: true);
      expect(failing.exitCode, 1);
      expect(
        failing.stderr as String,
        contains("needs_libomp.so:0: DT_NEEDED 'libomp.so'"),
      );
      expect(failing.stdout as String, contains('1 violation(s)'));

      final ProcessResult passing = Process.runSync('dart', <String>[
        'run',
        '--verbosity=error',
        'tool/check_native_library.dart',
        _fixture('aligned16k.so'),
      ], runInShell: true);
      expect(passing.exitCode, 0);
    });
  });
}
