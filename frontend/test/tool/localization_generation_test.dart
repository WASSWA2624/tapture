@Timeout(Duration(minutes: 5))
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'support/plan_fixture.dart' show dartExecutable;

void main() {
  test(
    'real generators reject stale factories, dispatch, pure copy and import probe',
    () async {
      final _Fixture fixture = _Fixture();
      await fixture.generate('generate_copy_messages');
      await fixture.generate('generate_domain_copy');
      await fixture.formatGenerated();
      for (final String generator in <String>[
        'generate_copy_messages',
        'generate_domain_copy',
      ]) {
        final ProcessResult clean = await fixture.generate(
          generator,
          check: true,
        );
        expect(clean.exitCode, 0, reason: '${clean.stdout}\n${clean.stderr}');
      }
      final File factory = fixture.file('lib/core/copy/copy_messages.g.dart');
      expect(factory.readAsStringSync(), contains('/// The project heading.'));
      factory.writeAsStringSync(
        factory.readAsStringSync().replaceFirst(
          'The project heading.',
          'The stale heading.',
        ),
      );
      final File resolver = fixture.file(
        'lib/core/copy/localized_copy_resolver.g.dart',
      );
      resolver.writeAsStringSync(
        resolver.readAsStringSync().replaceFirst(
          "'title' => title",
          "'wrong' => title",
        ),
      );
      final File pure = fixture.file('lib/core/copy/domain_copy.g.dart');
      pure.writeAsStringSync(
        pure.readAsStringSync().replaceFirst("'Projects'", "'Stale projects'"),
      );
      final File probe = fixture.file('tool/domain_copy_imports.g.dart');
      probe.writeAsStringSync('void verifyDomainImports() {}\n');
      final List<File> outputs = <File>[factory, resolver, pure, probe];
      final List<String> tampered = outputs
          .map((File file) => file.readAsStringSync())
          .toList();
      final ProcessResult messages = await fixture.generate(
        'generate_copy_messages',
        check: true,
      );
      final ProcessResult domain = await fixture.generate(
        'generate_domain_copy',
        check: true,
      );
      expect(messages.exitCode, 1);
      expect(domain.exitCode, 1);
      for (final String path in <String>[
        'lib/core/copy/copy_messages.g.dart',
        'lib/core/copy/localized_copy_resolver.g.dart',
      ]) {
        expect(
          '${messages.stderr}',
          contains(
            RegExp(
              '${RegExp.escape(path)}:[1-9][0-9]*: generated output is stale',
            ),
          ),
        );
      }
      for (final String path in <String>[
        'lib/core/copy/domain_copy.g.dart',
        'tool/domain_copy_imports.g.dart',
      ]) {
        expect(
          '${domain.stderr}',
          contains(
            RegExp(
              '${RegExp.escape(path)}:[1-9][0-9]*: generated output is stale',
            ),
          ),
        );
      }
      expect(
        messages.stderr,
        contains('Run dart run tool/generate_copy_messages.dart.'),
      );
      expect(
        domain.stderr,
        contains('Run dart run tool/generate_domain_copy.dart.'),
      );
      expect(
        outputs.map((File file) => file.readAsStringSync()).toList(),
        tampered,
      );
    },
  );

  test(
    'wrapped semantic calls join the real headless probe, which rejects transitive dart:ui',
    () async {
      final _Fixture fixture = _Fixture();
      await fixture.generate('generate_domain_copy');
      final String generated = fixture
          .file('tool/domain_copy_imports.g.dart')
          .readAsStringSync();
      expect(generated, contains('features/demo/domain/wrapped.dart'));
      expect(
        fixture.file('lib/core/copy/domain_copy.g.dart').readAsStringSync(),
        contains('LocalizedMessage items([int count = 2])'),
      );
      final ProcessResult clean = await fixture.probe();
      expect(clean.exitCode, 0, reason: '${clean.stdout}\n${clean.stderr}');
      fixture.write(
        'lib/core/fixture_helper.dart',
        "import 'dart:ui';\nclass FixtureHelper {}\n",
      );
      final ProcessResult broken = await fixture.probe();
      expect(broken.exitCode, isNot(0));
      expect(
        broken.stderr,
        contains("Dart library 'dart:ui' is not available"),
      );
      expect(
        broken.stderr,
        contains(RegExp(r'fixture_helper\.dart:1:[1-9][0-9]*:')),
      );
    },
  );
}

