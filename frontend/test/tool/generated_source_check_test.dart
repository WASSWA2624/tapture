import 'package:flutter_test/flutter_test.dart';

import '../../tool/generated_source_check.dart';

void main() {
  const String path = 'lib/core/copy/copy_messages.g.dart';
  const String generator = 'tool/generate_copy_messages.dart';
  const String expected =
      'class Messages {\n  /// The project heading.\n  String get title => "Projects";\n}\n';

  test('formatter whitespace does not make generated declarations stale', () {
    expect(
      generatedSourceProblem(
        path: path,
        expected: expected,
        actual:
            'class Messages{\n/// The project heading.\nString get title=>"Projects";\n}',
        generator: generator,
      ),
      isNull,
    );
  });

  test(
    'documentation drift reports its actual line and regeneration command',
    () {
      expect(
        generatedSourceProblem(
          path: path,
          expected: expected,
          actual: expected.replaceFirst('project heading', 'stale heading'),
          generator: generator,
        ),
        '$path:2: generated output is stale. Run dart run $generator.',
      );
    },
  );

  test(
    'optional trailing commas pass but creating a positional record fails',
    () {
      expect(
        generatedSourceProblem(
          path: path,
          expected: 'Object make() => Factory(one: 1, two: 2);',
          actual: 'Object make() => Factory(\n  one: 1,\n  two: 2,\n);',
          generator: generator,
        ),
        isNull,
      );
      expect(
        generatedSourceProblem(
          path: path,
          expected: 'Object make() => (1);',
          actual: 'Object make() => (1,);',
          generator: generator,
        ),
        isNotNull,
      );
      expect(
        generatedSourceProblem(
          path: path,
          expected: 'Object make() => (left: 1, right: 2);',
          actual: 'Object make() => (\n  left: 1,\n  right: 2,\n);',
          generator: generator,
        ),
        isNull,
      );
      expect(
        generatedSourceProblem(
          path: path,
          expected: 'Object make() => (left: 1, right: 2);',
          actual: 'Object make() => (left: 1, changed: 2);',
          generator: generator,
        ),
        isNotNull,
      );
    },
  );

  test('missing and truncated files fail with an actionable file location', () {
    expect(
      generatedSourceProblem(
        path: path,
        expected: expected,
        generator: generator,
      ),
      '$path:1: generated output is missing. Run dart run $generator.',
    );
    expect(
      generatedSourceProblem(
        path: path,
        expected: expected,
        actual: 'class Messages {\n}',
        generator: generator,
      ),
      startsWith('$path:2: generated output is stale.'),
    );
  });
}