/// A disposable, tiny catalogue driven by the shipped generators and Dart VM.
final class _Fixture {
  _Fixture()
    : root = Directory.systemTemp.createTempSync('tapture copy fixture ') {
    addTearDown(() => root.deleteSync(recursive: true));
    write('lib/core/copy/copy.dart', r'''
abstract final class Copy {
  /// The project heading.
  static String get title => _english.title;
  /// Number of records.
  static String items([int count = 2]) => _english.items(count);
  static String named({int count = 3}) => _english.named(count: count);
}
''');
    write('lib/core/copy/localized_copy.dart', '''
class LocalizedCopy {
  String get title => _catalog.title;
  String items([int count = 2]) => _catalog.items(count);
  String named({int count = 3}) => _catalog.named(count: count);
}
''');
    write('lib/core/copy/l10n/app_localizations_en.g.dart', r'''
class AppLocalizationsEn {
  String get title => 'Projects';
  String items([int count = 2]) => '$count records';
  String named({int count = 3}) => '$count named records';
}
''');
    write('lib/core/copy/localized_message.dart', '''
class LocalizedMessage {
  const LocalizedMessage({required this.key, required this.fallback,
    this.arguments = const <String, Object?>{}});
  final String key;
  final String fallback;
  final Map<String, Object?> arguments;
  static Object? encodeArgument(Object? value) => value;
}
''');
    write('lib/features/demo/domain/label.dart', '''
import 'package:tapture/core/copy/domain_copy.g.dart';
import 'package:tapture/core/fixture_helper.dart';
String label() => DomainCopy.title;
''');
    write('lib/features/demo/domain/wrapped.dart', '''
import 'package:tapture/core/copy/domain_copy.g.dart';
LocalizedMessage message() => DomainCopy
    .messages
    .items(2);
LocalizedMessage namedMessage() => DomainCopy.messages.named();
''');
    write('lib/core/fixture_helper.dart', 'class FixtureHelper {}\n');
    write('tool/probe.dart', '''
import 'package:tapture/core/copy/domain_copy.g.dart';
import 'domain_copy_imports.g.dart';
void main() {
  verifyDomainImports();
  if (DomainCopy.title != 'Projects' ||
      DomainCopy.messages.items(2).fallback != '2 records' ||
      DomainCopy.messages.items().fallback != '2 records' ||
      DomainCopy.messages.items(8).arguments['count'] != 8 ||
      DomainCopy.messages.named().fallback != '3 named records' ||
      DomainCopy.messages.named(count: 9).fallback != '9 named records' ||
      DomainCopy.messages.named().arguments['count'] != 3) {
    throw StateError('Changed English audit fallback');
  }
}
''');
    final Map<String, Object?> config = Map<String, Object?>.from(
      jsonDecode(_packages.readAsStringSync()) as Map,
    );
    for (final Object? item in config['packages']! as List) {
      final Map<String, Object?> package = item! as Map<String, Object?>;
      package['rootUri'] = package['name'] == 'tapture'
          ? root.uri.toString()
          : _packages.uri.resolve(package['rootUri']! as String).toString();
    }
    write('.dart_tool/package_config.json', jsonEncode(config));
  }

  static final File _packages = File('.dart_tool/package_config.json').absolute;
  final Directory root;

  File file(String path) => File('${root.path}/$path');

  void write(String path, String content) {
    file(path)
      ..parent.createSync(recursive: true)
      ..writeAsStringSync(content);
  }

  Future<ProcessResult> generate(String name, {bool check = false}) async {
    final ProcessResult result = await Process.run(dartExecutable(), <String>[
      '--packages=${_packages.path}',
      File('tool/$name.dart').absolute.path,
      if (check) '--check',
    ], workingDirectory: root.path);
    if (!check) {
      expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
    }
    return result;
  }

  Future<ProcessResult> probe() => Process.run(dartExecutable(), <String>[
    '--packages=${file('.dart_tool/package_config.json').path}',
    file('tool/probe.dart').path,
  ], workingDirectory: root.path);

  Future<void> formatGenerated() async {
    final ProcessResult result =
        await Process.run(dartExecutable(), const <String>[
          'format',
          'lib/core/copy/copy_messages.g.dart',
          'lib/core/copy/localized_copy_resolver.g.dart',
          'lib/core/copy/domain_copy.g.dart',
          'tool/domain_copy_imports.g.dart',
        ], workingDirectory: root.path);
    expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
  }
}
